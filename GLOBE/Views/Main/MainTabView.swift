import SwiftUI
import UIKit
import MapKit
import CoreLocation
import Combine

struct MainTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var postManager = PostManager.shared
    @StateObject private var mapManager = MapManager()
    @StateObject private var locationManager = MapLocationService()
    @StateObject private var appSettings = AppSettings.shared
    @State private var showingCreatePost = false
    @State private var stories: [Story] = Story.mockStories
    @State private var showingAuth = false
    @State private var showingProfile = false
    @State private var shouldMoveToCurrentLocation = false

    
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
                    .environmentObject(appSettings)
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
                        .offset(y: 50) // 位置マーカーが画面下部に来るので、投稿カードを画面下部寄りに配置
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
                // Dismiss any existing sheets before presenting auth to avoid
                // "Currently, only presenting a single sheet is supported" warnings
                showingCreatePost = false
                showingProfile = false
                // Present auth slightly delayed to let dismissals complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showingAuth = true
                }
            } else {
                // Ensure auth sheet is closed once signed in
                showingAuth = false
            }
        }
        .onAppear {
            // 通知の監視を開始
            NotificationCenter.default.addObserver(
                forName: Notification.Name("PostAtCurrentLocation"),
                object: nil,
                queue: .main
            ) { _ in
                // 現在地に移動してから投稿画面を開く
                Task {
                    await moveToCurrentLocationAndPost()
                }
            }
            
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
                    // 最初の投稿取得はUI表示後に遅延して実行（起動体感を軽く）
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    await mapManager.fetchInitialPostsIfNeeded()
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, authed in
            if authed {
                Task { await mapManager.fetchInitialPostsIfNeeded() }
            }
        }
        .task {
            // 定期的なセキュリティチェック（バックグラウンドで実行）
            await performPeriodicSecurityChecks()
        }
    }
    
    // MARK: - Post at Current Location
    private func moveToCurrentLocationAndPost() async {
        // 位置情報許可を確認
        let locationManager = CLLocationManager()
        let status = locationManager.authorizationStatus
        
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            // 位置情報が許可されていない場合は許可をリクエスト
            if status == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
            return
        }
        
        // 現在地を取得
        if let currentLocation = locationManager.location?.coordinate {
            // メインスレッドで地図を現在地に移動
            await MainActor.run {
                // 地図を現在地にフォーカス
                mapManager.focusOnLocation(currentLocation)
                
                // 少し待ってから投稿画面を開く
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingCreatePost = true
                }
            }
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






#Preview {
    MainTabView()
}
