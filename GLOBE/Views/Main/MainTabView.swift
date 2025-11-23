import SwiftUI
import MapKit
import CoreLocation

struct MainTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var postManager = PostManager.shared
    @StateObject private var mapManager = MapManager()
    @StateObject private var locationManager = MapLocationService()
    @StateObject private var appSettings = AppSettings.shared
    @State private var showingCreatePost = false
    @State private var showingAuth = false
    @State private var showingProfile = false
    @State private var shouldMoveToCurrentLocation = false
    @State private var notificationObservers: [NSObjectProtocol] = []
    @State private var shouldShowPostAfterDelay = false
    @State private var tappedLocation: CLLocationCoordinate2D?
    @State private var vTipPoint: CGPoint = CGPoint.zero
    @State private var hasSetInitialLocation = false
    @State private var showingSearch = false
    @State private var selectedUserIdForProfile: String?
    @State private var showingUserProfile = false


    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    
    var body: some View {
        GeometryReader { proxy in
            let safeInsets = proxy.safeAreaInsets

            ZStack {
                // Full screen map
                MapContentView(
                    mapManager: mapManager,
                    locationManager: locationManager,
                    postManager: postManager,
                    authManager: authManager,
                    showingCreatePost: $showingCreatePost,
                    shouldMoveToCurrentLocation: $shouldMoveToCurrentLocation,
                    tappedLocation: $tappedLocation,
                    vTipPoint: .constant(CGPoint.zero) // TEMPORARILY DISABLED
                )
                    .environmentObject(appSettings)
                    .ignoresSafeArea(.all)

                // Bottom UI: Search button and Tab bar
                HStack(spacing: 12) {
                    // Search button (left side) - circular glass effect
                    GlassEffectContainer {
                        Button(action: {
                            SecureLogger.shared.info("Search button tapped")
                            if showingCreatePost {
                                showingCreatePost = false
                            }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingSearch = true
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(width: 52, height: 52)
                        }
                    }
                    .coordinatedGlassEffect(id: "search-button")
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                    Spacer()

                    // Tab bar (right side)
                    LiquidGlassBottomTabBar(
                        onProfileTapped: {
                            SecureLogger.shared.info("Profile button tapped in tab bar")
                            // 投稿作成カードが開いている場合は閉じる
                            if showingCreatePost {
                                showingCreatePost = false
                            }
                            // 認証されている場合のみプロフィール画面を表示
                            if authManager.isAuthenticated {
                                showingProfile = true
                            } else {
                                showingAuth = true
                            }
                        },
                        onPostTapped: {
                            SecureLogger.shared.info("Post button tapped in tab bar")
                            if authManager.isAuthenticated {
                                // 投稿作成カードをトグル（開いている場合は閉じる）
                                if showingCreatePost {
                                    showingCreatePost = false
                                } else {
                                    tappedLocation = mapManager.region.center
                                    showingCreatePost = true
                                }
                            } else {
                                showingAuth = true
                            }
                        },
                        onLocationTapped: {
                            SecureLogger.shared.info("Location button tapped in tab bar")
                            // 投稿作成カードが開いている場合は閉じる
                            if showingCreatePost {
                                showingCreatePost = false
                            }

                            // Request location permission if needed
                            locationManager.startLocationServices()

                            // Move to current location if available
                            if let currentLocation = locationManager.location?.coordinate {
                                mapManager.focusOnLocation(currentLocation, zoomLevel: 0.0008)
                            }
                        }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: .center, vertical: .bottom))
                .padding(.leading, max(safeInsets.leading, 0) + 20)
                .padding(.trailing, max(safeInsets.trailing, 0) + 20)
                .padding(.bottom, 0)
                .offset(y: showingSearch ? 200 : 0)
            }
            .ignoresSafeArea(.keyboard)

            // Profile overlay with slide-in transition from right
            if showingProfile {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingProfile = false
                        }
                    }

                NavigationStack {
                    TabBarProfileView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingProfile = false
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(MinimalDesign.Colors.primary)
                                }
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.move(edge: .trailing))
                .zIndex(100)
            }

            // Create Post overlay
            if showingCreatePost {
                CreatePostView(
                    isPresented: $showingCreatePost,
                    mapManager: mapManager,
                    initialLocation: tappedLocation
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: showingCreatePost)
            }

            // Search overlay
            if showingSearch {
                SearchPopupView(
                    isPresented: $showingSearch,
                    selectedUserIdForProfile: $selectedUserIdForProfile
                )
                    .transition(.move(edge: .bottom))
                    .zIndex(101)
            }
        }
        .fullScreenCover(isPresented: $showingUserProfile) {
            if let userId = selectedUserIdForProfile {
                UserProfileView(
                    userName: "User",
                    userId: userId,
                    isPresented: $showingUserProfile
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingProfile)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingSearch)
        .fullScreenCover(isPresented: $showingAuth) {
            SignInView()
        }
        .onChange(of: selectedUserIdForProfile) { _, newValue in
            if newValue != nil {
                showingUserProfile = true
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                // Dismiss any existing sheets before presenting auth to avoid
                // "Currently, only presenting a single sheet is supported" warnings
                self.showingCreatePost = false
                self.showingProfile = false
                // Present auth slightly delayed to let dismissals complete
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    showingAuth = true
                }
            } else {
                // Ensure auth sheet is closed once signed in
                self.showingAuth = false
            }
        }
        .onAppear {
            // 位置情報サービスを開始
            locationManager.startLocationServices()

            #if DEBUG
            // 開発環境でのログインスキップ（デバッグビルドのみ）
            authManager.enableDevelopmentAuth()
            // 開発環境では認証画面を表示しない
            #else
            // アプリ起動時に認証状態をチェック - 次のレンダリングサイクルで実行
            Task { @MainActor in
                if !authManager.isAuthenticated {
                    showingAuth = true
                } else {
                    // 認証済みの場合は投稿を読み込み
                    await mapManager.fetchInitialPostsIfNeeded()
                }
            }
            #endif

            // 開発環境でも投稿を読み込み
            #if DEBUG
            Task { @MainActor in
                await mapManager.fetchInitialPostsIfNeeded()
            }
            #endif
        }
        .onChange(of: locationManager.location) { _, newLocation in
            // 現在位置が取得できたら初回のみ地図の中心を設定
            if !hasSetInitialLocation, let location = newLocation?.coordinate {
                mapManager.setInitialRegionToCurrentLocation(location)
                hasSetInitialLocation = true
                SecureLogger.shared.info("Initial location set to user's current location")
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, authed in
            if authed {
                Task { @MainActor in
                    await mapManager.fetchInitialPostsIfNeeded()
                }
            }
        }
        .onDisappear {
            // NotificationCenter observersをクリーンアップ
            for observer in notificationObservers {
                NotificationCenter.default.removeObserver(observer)
            }
            notificationObservers.removeAll()
        }
        }
    }

// MARK: - Security Methods

extension MainTabView {
    // TEMPORARILY DISABLED FOR CRASH DEBUGGING
    //###########################################################################
    // MARK: - Location Permission Check
    // Function: checkLocationPermission
    // Overview: Verify and request location access permissions
    // Processing: Check CLAuthorizationStatus and request if needed
    //###########################################################################
    private func checkLocationPermission() {
        let locationManager = CLLocationManager()
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
    
    //###########################################################################
    // MARK: - App Version Security
    // Function: checkAppVersionSecurity
    // Overview: Verify app version integrity and detect tampering
    // Processing: Check bundle version, build number, and signature
    //###########################################################################
    private func checkAppVersionSecurity() {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            SecureLogger.shared.securityEvent("Unable to determine app version")
            return
        }
        
        // 最小要求バージョンチェック（実際の実装では外部設定から取得）
        let minimumVersion = "1.0.0" // 実際の実装では外部から取得
        
        if !isVersionSupported(current: currentVersion, minimum: minimumVersion) {
            authManager.reportSecurityEvent(
                "outdated_app_version",
                severity: .high,
                details: [
                    "current_version": currentVersion,
                    "minimum_version": minimumVersion
                ]
            )
        }
    }
    
    /// バージョン比較
    private func isVersionSupported(current: String, minimum: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let minimumComponents = minimum.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(currentComponents.count, minimumComponents.count) {
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            let minimumValue = i < minimumComponents.count ? minimumComponents[i] : 0
            
            if currentValue > minimumValue {
                return true
            } else if currentValue < minimumValue {
                return false
            }
        }
        
        return true // 同じバージョン
    }
}






#Preview {
    MainTabView()
}
