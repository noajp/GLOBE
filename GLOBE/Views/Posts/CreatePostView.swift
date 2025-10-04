//======================================================================
// MARK: - CreatePostView.swift
// Purpose: Post creation popup with full-screen photo background
// Path: GLOBE/Views/Posts/CreatePostView.swift
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


struct CreatePostView: View {
    @Binding var isPresented: Bool
    let mapManager: MapManager  // Remove @ObservedObject
    let initialLocation: CLLocationCoordinate2D? // Add parameter for exact post location
    var postType: PostType = .textPost // Default to text post
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
    @State private var showPrivacyDropdown = false
    @State private var selectedPrivacyType: PostPrivacyType = .anonymous
    @State private var isSubmitting = false
    @State private var showingCamera = false
    @State private var selectedImageData: Data?
    // App settings
    @StateObject private var appSettings = AppSettings.shared
    
    // Computed properties to reduce complexity
    private var isButtonDisabled: Bool {
        postText.isEmpty || weightedCharacterCount > Double(maxTextLength)
    }

    // 投稿ボタンがアクティブになる条件を集約
    private var isPostActionEnabled: Bool {
        !postText.isEmpty && weightedCharacterCount <= Double(maxTextLength) && !isSubmitting
    }

    // 重み付き文字数カウント（日中韓=1.0、アルファベット=0.5）
    private var weightedCharacterCount: Double {
        postText.reduce(0.0) { count, character in
            let scalar = character.unicodeScalars.first
            guard let unicodeScalar = scalar else { return count + 1.0 }

            // 日本語（ひらがな、カタカナ、漢字）、中国語、韓国語
            let isAsianCharacter = (0x3040...0x309F).contains(unicodeScalar.value) || // ひらがな
                                   (0x30A0...0x30FF).contains(unicodeScalar.value) || // カタカナ
                                   (0x4E00...0x9FFF).contains(unicodeScalar.value) || // 漢字（CJK統合漢字）
                                   (0xAC00...0xD7AF).contains(unicodeScalar.value)    // ハングル

            return count + (isAsianCharacter ? 1.0 : 0.5)
        }
    }

    private var maxTextLength: Int {
        // 画像の有無で制限値を変更
        return selectedImageData != nil ? 15 : 30
    }
    
    var body: some View {
        ZStack {
            // Popup content with speech bubble design
            GlassEffectContainer {
                VStack(spacing: 0) {
                    // Main card with rounded corners
                    VStack(spacing: 0) {
                        postCreationView
                    }
                    .frame(width: 280, height: selectedImageData != nil ? 360 : 210)
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                    // Simple triangle tail below card
                    Triangle()
                        .fill(Color.clear)
                        .frame(width: 50, height: 25)
                        .glassEffect(.clear, in: Triangle())
                        .rotationEffect(.degrees(180))
                        .offset(y: -1) // Slight overlap to hide seam
                }
            }
            .shadow(radius: 10)
            // TEMPORARILY DISABLED - VTipPreferenceKey causes crashes
            // .overlay(alignment: .bottom) {
            //     GeometryReader { proxy in
            //         Color.clear
            //             .frame(width: 1, height: 1)
            //             .preference(key: VTipPreferenceKey.self, value: {
            //                 let f = proxy.frame(in: .global)
            //                 // Speech bubble tail tip position (integrated into shape)
            //                 return CGPoint(x: f.midX, y: f.maxY)
            //             }())
            //     }
            //     .frame(width: 1, height: 1)
            // }

            // Privacy selection popup from bottom
            if showPrivacyDropdown {
                Color.black.opacity(0.001) // Invisible tap area
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showPrivacyDropdown = false
                        }
                    }

                privacyPopupView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPrivacyDropdown)
        .onDisappear {
            // Clean up when popup closes
            mapManager.draftPostCoordinate = nil
            postLocation = nil
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
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(selectedImageData: $selectedImageData)
        }
        .onAppear {
            // Use initial location if provided
            if let initial = initialLocation {
                postLocation = initial
            }
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
        Rectangle()
            .fill(Color.clear)
            .frame(width: 280, height: 52)
            .overlay(alignment: .topLeading) {
                headerCloseButton
                    .padding(.leading, 8)
                    .padding(.top, 8)
            }
            .overlay(alignment: .topTrailing) {
                postActionButton
                    .padding(.trailing, 4)
                    .padding(.top, 8)
            }
    }

    private var headerCloseButton: some View {
        Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            isPresented = false
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(glassCircleBackground)
                .clipShape(Circle())
                .overlay(circleStrokeOverlay)
        }
        .shadow(color: Color.black.opacity(0.22), radius: 6, x: 0, y: 4)
        .accessibilityLabel(Text("投稿を閉じる"))
    }

    private var postActionButton: some View {
        HStack(spacing: 6) {
            // Chevron button - separate and simple
            Button(action: {
                print("🔄 Privacy dropdown button pressed...")
                DispatchQueue.main.async {
                    showPrivacyDropdown.toggle()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(.black))
            }
            .padding(.leading, 4)

            // POST button - separate and simple
            Button(action: {
                print("📝 POST button pressed...")
                // 画像がある場合はテキストなしでもOK
                let hasValidContent = selectedImageData != nil || (!postText.isEmpty && postText.count <= maxTextLength)
                guard hasValidContent else {
                    print("❌ POST validation failed")
                    return
                }
                createPost()
            }) {
                Text("POST")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.leading, 0)
                    .padding(.trailing, 10)
                    .padding(.vertical, 6)
            }
        }
        .background(simpleWhiteBackground)
        .clipShape(Capsule())
        .frame(width: 80)
    }

    private var simpleWhiteBackground: some View {
        Capsule()
            .fill(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
    }

    // MARK: - Circular Progress Counter
    private var circularProgressCounter: some View {
        let progress = min(weightedCharacterCount / Double(maxTextLength), 1.0)
        let isOverLimit = weightedCharacterCount > Double(maxTextLength)
        let isNearLimit = weightedCharacterCount >= Double(maxTextLength) * 0.9

        return ZStack {
            // 背景の円
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2.5)

            // プログレスリング
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isOverLimit ? Color.red :
                    isNearLimit ? Color.orange :
                    Color.white.opacity(0.9),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: weightedCharacterCount)
        }
        .frame(width: 26, height: 26)
    }
    
    
    // MARK: - Text Input View
    private var textInputView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // 画像プレビュー
            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                VStack(spacing: 4) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 248, height: 248)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        // 削除ボタン
                        Button(action: {
                            selectedImageData = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(Circle().fill(.black.opacity(0.6)))
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }

                    // 画像がある時のテキスト入力
                    TextField("text", text: Binding(
                        get: { postText },
                        set: { newValue in
                            postText = newValue
                        }
                    ), axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundColor(weightedCharacterCount > Double(maxTextLength) ? .red : .white)
                    .lineLimit(2)
                    .textFieldStyle(PlainTextFieldStyle())
                    .scrollContentBackground(.hidden)
                }
            } else {
                // 画像がない時のみテキスト入力を表示
                TextField("text", text: Binding(
                    get: { postText },
                    set: { newValue in
                        postText = newValue
                    }
                ), axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(weightedCharacterCount > Double(maxTextLength) ? .red : .white)
                .lineLimit(10)
                .textFieldStyle(PlainTextFieldStyle())
                .scrollContentBackground(.hidden)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Bottom Section View 
    private var bottomSectionView: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 280, height: 56)
            .overlay(alignment: .bottom) {
                HStack(alignment: .center) {
                    locationActionButton

                    Spacer()

                    if showPrivacyDropdown {
                        privacyDescriptionLabel
                            .transition(.opacity.combined(with: .scale))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        circularProgressCounter
                        cameraActionButton
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
    }

    private var locationActionButton: some View {
        Button(action: handleLocationButton) {
            Image(systemName: postLocation != nil ? "location.fill" : "location")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(glassCircleBackground)
                .clipShape(Circle())
                .overlay(circleStrokeOverlay)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 5, x: 0, y: 3)
    }

    private var cameraActionButton: some View {
        Button(action: handleCameraButton) {
            Image(systemName: "camera.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(glassCircleBackground)
                .clipShape(Circle())
                .overlay(circleStrokeOverlay)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 5, x: 0, y: 3)
    }

    private var privacyDescriptionLabel: some View {
        Text(
            selectedPrivacyType == .publicPost ? "Post publicly" :
            selectedPrivacyType == .followersOnly ? "Post to followers" : "Post anonymously"
        )
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.white.opacity(0.85))
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.6)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.15), lineWidth: 0.6)
                        .blendMode(.overlay)
                )
        )
        .clipShape(Capsule())
    }

    private func handleLocationButton() {
        // Request location permission if needed
        mapLocationService.startLocationServices()

        // Move to current location if available
        if let currentLocation = mapLocationService.location?.coordinate {
            mapManager.focusOnLocation(currentLocation, zoomLevel: 0.0008)
            postLocation = currentLocation
        }
    }

    private func handleCameraButton() {
        print("📷 CreatePostView: Camera button pressed")
        showingCamera = true
    }

    private var glassCircleBackground: some View {
        Circle()
            .fill(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
    }

    private var circleBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color.white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var circleStrokeOverlay: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color.black.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.9
            )
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

    // MARK: - Privacy Popup View
    private var privacyPopupView: some View {
        VStack {
            Spacer()
            Spacer() // Additional spacer to push popup lower
            Spacer() // Extra spacer to push popup even lower

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select Privacy")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPrivacyDropdown = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Privacy options
                VStack(alignment: .leading, spacing: 1) {
                    privacyPopupOption(.anonymous, "person.fill.questionmark", .black, "Post anonymously", "Your identity will be hidden")
                    privacyPopupOption(.publicPost, "globe", .black, "Post publicly", "Everyone can see this post")
                    privacyPopupOption(.followersOnly, "person.2.fill", .black, "Post to followers", "Only your followers can see this")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.black.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 20)
            .shadow(radius: 10)
        }
    }

    private func privacyPopupOption(_ type: PostPrivacyType, _ icon: String, _ color: Color, _ title: String, _ subtitle: String) -> some View {
        Button(action: {
            selectedPrivacyType = type
            withAnimation(.easeInOut(duration: 0.3)) {
                showPrivacyDropdown = false
            }
        }) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 24, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    HStack {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.black.opacity(0.6))
                        Spacer()
                    }
                }

                if selectedPrivacyType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(selectedPrivacyType == type ? .black.opacity(0.05) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Action Methods

    private func createPost() {
        print("🚀 CreatePost: Starting post creation")

        // Capture values before closing UI
        let text = postText
        let privacy = selectedPrivacyType
        // 常に画面中央（吹き出しの先端が指す位置）の座標を使用
        let loc = mapManager.region.center
        let imageData = selectedImageData

        print("📍 CreatePost: Location (bubble tip) - \(loc.latitude), \(loc.longitude)")
        print("📝 CreatePost: Text - \(text)")
        print("🔒 CreatePost: Privacy - \(privacy)")
        print("📷 CreatePost: Has image - \(imageData != nil)")

        // Close UI immediately
        isPresented = false

        // Create post after UI is closed
        Task {
            do {
                try await postManager.createPost(
                    content: text,
                    imageData: imageData,
                    location: loc,
                    locationName: nil,
                    isAnonymous: privacy == .anonymous
                )
                print("✅ CreatePost: Post created successfully")
            } catch {
                print("❌ CreatePost: Failed to create post - \(error)")
            }
        }
    }


    // MARK: - Helper Functions
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

    
    private func updateAreaLocation(for coordinate: CLLocationCoordinate2D) {
        // Disabled to prevent deadlock - area name resolution is not critical for posting
        areaName = ""
    }
    
    private func moveToCurrentLocation() {
        // Removed - using simpler inline approach in button action
    }

    // MARK: - Auto acquire current location on demand
    private func autoAcquireCurrentLocation() {
        // Removed - using simpler inline approach in button action
    }
    
    private func updatePostLocation() {
        postLocation = mapManager.region.center
    }
}


// MARK: - Speech Bubble Shape - TEMPORARILY DISABLED DUE TO CRASHES
// Replaced with separate RoundedRectangle and Triangle components

// MARK: - V Tip Preference - TEMPORARILY DISABLED
// struct VTipPreferenceKey: PreferenceKey {
//     static var defaultValue: CGPoint = CGPoint.zero
//     static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
//         value = nextValue()
//     }
// }
