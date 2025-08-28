import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MainTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var postManager = PostManager.shared
    @StateObject private var mapManager = MapManager()
    @State private var showingCreatePost = false
    @State private var stories: [Story] = Story.mockStories
    @State private var showingAuth = false
    @State private var showingProfile = false

    
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    
    var body: some View {
        ZStack {
            // Main content with header
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    // App title bar
                    HStack {
                        Text("GLOBE")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Profile button
                        Button(action: {
                            if authManager.isAuthenticated {
                                showingProfile = true
                            } else {
                                showingAuth = true
                            }
                        }) {
                            Image(systemName: authManager.isAuthenticated ? "person.circle.fill" : "person.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(customBlack)
                }
                .background(customBlack)
                
                // Main content area - always show map
                MapContentView(mapManager: mapManager, showCenterPin: showingCreatePost)
                    .ignoresSafeArea(edges: .bottom)
            }
            .background(Color.clear)
            
            // Floating post button (bottom right)
            if authManager.isAuthenticated {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingCreatePost = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(customBlack)
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .overlay(
            Group {
                if showingCreatePost {
                    PostPopupView(isPresented: $showingCreatePost, mapManager: mapManager)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: showingCreatePost)
                        .allowsHitTesting(true) // ポップアップ自体のみタッチを受け付ける
                }
            }
            .allowsHitTesting(showingCreatePost) // ポップアップが表示されている時のみHitTestingを有効にする
        )
        .fullScreenCover(isPresented: $showingAuth) {
            AuthenticationView()
        }
        .fullScreenCover(isPresented: $showingProfile) {
            MyPageView()
        }

        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in

            if !isAuthenticated {
                showingAuth = true
            }
        }
        .onAppear {

            
            // セキュリティ初期化
            performSecurityChecks()
            
            // アプリ起動時に認証状態をチェック
            if !authManager.isAuthenticated {

                showingAuth = true
            } else {

                
                // 認証済みユーザーのセッション検証
                Task {
                    let isValidSession = await authManager.validateSession()
                    if !isValidSession {

                        showingAuth = true
                    }
                }
            }
        }
        .task {
            // 定期的なセキュリティチェック（バックグラウンドで実行）
            await performPeriodicSecurityChecks()
        }
    }
    
    // MARK: - Location Permission Check
    private func checkLocationPermission() {
        let locationManager = CLLocationManager()
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // まだ許可を求めていない場合は直接システムダイアログを表示
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // 拒否されている場合は設定アプリへの誘導を検討（ここではログのみ）
            break

        case .authorizedWhenInUse, .authorizedAlways:
            // 許可済みの場合は何もしない
            break
        @unknown default:
            break

        }
    }
}

// MARK: - Security Methods

extension MainTabView {
    
    /// アプリ起動時のセキュリティチェック
    private func performSecurityChecks() {
        SecureLogger.shared.info("Performing app startup security checks")
        
        // デバイスセキュリティチェック
        let deviceInfo = authManager.getDeviceSecurityInfo()
        
        // Jailbreak検出
        if deviceInfo["is_jailbroken"] == "true" {
            authManager.reportSecurityEvent(
                "jailbreak_detected",
                severity: .critical,
                details: deviceInfo
            )
        }
        
        // シミュレータ検出（本番では警告）
        #if !DEBUG
        if deviceInfo["is_simulator"] == "true" {
            authManager.reportSecurityEvent(
                "simulator_detected_in_production",
                severity: .high,
                details: deviceInfo
            )
        }
        #endif
        
        // アプリバージョンチェック
        checkAppVersionSecurity()
        
        SecureLogger.shared.info("App startup security checks completed")
    }
    
    /// 定期的なセキュリティチェック
    private func performPeriodicSecurityChecks() async {
        while true {
            // 5分ごとにセキュリティチェックを実行
            try? await Task.sleep(nanoseconds: 300_000_000_000) // 5分
            
            guard authManager.isAuthenticated else { continue }
            
            SecureLogger.shared.debug("Performing periodic security checks")
            
            // セッション妥当性チェック
            let isValidSession = await authManager.validateSession()
            if !isValidSession {
                SecureLogger.shared.securityEvent("Periodic session validation failed")
                await MainActor.run {
                    showingAuth = true
                }
                break
            }
            
            // デバイス状態チェック
            let currentDeviceInfo = authManager.getDeviceSecurityInfo()
            if currentDeviceInfo["is_jailbroken"] == "true" {
                authManager.reportSecurityEvent(
                    "runtime_jailbreak_detected",
                    severity: .critical,
                    details: currentDeviceInfo
                )
                break
            }
        }
    }
    
    /// アプリバージョンセキュリティチェック
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

// Map content view separated for cleaner code
struct MapContentView: View {
    @ObservedObject var mapManager: MapManager
    @State private var selectedPost: Post?
    @State private var showingPostDetail = false
    @State private var mapPosition: MapCameraPosition
    @State private var currentMapSpan: Double = 1.0 // マップのスパンを追跡
    @StateObject private var locationManager = MapLocationManager()
    let showCenterPin: Bool
    
    init(mapManager: MapManager, showCenterPin: Bool = false) {
        self.mapManager = mapManager
        self.showCenterPin = showCenterPin
        self._mapPosition = State(initialValue: .region(mapManager.region))
    }
    
    // ズームレベルに応じて表示する投稿をフィルタリング
    private var filteredPosts: [Post] {
        let span = currentMapSpan
        
        return mapManager.posts.filter { post in
            // スパンが大きい（ズームアウト）ほど、いいね数の多い投稿のみ表示
            if span > 50 {
                // 地球全体～大陸レベル: いいね数15以上のみ
                return post.likeCount >= 15
            } else if span > 10 {
                // 国レベル: いいね数8以上
                return post.likeCount >= 8
            } else if span > 1 {
                // 州・県レベル: いいね数3以上
                return post.likeCount >= 3
            } else {
                // 市・詳細レベル: 全て表示
                return true
            }
        }
    }
    
    var body: some View {
        ZStack {
            Map(position: $mapPosition) {
                // User's current location - blue dot
                if let userLocation = locationManager.location {
                    Annotation("", coordinate: userLocation, anchor: .center) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 16, height: 16)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                
                // Posts
                ForEach(filteredPosts) { post in
                    Annotation(
                        "",
                        coordinate: CLLocationCoordinate2D(latitude: post.latitude, longitude: post.longitude),
                        anchor: .bottom
                    ) {
                        ScalablePostPin(
                            post: post,
                            mapSpan: currentMapSpan
                        )
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange { context in
                // Update mapManager region when map position changes
                mapManager.region = context.region
                // Track map span for scaling calculations
                currentMapSpan = max(context.region.span.latitudeDelta, context.region.span.longitudeDelta)
            }
        }
        .sheet(isPresented: $showingPostDetail) {
            if let selectedPost = selectedPost {
                DetailedPostView(post: selectedPost, isPresented: $showingPostDetail)
            }
        }
    }
}




// MARK: - MapLocationManager for Map
class MapLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        
        // Check current authorization status
        authorizationStatus = locationManager.authorizationStatus
        
        // Start updating location if authorized
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        DispatchQueue.main.async {
            self.location = newLocation.coordinate
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            } else {
                manager.stopUpdatingLocation()
                self.location = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {

    }
}

#Preview {
    MainTabView()
}