import SwiftUI
import os.log

@main
struct GlobeApp: App {
    init() {
        // ConsoleLoggerを初期化（本番は静かに）
        let consoleLogger = ConsoleLogger.shared

        // Supabase設定を初期化
        initializeSupabaseConfig()

        // Keychainの古い設定をクリアして、Secrets.plistから再読み込み
        clearKeychainAndReloadConfig()
        
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
        // Supabase設定を直接Keychainに保存
        let service = Bundle.main.bundleIdentifier ?? "com.globe.app"
        let supabaseURL = "https://kkznkqshpdzlhtuawasm.supabase.co"
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtrem5rcXNocGR6bGh0dWF3YXNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzMTA5NzAsImV4cCI6MjA3MDg4Njk3MH0.BXF3JVvs0M7Mgp9whEwFXd6PRfEwEMcCbKfnRBROEBM"

        // URLをKeychainに保存
        let urlData = supabaseURL.data(using: .utf8)!
        let urlQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "supabase_url",
            kSecAttrService as String: service,
            kSecValueData as String: urlData
        ]
        SecItemDelete(urlQuery as CFDictionary)
        SecItemAdd(urlQuery as CFDictionary, nil)

        // Anon KeyをKeychainに保存
        let keyData = supabaseAnonKey.data(using: .utf8)!
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "supabase_anon_key",
            kSecAttrService as String: service,
            kSecValueData as String: keyData
        ]
        SecItemDelete(keyQuery as CFDictionary)
        SecItemAdd(keyQuery as CFDictionary, nil)

        print("✅ Supabase configuration initialized in Keychain")
    }

    private func clearKeychainAndReloadConfig() {
        // 開発環境でのみ、間違ったURLが保存されている場合にクリア
        let service = Bundle.main.bundleIdentifier ?? "com.globe.app"
        let urlKey = "supabase_url"
        
        // 現在のKeychainの値を確認
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: urlKey,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let currentURL = String(data: data, encoding: .utf8) {
            // 間違ったURLが保存されている場合のみクリア
            if currentURL.contains("lhsdzjkdhiefbhzmwxbj") {
                print("🔧 Found incorrect URL in Keychain, clearing...")
                
                // 両方のキーを削除
                let keysToDelete = ["supabase_url", "supabase_anon_key"]
                for key in keysToDelete {
                    let deleteQuery: [String: Any] = [
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrAccount as String: key,
                        kSecAttrService as String: service
                    ]
                    SecItemDelete(deleteQuery as CFDictionary)
                }
                
                // 正しい設定を読み込み（同期アクセサ）
                _ = SecureConfig.shared.supabaseURLSync()
                _ = SecureConfig.shared.supabaseAnonKey
                print("🔧 Reloaded correct Supabase configuration")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
