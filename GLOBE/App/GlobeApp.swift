import SwiftUI
import os.log

@main
struct GlobeApp: App {
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
        // Supabase設定をInfo.plistから読み込んでKeychainに保存
        let service = Bundle.main.bundleIdentifier ?? "com.globe.app"

        // Info.plistから読み込み
        guard let supabaseURL = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let supabaseAnonKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
              !supabaseURL.isEmpty,
              !supabaseAnonKey.isEmpty else {
            SecureLogger.shared.warning("Supabase configuration not found in Info.plist")
            return
        }

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
    }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
