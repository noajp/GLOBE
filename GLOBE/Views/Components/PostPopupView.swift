//======================================================================
// MARK: - PostPopupView.swift
// Purpose: Post creation popup with full-screen photo background
// Path: GLOBE/Views/Components/PostPopupView.swift
//======================================================================
import SwiftUI
import UIKit
import CoreLocation
import MapKit
import Combine

// MARK: - Post Privacy Options
enum PostPrivacyType: Equatable, Sendable {
    case followersOnly
    case publicPost
    case anonymous
}

// MARK: - Post Type Options
enum PostType: Equatable, Sendable, CaseIterable {
    case textPost
    case photoPost
    case locationPost
    case eventPost

    var displayName: String {
        switch self {
        case .textPost: return "テキスト"
        case .photoPost: return "写真"
        case .locationPost: return "位置情報"
        case .eventPost: return "イベント"
        }
    }

    var icon: String {
        switch self {
        case .textPost: return "text.alignleft"
        case .photoPost: return "camera.fill"
        case .locationPost: return "location.fill"
        case .eventPost: return "calendar"
        }
    }

    var color: Color {
        switch self {
        case .textPost: return .blue
        case .photoPost: return .green
        case .locationPost: return .red
        case .eventPost: return .purple
        }
    }
}


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
    
    @State private var postText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingLocationPermissionAlert = false
    @State private var postLocation: CLLocationCoordinate2D?
    // 位置決定は地図の中心に揃える（Vの先端=地図中心）。余計なオフセットは使わない。
    @State private var areaName: String = ""
    @State private var showPrivacySelection = false
    @State private var showPostTypeSelection = false
    @State private var selectedPrivacyType: PostPrivacyType = .publicPost
    @State private var selectedPostType: PostType = .textPost
    @State private var isSubmitting = false
    // App settings
    @StateObject private var appSettings = AppSettings.shared
    
    // Computed properties to reduce complexity
    private var isButtonDisabled: Bool {
        let hasText = !postText.isEmpty
        let disabled = !hasText
        print("🔘 PostPopup - isButtonDisabled calculated: \(disabled) (hasText=\(hasText))")
        return disabled
    }
    
    private var maxTextLength: Int {
        60  // Text-only posts can use the full length
    }
    
    var body: some View {
        ZStack {
            // Popup content with speech bubble tail
            GlassEffectContainer {
                VStack(spacing: 0) {
                    if showPostTypeSelection {
                        postTypeSelectionView
                    } else if showPrivacySelection {
                        privacySelectionView
                    } else {
                        postCreationView
                    }
                }
                .frame(width: 270, height: 189)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                // Note: Do not add a parent onTapGesture here; it can interfere with inner Buttons
                .overlay(
                    speechBubbleTail
                        .allowsHitTesting(false),
                    alignment: .bottom
                )
                .shadow(radius: 10)
            }
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
        .animation(.easeInOut(duration: 0.3), value: showPostTypeSelection)
        .onDisappear {
            mapManager.draftPostCoordinate = nil
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

        }
    }
    
    // MARK: - Post Creation View
    private var postCreationView: some View {
        VStack(spacing: 0) {
            headerView
            textInputView
            Spacer()
            bottomSectionView
        }
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
                    .foregroundColor(.black)
                    .padding(8)
            }
            .background(.white.opacity(0.9))
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
            
            Spacer()
            
            Button(action: handleVButtonPress) {
                HStack(spacing: 3) {
                    Text("POST")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.black)

                    Triangle()
                        .fill(.black)
                        .frame(width: 8, height: 6)
                        .rotationEffect(.degrees(180))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .background(.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.3), lineWidth: 1))
            .disabled(isButtonDisabled || isSubmitting)
            .onAppear {
                print("🔘 PostPopup - Button state on appear: disabled=\(isButtonDisabled)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .zIndex(1) // ensure header stays above other layers for hit testing
    }
    
    
    // MARK: - Text Input View
    private var textInputView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            TextField("何を投稿しますか？", text: Binding(
                get: { postText },
                set: { newValue in
                    postText = newValue
                }
            ), axis: .vertical)
            .font(.system(size: 16))
            .foregroundColor(postText.count > maxTextLength ? .red : .white)
            .lineLimit(10)
            .textFieldStyle(PlainTextFieldStyle())
            .scrollContentBackground(.hidden)
            
            // 文字数カウンター
            Text("\(postText.count)/\(maxTextLength)")
                .font(.system(size: 12))
                .foregroundColor(postText.count > maxTextLength ? .red : (postText.count >= maxTextLength ? .orange : .white.opacity(0.6)))
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    
    // MARK: - Bottom Section View
    private var bottomSectionView: some View {
        HStack {
            // Location info button - move to current location
            Button(action: {
                print("📍🔥 PostPopup: Location button ACTION TRIGGERED!")
                moveToCurrentLocation()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: postLocation != nil ? "location.fill" : "location")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .medium))

                    if !areaName.isEmpty {
                        Text(areaName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .background(.white.opacity(0.9))
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
            
            Spacer()
            
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Post Type Selection View
    private var postTypeSelectionView: some View {
        VStack(spacing: 0) {
            postTypeHeaderView
            Spacer()
            postTypeButtonsView
            Spacer()
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
    }

    // MARK: - Post Type Header View
    private var postTypeHeaderView: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPostTypeSelection = false
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }

            Spacer()

            Text("投稿タイプ")
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

    // MARK: - Post Type Buttons View
    private var postTypeButtonsView: some View {
        HStack(spacing: 12) {
            ForEach(Array(PostType.allCases.enumerated()), id: \.element) { index, postType in
                Button(action: {
                    selectedPostType = postType
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showPostTypeSelection = false
                        showPrivacySelection = true
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(postType.color.opacity(0.2))
                                .frame(width: 30, height: 30)

                            Image(systemName: postType.icon)
                                .font(.system(size: 14))
                                .foregroundColor(postType.color)
                        }

                        Text(postType.displayName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 55)
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(postType.color.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
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
                createPostWithSelectedType()
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
                .frame(width: 180, height: 85)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Public
            Button(action: {
                guard !isSubmitting else { return }
                selectedPrivacyType = .publicPost
                createPostWithSelectedType()
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
                .frame(width: 180, height: 85)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Anonymous
            Button(action: {
                guard !isSubmitting else { return }
                selectedPrivacyType = .anonymous
                createPostWithSelectedType()
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
                .frame(width: 180, height: 85)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Speech Bubble Tail
    private var speechBubbleTail: some View {
        Triangle()
            .fill(Color.clear)
            .frame(width: 20, height: 15)
            .glassEffect(.clear, in: Triangle())
            .rotationEffect(.degrees(180))
            .offset(y: 15)
    }
    
    // MARK: - Action Methods
    private func handleVButtonPress() {
        print("🔘 PostPopup - V button pressed")
        print("📝 PostPopup - Current state: text='\(postText)'")
        print("🚫 PostPopup - Button disabled state: \(isButtonDisabled)")
        withAnimation(.easeInOut(duration: 0.3)) {
            showPostTypeSelection = true
        }
    }

    private func handleNextButtonPress() {
        print("🔘 PostPopup - Next button pressed")
        print("📝 PostPopup - Current state: text='\(postText)'")
        print("🚫 PostPopup - Button disabled state: \(isButtonDisabled)")
        withAnimation(.easeInOut(duration: 0.3)) {
            showPrivacySelection = true
        }
    }
    
    private func createPost() {
        guard !isSubmitting else { return }
        isSubmitting = true

        // Capture values to avoid self reference issues
        let currentText = postText
        let currentPrivacyType = selectedPrivacyType
        // Use speech bubble tip position (V先端) if available, otherwise use map center
        let location = mapManager.draftPostCoordinate ?? initialLocation ?? mapManager.region.center

        print("📍 PostPopupView: Creating post at location: (\(location.latitude), \(location.longitude))")

        // Create post in background without waiting for result
        Task.detached {
            do {
                try await postManager.createPost(
                    content: currentText,
                    imageData: nil,  // No image data for text-only posts
                    location: location,
                    locationName: nil,
                    isAnonymous: {
                        switch currentPrivacyType {
                        case .anonymous: return true
                        default: return false
                        }
                    }()
                )
            } catch {
                // Silently handle errors in background
            }
        }

        // Close immediately
        postText = ""
        showPrivacySelection = false
        isSubmitting = false
        isPresented = false
    }

    private func createPostWithSelectedType() {
        guard !isSubmitting else { return }
        isSubmitting = true

        // Capture values to avoid self reference issues
        let currentText = postText
        let currentPrivacyType = selectedPrivacyType
        let currentPostType = selectedPostType
        // Use speech bubble tip position (V先端) if available, otherwise use map center
        let location = mapManager.draftPostCoordinate ?? initialLocation ?? mapManager.region.center

        print("📍 PostPopupView: Creating \(currentPostType.displayName) post at location: (\(location.latitude), \(location.longitude))")

        // Create post in background without waiting for result
        Task.detached {
            do {
                try await postManager.createPost(
                    content: currentText,
                    imageData: nil,  // No image data for now
                    location: location,
                    locationName: nil,
                    isAnonymous: {
                        switch currentPrivacyType {
                        case .anonymous: return true
                        default: return false
                        }
                    }()
                )
            } catch {
                // Silently handle errors in background
            }
        }

        // Close immediately
        postText = ""
        showPrivacySelection = false
        showPostTypeSelection = false
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
                // Skip if no meaningful location name found
                return components.prefix(2).joined(separator: " ")
            }
        } catch {
            return nil
        }
        return nil
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let center = self.mapManager.region.center
                        self.postLocation = center
                        self.updateAreaLocation(for: center)
                    }
                } else {
                    print("⚠️ PostPopup - Failed to get location update")
                }
            }
        }
    }
    
    private func updateAreaLocation(for coordinate: CLLocationCoordinate2D) {
        Task {
            if let area = await resolveAreaName(for: coordinate) {
                await MainActor.run {
                    self.areaName = area
                }
            }
        }
    }
    
    private func moveToCurrentLocation() {
        print("📍🔥 PostPopup: moveToCurrentLocation called")

        // Check location services availability off main thread
        Task.detached {
            let servicesEnabled = await Task.detached { CLLocationManager.locationServicesEnabled() }.value

            await MainActor.run {
                guard servicesEnabled else {
                    print("🚫 PostPopup: Location services disabled")
                    showingLocationPermissionAlert = true
                    return
                }

                // If we already have permission, go straight to the location manager's helper
                if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
                    print("✅ PostPopup: Already authorized, calling autoAcquireCurrentLocation")
                    autoAcquireCurrentLocation()
                    return
                }

                switch locationManager.authorizationStatus {
                case .notDetermined:
                    print("❔ PostPopup: Authorization not determined, requesting...")
                    locationManager.requestLocationPermission()
                    // After requesting, try to auto acquire (CLLocationManager will callback via delegate)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.autoAcquireCurrentLocation()
                    }
                case .denied, .restricted:
                    print("🚫 PostPopup: Authorization denied or restricted, showing alert")
                    showingLocationPermissionAlert = true
                case .authorizedAlways, .authorizedWhenInUse:
                    print("✅ PostPopup: Authorization OK, auto-acquiring location")
                    autoAcquireCurrentLocation()
                @unknown default:
                    print("❌ PostPopup: Unknown authorization status")
                    showingLocationPermissionAlert = true
                }
            }
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
            print("📍🔥 PostPopup: Calling mapManager.focusOnLocation...")

            Task { @MainActor in
                // 画面下部に位置マーカーが来るように、マップの中心を少し北側にオフセット
                let offsetCoordinate = CLLocationCoordinate2D(
                    latitude: loc.latitude + 0.0005, // 北に約50m移動（カードが見えるように調整）
                    longitude: loc.longitude
                )
                // ズームインしながら現在地に遷移（focusOnLocationが内部でアニメーション処理をする）
                self.mapManager.focusOnLocation(offsetCoordinate, zoomLevel: 0.0008)

                // Update postLocation to show that location is set
                self.postLocation = loc
                self.updateAreaLocation(for: loc)

                // Move the post creation card to current location immediately
                self.mapManager.draftPostCoordinate = loc
            }
            return
        }

        print("📍🔥 PostPopup: No cached location, requesting one-shot update...")
        // Otherwise request a one-shot update
        locationManager.requestLocationUpdate { coordinate in
            print("📍🔥 PostPopup: One-shot update callback received: \(String(describing: coordinate))")
            if let c = coordinate {
                print("📍🔥 PostPopup: Calling mapManager.focusOnLocation with new location...")

                Task { @MainActor in
                    // 画面下部に位置マーカーが来るように、マップの中心を少し北側にオフセット
                    let offsetCoordinate = CLLocationCoordinate2D(
                        latitude: c.latitude + 0.0005, // 北に約50m移動（カードが見えるように調整）
                        longitude: c.longitude
                    )
                    // ズームインしながら現在地に遷移（focusOnLocationが内部でアニメーション処理をする）
                    self.mapManager.focusOnLocation(offsetCoordinate, zoomLevel: 0.0008)

                    // Update postLocation to show that location is set
                    self.postLocation = c
                    self.updateAreaLocation(for: c)

                    // Move the post creation card to current location immediately
                    self.mapManager.draftPostCoordinate = c
                }
            } else {
                print("📍🔥 PostPopup: No coordinate received, falling back to map center")
                // Fallback to current map center
                self.updatePostLocation()
            }
        }
    }
    
    private func updatePostLocation() {
        postLocation = mapManager.region.center
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
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocationUpdate(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        locationUpdateCompletion = completion
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            locationUpdateCompletion?(nil)
            locationUpdateCompletion = nil
            return
        }
        self.location = location.coordinate
        locationUpdateCompletion?(location.coordinate)
        locationUpdateCompletion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ PostLocationManager - Failed to get location: \(error.localizedDescription)")
        locationUpdateCompletion?(nil)
        locationUpdateCompletion = nil
    }
}
