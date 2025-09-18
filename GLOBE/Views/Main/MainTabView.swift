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
    @State private var notificationObservers: [NSObjectProtocol] = []
    @State private var shouldShowPostAfterDelay = false
    @State private var tappedLocation: CLLocationCoordinate2D?
    @State private var vTipPoint: CGPoint?


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
                    vTipPoint: $vTipPoint
                )
                    .environmentObject(appSettings)
                    .ignoresSafeArea(.all)

                LiquidGlassBottomTabBar(
                    onProfileTapped: {
                        if authManager.isAuthenticated {
                            showingProfile = true
                        } else {
                            showingAuth = true
                        }
                    },
                    onPostTapped: {
                        print("➕ LiquidGlassBottomTabBar: post tapped")
                        if authManager.isAuthenticated {
                            tappedLocation = mapManager.region.center
                            showingCreatePost = true
                        } else {
                            showingAuth = true
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: .trailing, vertical: .bottom))
                .padding(.trailing, max(safeInsets.trailing, 0) + 16)
                .padding(.bottom, 60)
            }
            .ignoresSafeArea(.keyboard)
        }
        .overlay(
            Group {
                if showingCreatePost {
                    PostPopupView(
                        isPresented: $showingCreatePost,
                        mapManager: mapManager,
                        initialLocation: tappedLocation
                    )
                    // 既存のカード位置を維持（下寄せ 50px）
                    .offset(y: 50)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showingCreatePost)
                    .allowsHitTesting(true) // ポップアップ自体のみタッチを受け付ける
                }
            }
            // 吹き出しVのスクリーン座標を受け取ってMapへ渡す
            .onPreferenceChange(VTipPreferenceKey.self) { point in
                self.vTipPoint = point
            }
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

            // アプリ起動時に認証状態をチェック - 次のレンダリングサイクルで実行
            Task { @MainActor in
                if !authManager.isAuthenticated {
                    showingAuth = true
                } else {
                    // 認証済みの場合は投稿を読み込み
                    await mapManager.fetchInitialPostsIfNeeded()
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, authed in
            if authed {
                Task { @MainActor in
                    await mapManager.fetchInitialPostsIfNeeded()
                }
            }
        }
        // TEMPORARILY DISABLED ALL ASYNC TASKS FOR CRASH DEBUGGING
        // .task {
        //     // 定期的なセキュリティチェック（バックグラウンドで実行）
        //     await performPeriodicSecurityChecks()
        // }
        // .task {
        //     // 認証済みユーザーのセッション検証
        //     guard authManager.isAuthenticated else { return }
        //
        //     do {
        //         let isValidSession = (try? await authManager.validateSession()) ?? false
        //         if !isValidSession {
        //             await MainActor.run {
        //                 showingAuth = true
        //             }
        //             return
        //         }
        //         // 最初の投稿取得はUI表示後に遅延して実行（起動体感を軽く）
        //         try await Task.sleep(nanoseconds: 200_000_000)
        //         await mapManager.fetchInitialPostsIfNeeded()
        //     } catch {
        //         SecureLogger.shared.error("Failed to initialize user session: \(error)")
        //     }
        // }
        // .task {
        //     // Watch for delayed post creation trigger
        //     while !Task.isCancelled {
        //         if shouldShowPostAfterDelay {
        //             try? await Task.sleep(nanoseconds: 500_000_000)
        //             if !Task.isCancelled {
        //                 showingCreatePost = true
        //                 shouldShowPostAfterDelay = false
        //             }
        //         }
        //         try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1 seconds
        //     }
        // }
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
    // // MARK: - Post at Current Location
    // @MainActor
    // private func moveToCurrentLocationAndPost() {
    //     let locationManager = CLLocationManager()
    //     let status = locationManager.authorizationStatus
    //
    //     guard status == .authorizedWhenInUse || status == .authorizedAlways else {
    //         if status == .notDetermined {
    //             locationManager.requestWhenInUseAuthorization()
    //         }
    //         return
    //     }
    //
    //     if let currentLocation = locationManager.location?.coordinate {
    //         mapManager.focusOnLocation(currentLocation)
    //
    //         // Trigger delayed post creation via state change
    //         shouldShowPostAfterDelay = true
    //     }
    // }

    // MARK: - Location Permission Check
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
    
    // TEMPORARILY DISABLED FOR CRASH DEBUGGING
    // /// アプリ起動時のセキュリティチェック
    // private func performSecurityChecks() {
    //     SecureLogger.shared.info("Performing app startup security checks")
    //
    //     // デバイスセキュリティチェック
    //     let deviceInfo = authManager.getDeviceSecurityInfo()
    //     let deviceInfoStrings: [String: String] = deviceInfo.reduce(into: [:]) { dict, pair in
    //         dict[pair.key] = String(describing: pair.value)
    //     }
    //
    //     // Jailbreak検出
    //     if (deviceInfo["is_jailbroken"] as? Bool) == true {
    //         authManager.reportSecurityEvent(
    //             "jailbreak_detected",
    //             severity: .critical,
    //             details: deviceInfoStrings
    //         )
    //     }
    //
    //     // シミュレータ検出（本番では警告）
    //     #if !DEBUG
    //     if (deviceInfo["is_simulator"] as? Bool) == true {
    //         authManager.reportSecurityEvent(
    //             "simulator_detected_in_production",
    //             severity: .high,
    //             details: deviceInfoStrings
    //         )
    //     }
    //     #endif
    //
    //     // アプリバージョンチェック
    //     checkAppVersionSecurity()
    //
    //     SecureLogger.shared.info("App startup security checks completed")
    // }
    
    // TEMPORARILY DISABLED FOR CRASH DEBUGGING
    // /// 定期的なセキュリティチェック
    // private func performPeriodicSecurityChecks() async {
    //     while !Task.isCancelled {
    //         // 5分ごとにセキュリティチェックを実行
    //         do {
    //             try await Task.sleep(nanoseconds: 300_000_000_000) // 5分
    //         } catch {
    //             // Task was cancelled, exit gracefully
    //             break
    //         }
    //
    //         guard authManager.isAuthenticated && !Task.isCancelled else { continue }
    //
    //         SecureLogger.shared.debug("Performing periodic security checks")
    //
    //         // Task cancellation check
    //         guard !Task.isCancelled else { break }
    //
    //         // セッション妥当性チェック
    //         let isValidSession = (try? await authManager.validateSession()) ?? false
    //         if !isValidSession {
    //             SecureLogger.shared.securityEvent("Periodic session validation failed")
    //             await MainActor.run {
    //                 showingAuth = true
    //             }
    //             break
    //         }
    //
    //         // Task cancellation check
    //         guard !Task.isCancelled else { break }
    //
    //         // デバイス状態チェック
    //         let currentDeviceInfo = authManager.getDeviceSecurityInfo()
    //         let currentDeviceInfoStrings: [String: String] = currentDeviceInfo.reduce(into: [:]) { dict, pair in
    //             dict[pair.key] = String(describing: pair.value)
    //         }
    //         if (currentDeviceInfo["is_jailbroken"] as? Bool) == true {
    //             authManager.reportSecurityEvent(
    //                 "runtime_jailbreak_detected",
    //                 severity: .critical,
    //                 details: currentDeviceInfoStrings
    //             )
    //             break
    //         }
    //     }
    // }
    
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
