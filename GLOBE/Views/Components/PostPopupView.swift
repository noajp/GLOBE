//======================================================================
// MARK: - PostPopupView.swift
// Purpose: Post creation popup with full-screen photo background
// Path: GLOBE/Views/Components/PostPopupView.swift
//======================================================================
import SwiftUI
import UIKit
import CoreLocation
import MapKit
import AVFoundation
import Combine

struct PostPopupView: View {
    @Binding var isPresented: Bool
    @ObservedObject var mapManager: MapManager
    let initialLocation: CLLocationCoordinate2D? // Add parameter for exact post location
    @StateObject private var locationManager = PostLocationManager()
    @StateObject private var mapLocationService = MapLocationService()
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var postManager = PostManager.shared
    
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    private let cardCornerRadius: CGFloat = 28
    private let sectionCornerRadius: CGFloat = 20
    private let mediaAspectRatio: CGFloat = 3.0 / 4.0
    
    @State private var postText = ""
    @State private var selectedImageData: Data?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingCamera = false
    @State private var showingCameraPermissionAlert = false
    @State private var showingLocationPermissionAlert = false
    @State private var capturedUIImage: UIImage?
    @State private var postLocation: CLLocationCoordinate2D?
    // 位置決定は地図の中心に揃える（Vの先端=地図中心）。余計なオフセットは使わない。
    @State private var areaName: String = ""
    @State private var showPrivacySelection = false
    @State private var selectedPrivacyType: PostPrivacyType = .publicPost
    @State private var isSubmitting = false
    // App settings
    @StateObject private var appSettings = AppSettings.shared
    
    enum PostPrivacyType {
        case followersOnly
        case publicPost
        case anonymous
    }
    
    // Computed properties to reduce complexity
    private var isButtonDisabled: Bool {
        let disabled = postText.isEmpty && selectedImageData == nil
        print("🔘 PostPopup - isButtonDisabled calculated: \(disabled) (text='\(postText)', hasImage=\(selectedImageData != nil))")
        return disabled
    }
    
    private var maxTextLength: Int {
        selectedImageData != nil ? 30 : 60
    }

    private var hasSelectedImage: Bool {
        selectedImageData != nil
    }
    
    var body: some View {
        ZStack {
            // Popup content with speech bubble tail
            LiquidGlassCard(
                id: "create-post-card",
                cornerRadius: cardCornerRadius,
                tint: Color.white.opacity(0.12),
                strokeColor: Color.white.opacity(0.38),
                highlightColor: Color.white.opacity(0.92),
                contentPadding: EdgeInsets(),
                contentBackdropOpacity: 0.22,
                shadowColor: Color.black.opacity(0.4),
                shadowRadius: 26,
                shadowOffsetY: 18
            ) {
                if !showPrivacySelection {
                    postCreationView
                } else {
                    privacySelectionView
                }
            }
            .frame(width: 260)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            // Note: Do not add a parent onTapGesture here; it can interfere with inner Buttons
            .overlay(
                speechBubbleTail
                    .allowsHitTesting(false),
                alignment: .bottom
            )
            // 吹き出しV先端のスクリーン座標をPreferenceで親に通知
            .overlay(alignment: .bottom) {
                GeometryReader { proxy in
                    Color.clear
                        .frame(width: 1, height: 1)
                        // V先端はカードの下端から約15pt下
                        .offset(y: 15)
                        .preference(key: VTipPreferenceKey.self, value: {
                            let f = proxy.frame(in: .global)
                            // 吹き出し三角の高さ分（約15pt）を下に補正してV先端の画面座標に一致
                            return CGPoint(x: f.midX, y: f.maxY + 15)
                        }())
                }
                .frame(width: 1, height: 1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPrivacySelection)
        .onDisappear {
            mapManager.draftPostCoordinate = nil
        }
        .fullScreenCover(isPresented: $showingCamera) {
            ZStack {
                // Fast custom camera preview
                CameraPreviewView(capturedImage: $capturedUIImage)
                    .ignoresSafeArea()

                // Top bar with close button
                VStack {
                    HStack {
                        Button(action: { showingCamera = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        Spacer()
                    }
                    Spacer()
                }
            }
            .onChange(of: capturedUIImage) { _, newImage in
                if let img = newImage, let data = img.jpegData(compressionQuality: 0.85) {
                    print("📷 PostPopup - Captured image via custom camera: \(data.count) bytes")
                    selectedImageData = data
                    capturedUIImage = nil
                    showingCamera = false
                }
            }
        }
        .alert("カメラへのアクセスが必要です", isPresented: $showingCameraPermissionAlert) {
            Button("設定を開く") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("写真を撮影するために、カメラへのアクセスを許可してください。")
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .alert("Location access required", isPresented: $showingLocationPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow location access in Settings to move to your current location.")
        }
        .onAppear {
            // Start location services
            mapLocationService.startLocationServices()

            // Initialize with current map center; user can press the direction icon to move to self location.
            updatePostLocation()

            // Pre-warm camera permission to reduce launch latency
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { _ in }
            }
        }
        // ここでは購読しない（無限再レンダリングを避ける）。投稿時に最新座標を参照する。
        .onChange(of: selectedImageData) { oldValue, newValue in
            print("📸 PostPopup - selectedImageData changed: \(newValue?.count ?? 0) bytes (was: \(oldValue?.count ?? 0) bytes)")
            print("📝 PostPopup - After change - text: '\(postText)', hasImage: \(newValue != nil)")
            print("🔘 PostPopup - Button should be disabled: \(postText.isEmpty && newValue == nil)")
            // Ensure the popup remains visible after capture
            if newValue != nil {
                // Just in case, guarantee camera sheet is closed
                showingCamera = false
            }
        }
    }
    
    // MARK: - Post Creation View
    private var postCreationView: some View {
        VStack(spacing: 18) {
            headerView

            VStack(spacing: 0) {
                mediaSection
                textComposerSection
            }

            Spacer(minLength: 0)

            bottomActionRow
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: handleNextButtonPress) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor((isButtonDisabled || isSubmitting) ? .gray : .white)
            }
            .disabled(isButtonDisabled || isSubmitting)
            .onAppear {
                print("🔘 PostPopup - Button state on appear: disabled=\(isButtonDisabled)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .zIndex(1) // ensure header stays above other layers for hit testing
    }
    
    // MARK: - Media Section
    private var mediaSection: some View {
        let clipShape = RoundedCornerShape(radius: sectionCornerRadius, corners: [.topLeft, .topRight])

        return ZStack(alignment: .topTrailing) {
            Group {
                if let imageData = selectedImageData,
                   let uiImage = UIImage(data: imageData)?.fixOrientation() {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(mediaAspectRatio, contentMode: .fill)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.0),
                                    Color.black.opacity(0.55)
                                ],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                } else {
                    ZStack(spacing: 10) {
                        clipShape
                            .fill(.ultraThinMaterial)
                            .overlay(clipShape.fill(Color.black.opacity(0.28)))
                            .overlay(clipShape.stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                            .compositingGroup()
                            .blur(radius: 12)

                        VStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20, weight: .medium))
                            Text("写真を追加")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(mediaAspectRatio, contentMode: .fit)
                }
            }
            .frame(maxWidth: .infinity)
            .clipShape(clipShape)
            .overlay(clipShape.stroke(Color.white.opacity(0.08), lineWidth: 0.6))
            .shadow(color: Color.black.opacity(hasSelectedImage ? 0.25 : 0.18), radius: hasSelectedImage ? 18 : 12, x: 0, y: 6)

            if hasSelectedImage {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedImageData = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
                }
                .padding(12)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hasSelectedImage)
    }

    // MARK: - Text Composer View
    private var textComposerSection: some View {
        let corners: UIRectCorner = hasSelectedImage ? [.bottomLeft, .bottomRight] : [.allCorners]
        let shape = RoundedCornerShape(radius: sectionCornerRadius, corners: corners)

        return VStack(alignment: .trailing, spacing: 6) {
            TextField("何を投稿しますか？", text: Binding(
                get: { postText },
                set: { newValue in
                    postText = newValue
                }
            ), axis: .vertical)
            .font(.system(size: 16))
            .foregroundColor(postText.count > maxTextLength ? .red : .white)
            .lineLimit(8)
            .textFieldStyle(PlainTextFieldStyle())
            .scrollContentBackground(.hidden)

            Text("\(postText.count)/\(maxTextLength)")
                .font(.system(size: 12))
                .foregroundColor(
                    postText.count > maxTextLength
                        ? .red
                        : (postText.count >= maxTextLength ? .orange : .white.opacity(0.7))
                )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            glassSectionBackground(
                corners: corners,
                radius: sectionCornerRadius,
                opacity: hasSelectedImage ? 0.45 : 0.32
            )
        )
        .clipShape(shape)
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
    }

    // MARK: - Bottom Action Row
    private var bottomActionRow: some View {
        let shape = RoundedCornerShape(radius: sectionCornerRadius, corners: [.allCorners])

        return HStack(spacing: 14) {
            Button(action: {
                print("📍🔥 PostPopup: Location button ACTION TRIGGERED!")
                moveToCurrentLocation()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: postLocation != nil ? "location.fill" : "location")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.accentRed)

                    Text("現在地")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("現在地に移動")

            Spacer()

            Button(action: checkCameraPermissionAndOpen) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.45))
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .background(
            glassSectionBackground(
                corners: [.allCorners],
                radius: sectionCornerRadius,
                opacity: 0.26
            )
        )
        .clipShape(shape)
    }

    private func glassSectionBackground(
        corners: UIRectCorner,
        radius: CGFloat,
        opacity: Double,
        blurRadius: CGFloat = 14
    ) -> some View {
        let shape = RoundedCornerShape(radius: radius, corners: corners)

        return shape
            .fill(.ultraThinMaterial)
            .overlay(shape.fill(Color.black.opacity(opacity)))
            .overlay(shape.stroke(Color.white.opacity(0.08), lineWidth: 0.6))
            .compositingGroup()
            .blur(radius: blurRadius)
    }
    
    // MARK: - Privacy Selection View
    private var privacySelectionView: some View {
        VStack(spacing: 0) {
            privacyHeaderView
            Spacer()
            privacyButtonsView
            Spacer()
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
    
    // MARK: - Privacy Header View
    private var privacyHeaderView: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPrivacySelection = false
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("公開範囲")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // バランス用の空スペース
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Privacy Buttons View
    private var privacyButtonsView: some View {
        VStack(spacing: 16) {
            // Followers Only
            Button(action: {
                guard !isSubmitting else { return }
                selectedPrivacyType = .followersOnly
                createPost()
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                    }
                    
                    Text("Followers Only")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 160, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Public
            Button(action: {
                guard !isSubmitting else { return }
                selectedPrivacyType = .publicPost
                createPost()
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "globe")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Public")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 160, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Anonymous
            Button(action: {
                guard !isSubmitting else { return }
                selectedPrivacyType = .anonymous
                createPost()
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 22))
                            .foregroundColor(.purple)
                    }
                    
                    Text("Anonymous")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 160, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Speech Bubble Tail
    private var speechBubbleTail: some View {
        Triangle()
            .fill(hasSelectedImage ? Color.black.opacity(0.85) : customBlack.opacity(0.9))
            .frame(width: 20, height: 15)
            .rotationEffect(.degrees(180))
            .offset(y: 15)
    }
    
    // MARK: - Action Methods
    private func handleNextButtonPress() {
        print("🔘 PostPopup - Next button pressed")
        print("📝 PostPopup - Current state: text='\(postText)', hasImage=\(selectedImageData != nil)")
        print("🚫 PostPopup - Button disabled state: \(isButtonDisabled)")
        if let imageData = selectedImageData {
            print("📸 PostPopup - Image data size at button press: \(imageData.count) bytes")
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            showPrivacySelection = true
        }
    }
    
    private func createPost() {
        guard !isSubmitting else { return }
        isSubmitting = true

        // Capture values to avoid self reference issues
        let currentText = postText
        let currentImageData = selectedImageData
        let currentPrivacyType = selectedPrivacyType
        // Use speech bubble tip position (V先端) if available, otherwise use map center
        let location = mapManager.draftPostCoordinate ?? initialLocation ?? mapManager.region.center

        print("📍 PostPopupView: Creating post at location: (\(location.latitude), \(location.longitude))")

        // Create post in background without waiting for result
        Task.detached {
            do {
                try await postManager.createPost(
                    content: currentText,
                    imageData: currentImageData,
                    location: location,
                    locationName: nil,
                    isAnonymous: currentPrivacyType == .anonymous
                )
            } catch {
                // Silently handle errors in background
            }
        }

        // Close immediately
        postText = ""
        selectedImageData = nil
        showPrivacySelection = false
        isSubmitting = false
        isPresented = false
    }

    // 選択座標のエリア名を軽量に解決（投稿時のみ）
    private func resolveAreaName(for coordinate: CLLocationCoordinate2D) async -> String? {
        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "\(coordinate.latitude),\(coordinate.longitude)"
            request.resultTypes = [.address]
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            if let mapItem = response.mapItems.first {
                var components: [String] = []
                if let name = mapItem.name {
                    let cleaned = name
                        .replacingOccurrences(of: #"[0-9]+-[0-9]+.*"#, with: "", options: .regularExpression)
                        .replacingOccurrences(of: #"[0-9]+番地.*"#, with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleaned.isEmpty { components.append(cleaned) }
                }
                if components.isEmpty { components.append("Near Current Location") }
                return components.prefix(2).joined(separator: " ")
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private func checkCameraPermissionAndOpen() {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthStatus {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showingCamera = true
                    } else {
                        self.showingCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showingCameraPermissionAlert = true
            }
        @unknown default:
            DispatchQueue.main.async {
                self.showingCameraPermissionAlert = true
            }
        }
    }
    
    private func getCurrentLocationAndMoveMap() {
        print("📍 PostPopup - Location button tapped, getting current location")
        // If denied, surface an alert guiding the user to Settings
        if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
            showingLocationPermissionAlert = true
            return
        }
        locationManager.requestLocationPermission()
        
        if let currentLocation = locationManager.location {
            print("✅ PostPopup - Got current location: \(currentLocation.latitude), \(currentLocation.longitude)")
            mapManager.focusOnLocation(currentLocation)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let center = self.mapManager.region.center
                self.postLocation = center
                self.updateAreaLocation(for: center)
            }
        } else {
            print("🔄 PostPopup - Requesting location update...")
            locationManager.requestLocationUpdate { location in
                if let location = location {
                    print("✅ PostPopup - Got location update: \(location.latitude), \(location.longitude)")
                    
                    // 画面下部に位置マーカーが来るように、マップの中心を少し北側にオフセット
                    let offsetCoordinate = CLLocationCoordinate2D(
                        latitude: location.latitude + 0.003, // 北に約300m移動
                        longitude: location.longitude
                    )
                    self.mapManager.focusOnLocation(offsetCoordinate)
                    // postLocation は設定せず、地図移動のみ
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // 何も設定しない - 位置ボタンは地図移動のみ
                    }
                } else {
                    print("❌ PostPopup - Failed to get location")
                    self.areaName = "位置情報を取得できません"
                }
            }
        }
    }
    
    private func updatePostLocation() {
        if let initialLocation = initialLocation {
            print("🗺️ PostPopup - Using provided initial location: \(initialLocation.latitude), \(initialLocation.longitude)")
            // 投稿座標は指定の地点。地図は動かさない（ユーザーの意図を優先）
            postLocation = initialLocation
            updateAreaLocation(for: initialLocation)
        } else {
            // 投稿座標は「地図の中心」
            let center = mapManager.region.center
            print("🗺️ PostPopup - Using map center for post: \(center.latitude), \(center.longitude)")
            postLocation = center
            updateAreaLocation(for: center)
        }
    }
    
    private func updateAreaLocation(for coordinate: CLLocationCoordinate2D) {
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = "\(coordinate.latitude),\(coordinate.longitude)"
                request.resultTypes = [.address]
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                if let mapItem = response.mapItems.first {
                    DispatchQueue.main.async {
                        var components: [String] = []
                        
                        if let name = mapItem.name {
                            let cleanedName = name
                                .replacingOccurrences(of: #"[0-9]+-[0-9]+.*"#, with: "", options: .regularExpression)
                                .replacingOccurrences(of: #"[0-9]+番地.*"#, with: "", options: .regularExpression)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if !cleanedName.isEmpty {
                                components.append(cleanedName)
                            }
                        }
                        
                        if components.isEmpty {
                            components.append("Near Current Location")
                        }
                        
                        self.areaName = components.prefix(2).joined(separator: " ")
                        
                        if self.areaName.isEmpty {
                            self.areaName = "不明な場所"
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.areaName = "位置情報を取得できませんでした"
                }
            }
        }
    }

    // MARK: - Move to current location
    private func moveToCurrentLocation() {
        print("📍🔥 PostPopup: Location button pressed - Moving to current location")

        // Start location services if not already started
        mapLocationService.startLocationServices()

        // Request immediate location update
        mapLocationService.requestLocation()

        // Use CLLocationManager directly as a fallback
        let locationManager = CLLocationManager()

        if let location = locationManager.location {
            print("📍🔥 PostPopup: Using CLLocationManager location: \(location.coordinate)")

            // 画面下部に位置マーカーが来るように、マップの中心を少し北側にオフセット
            let offsetCoordinate = CLLocationCoordinate2D(
                latitude: location.coordinate.latitude + 0.003, // 北に約300m移動
                longitude: location.coordinate.longitude
            )
            mapManager.focusOnLocation(offsetCoordinate)

            // DON'T update post location - keep it at speech bubble tip position
            print("📍🔥 PostPopup: Map moved to current location, but post location remains unchanged")
        } else if let mapLocation = mapLocationService.location {
            print("📍🔥 PostPopup: Using MapLocationService location: \(mapLocation.coordinate)")

            // 画面下部に位置マーカーが来るように、マップの中心を少し北側にオフセット
            let offsetCoordinate = CLLocationCoordinate2D(
                latitude: mapLocation.coordinate.latitude + 0.003, // 北に約300m移動
                longitude: mapLocation.coordinate.longitude
            )
            mapManager.focusOnLocation(offsetCoordinate)

            // DON'T update post location - keep it at speech bubble tip position
            print("📍🔥 PostPopup: Map moved to current location, but post location remains unchanged")
        } else {
            print("📍🔥 PostPopup: No location available, requesting permission...")
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // MARK: - Auto acquire current location on demand
    private func autoAcquireCurrentLocation() {
        print("📍🔥 PostPopup: autoAcquireCurrentLocation called")
        
        // Request permission if needed, then try to read cached location first
        print("📍🔥 PostPopup: Requesting location permission...")
        locationManager.requestLocationPermission()

        if let loc = locationManager.location {
            // Use immediate value if available
            print("📍🔥 PostPopup: Using cached location: \(loc)")
            // postLocation は設定しない - 位置ボタンは地図移動のみ
            print("📍🔥 PostPopup: Calling mapManager.focusOnLocation...")
            
            // 画面下部に位置マーカーが来るように、マップの中心を少し北側にオフセット
            let offsetCoordinate = CLLocationCoordinate2D(
                latitude: loc.latitude + 0.003, // 北に約300m移動
                longitude: loc.longitude
            )
            self.mapManager.focusOnLocation(offsetCoordinate)
            // updateAreaLocation も呼ばない - 投稿位置とは切り離し
            return
        }

        print("📍🔥 PostPopup: No cached location, requesting one-shot update...")
        // Otherwise request a one-shot update
        locationManager.requestLocationUpdate { coordinate in
            print("📍🔥 PostPopup: One-shot update callback received: \(String(describing: coordinate))")
            if let c = coordinate {
                // postLocation は設定しない - 位置ボタンは地図移動のみ
                print("📍🔥 PostPopup: Calling mapManager.focusOnLocation with new location...")
                
                // 画面下部に位置マーカーが来るように、マップの中心を少し北側にオフセット
                let offsetCoordinate = CLLocationCoordinate2D(
                    latitude: c.latitude + 0.003, // 北に約300m移動
                    longitude: c.longitude
                )
                self.mapManager.focusOnLocation(offsetCoordinate)
                // updateAreaLocation も呼ばない - 投稿位置とは切り離し
            } else {
                print("📍🔥 PostPopup: No coordinate received, falling back to map center")
                // Fallback to current map center
                self.updatePostLocation()
            }
        }
    }
}

// MARK: - Rounded Corner Helper
private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Triangle shape for speech bubble
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - V Tip Preference
struct VTipPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint? = nil
    static func reduce(value: inout CGPoint?, nextValue: () -> CGPoint?) {
        if let next = nextValue() { value = next }
    }
}

// MARK: - PostLocationManager for PostPopup
class PostLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var locationUpdateCompletion: ((CLLocationCoordinate2D?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    func requestLocationUpdate(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        locationUpdateCompletion = completion
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        } else if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            completion(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.location = location.coordinate
            self.locationUpdateCompletion?(location.coordinate)
            self.locationUpdateCompletion = nil
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationUpdateCompletion?(nil)
        locationUpdateCompletion = nil
    }
}
