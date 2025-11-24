import SwiftUI
import os.log
import Supabase

@main
struct GlobeApp: App {
    // MARK: - Environment Objects (Shared Singletons)
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var postManager = PostManager.shared
    @StateObject private var postService = PostService.shared
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var likeService = LikeService.shared
    @StateObject private var commentService = CommentService.shared
    @StateObject private var followManager = FollowManager.shared

    init() {
        // ConsoleLoggerを初期化（本番は静かに）
        let consoleLogger = ConsoleLogger.shared

        // Supabase設定を初期化
        initializeSupabaseConfig()
        
        #if DEBUG
        consoleLogger.forceLog("=== GLOBE APP INITIALIZATION STARTED ===")
        consoleLogger.forceLog("App Info: Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"), Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")")
        consoleLogger.forceLog("Device: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)")
        // 軽量なテストログのみ（重い生成はしない）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            consoleLogger.forceLog("Initialization heartbeat")
        }
        consoleLogger.forceLog("=== GLOBE APP INITIALIZATION COMPLETED ===")
        #endif
        
        // Preload profile images in background
        Task {
            await ProfileImageCacheManager.shared.preloadCurrentUserProfileImage()
        }
    }
    
    private func initializeSupabaseConfig() {
        // Supabase設定をKeychainに保存（起動時に一度だけ実行）
        let service = Bundle.main.bundleIdentifier ?? "com.globe.app"

        // Keychainに既に保存されているかチェック
        let checkQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "supabase_anon_key",
            kSecAttrService as String: service,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(checkQuery as CFDictionary, &result)

        // 既に存在する場合はスキップ
        if status == errSecSuccess {
            SecureLogger.shared.info("Supabase credentials already in Keychain")
            return
        }

        // 認証情報を取得（Info.plist → Secrets.plist の順）
        var supabaseURL: String?
        var supabaseAnonKey: String?

        // Info.plistから試行
        if let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
           let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
           !url.hasPrefix("YOUR_SUPABASE_"),
           !key.hasPrefix("YOUR_SUPABASE_") {
            supabaseURL = url
            supabaseAnonKey = key
        }

        // Secrets.plistから試行（複数の場所を確認）
        if supabaseURL == nil {
            // プロジェクトルートのSecrets.plistを試行
            let projectRoot = URL(fileURLWithPath: #file)
                .deletingLastPathComponent() // App
                .deletingLastPathComponent() // GLOBE
                .deletingLastPathComponent() // プロジェクトルート
            let secretsPath = projectRoot.appendingPathComponent("Secrets.plist")

            if let secretsData = try? Data(contentsOf: secretsPath),
               let secrets = try? PropertyListSerialization.propertyList(from: secretsData, format: nil) as? [String: Any] {
                if let url = secrets["SUPABASE_URL"] as? String,
                   let key = secrets["SUPABASE_ANON_KEY"] as? String {
                    supabaseURL = url
                    supabaseAnonKey = key
                    SecureLogger.shared.info("Loaded config from Secrets.plist at project root")
                }
            }

            // バンドル内のSecrets.plistも試行
            if supabaseURL == nil,
               let secretsURL = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
               let secretsData = try? Data(contentsOf: secretsURL),
               let secrets = try? PropertyListSerialization.propertyList(from: secretsData, format: nil) as? [String: Any] {
                if let url = secrets["SUPABASE_URL"] as? String,
                   let key = secrets["SUPABASE_ANON_KEY"] as? String {
                    supabaseURL = url
                    supabaseAnonKey = key
                    SecureLogger.shared.info("Loaded config from Secrets.plist in bundle")
                }
            }
        }

        guard let url = supabaseURL, let key = supabaseAnonKey else {
            SecureLogger.shared.error("Supabase configuration not found in any location")
            return
        }

        // URLをKeychainに保存
        let urlData = url.data(using: .utf8)!
        let urlQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "supabase_url",
            kSecAttrService as String: service,
            kSecValueData as String: urlData
        ]
        SecItemDelete(urlQuery as CFDictionary)
        let urlStatus = SecItemAdd(urlQuery as CFDictionary, nil)

        if urlStatus == errSecSuccess {
            SecureLogger.shared.info("Supabase URL saved to Keychain")
        } else {
            SecureLogger.shared.error("Failed to save Supabase URL: \(urlStatus)")
        }

        // Anon KeyをKeychainに保存
        let keyData = key.data(using: .utf8)!
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "supabase_anon_key",
            kSecAttrService as String: service,
            kSecValueData as String: keyData
        ]
        SecItemDelete(keyQuery as CFDictionary)
        let keyStatus = SecItemAdd(keyQuery as CFDictionary, nil)

        if keyStatus == errSecSuccess {
            SecureLogger.shared.info("Supabase Anon Key saved to Keychain")
        } else {
            SecureLogger.shared.error("Failed to save Supabase Anon Key: \(keyStatus)")
        }
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(postManager)
                .environmentObject(postService)
                .environmentObject(appSettings)
                .environmentObject(likeService)
                .environmentObject(commentService)
                .environmentObject(followManager)
                .onOpenURL { url in
                    SecureLogger.shared.info("Received Deep Link URL: \(url.absoluteString)")
                    Task {
                        do {
                            // Supabaseの認証URLを処理
                            try await supabase.auth.session(from: url)
                            SecureLogger.shared.info("Successfully handled auth URL")

                            // セッション確立後、AuthManagerを更新
                            _ = try await authManager.validateSession()
                        } catch {
                            SecureLogger.shared.error("Failed to handle auth URL: \(error.localizedDescription)")
                        }
                    }
                }
        }
    }
}
