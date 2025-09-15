//======================================================================
// MARK: - SecureConfig.swift
// Purpose: Secure configuration management using Keychain and environment variables (Keychainと環境変数を使用したセキュアな設定管理)
// Path: GLOBE/Core/Security/SecureConfig.swift
//======================================================================

import Foundation
import Security

@MainActor
struct SecureConfig {
    static let shared = SecureConfig()

    private init() {
        // Initialize secure keychain integration
        // Note: Async initialization will be handled on first access
    }

    private static var didAttemptSecretsImport = false
    private static var isInitialized = false

    // MARK: - Secure Storage Integration
    private let secureKeychain = SecureKeychain.shared
    
    // MARK: - Keychain Keys
    private enum KeychainKey: String, CaseIterable {
        case supabaseURL = "supabase_url"
        case supabaseAnonKey = "supabase_anon_key"
    }
    
    // MARK: - Secure Configuration Access
    private static func ensureInitialization() async {
        guard !isInitialized else { return }
        await shared.initializeSecureStorage()
        isInitialized = true
    }

    private func initializeSecureStorage() async {
        // Migrate existing keychain items to encrypted storage if needed
        await migrateToSecureStorage()

        // Perform security validation
        if !secureKeychain.isDeviceSecure() {
            SecureLogger.shared.error("Device is not secure - passcode not set")
        }

        if secureKeychain.isBiometryAvailable() {
            SecureLogger.shared.info("Biometry available for additional security")
        }
    }

    private func migrateToSecureStorage() async {
        // Check if migration is needed
        for key in KeychainKey.allCases {
            if let legacyValue = getFromKeychain(key: key) {
                do {
                    // Store in secure encrypted keychain
                    try await secureKeychain.store(
                        legacyValue,
                        for: key.rawValue,
                        accessControl: .afterFirstUnlockThisDeviceOnly
                    )

                    // Remove legacy item
                    let query: [String: Any] = [
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrAccount as String: key.rawValue,
                        kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.globe.app"
                    ]
                    SecItemDelete(query as CFDictionary)

                    SecureLogger.shared.info("Migrated \(key.rawValue) to secure storage")
                } catch {
                    SecureLogger.shared.error("Failed to migrate \(key.rawValue): \(error)")
                }
            }
        }
    }

    // MARK: - Configuration Properties
    var supabaseURL: String {
        get async {
            // Ensure initialization
            await Self.ensureInitialization()

            // Try to get from secure keychain first
            do {
                if let secureURL = try await secureKeychain.retrieveString(for: KeychainKey.supabaseURL.rawValue) {
                    return secureURL
                }
            } catch {
                SecureLogger.shared.error("Failed to retrieve Supabase URL from secure storage: \(error)")
            }

            // Try legacy keychain
            if let keychainURL = getFromKeychain(key: .supabaseURL) {
                // Migrate to secure storage
                Task {
                    try? await secureKeychain.store(
                        keychainURL,
                        for: KeychainKey.supabaseURL.rawValue,
                        accessControl: .afterFirstUnlockThisDeviceOnly
                    )
                }
                return keychainURL
            }

            // Fallback to Info.plist
            if let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String, !isPlaceholder(url) {
                // Store in secure keychain for future use
                Task {
                    try? await secureKeychain.store(
                        url,
                        for: KeychainKey.supabaseURL.rawValue,
                        accessControl: .afterFirstUnlockThisDeviceOnly
                    )
                }
                return url
            }

            // Dev-only: Try Secrets.plist
            if let secrets = loadSecretsPlist(), let url = secrets["SUPABASE_URL"], !isPlaceholder(url) {
                // Cache to secure storage
                Task {
                    try? await secureKeychain.store(
                        url,
                        for: KeychainKey.supabaseURL.rawValue,
                        accessControl: .afterFirstUnlockThisDeviceOnly
                    )
                }
                return url
            }

            // Emergency fallback - should not happen in production
            SecureLogger.shared.error("No Supabase URL found in any secure location")
            return ""
        }
    }
    
    // Non-blocking, synchronous accessor used for early initialization paths
    // Falls back to Keychain -> Info.plist -> Secrets.plist without async calls
    func supabaseURLSync() -> String {
        if let keychainURL = getFromKeychain(key: .supabaseURL), !isPlaceholder(keychainURL) {
            return keychainURL
        }
        if let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String, !isPlaceholder(url) {
            return url
        }
        if let secrets = loadSecretsPlist(), let url = secrets["SUPABASE_URL"], !isPlaceholder(url) {
            return url
        }
        SecureLogger.shared.error("No Supabase URL (sync) found in secure locations")
        return ""
    }

    var supabaseAnonKey: String {
        // Try to get from Keychain first
        if let keychainKey = getFromKeychain(key: .supabaseAnonKey) {
            return keychainKey
        }
        
        // Fallback to Info.plist
        if let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String, !isPlaceholder(key) {
            return key
        }

        // Dev-only: Try Secrets.plist and cache
        if let secrets = loadSecretsPlist(), let key = secrets["SUPABASE_ANON_KEY"], !isPlaceholder(key) {
            saveToKeychain(key: .supabaseAnonKey, value: key)
            return key
        }
        
        // Emergency fallback - should not happen in production
        SecureLogger.shared.error("No Supabase Anon Key found in Keychain or Info.plist")
        return ""
    }
    
    // MARK: - Configuration Methods
    func setSupabaseConfig(url: String, anonKey: String) {
        saveToKeychain(key: .supabaseURL, value: url)
        saveToKeychain(key: .supabaseAnonKey, value: anonKey)
    }
    
    // MARK: - Keychain Operations
    private func saveToKeychain(key: KeychainKey, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.globe.app",
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            SecureLogger.shared.error("Failed to save \(key.rawValue) to Keychain: \(status)")
        }
    }
    
    private func getFromKeychain(key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.globe.app",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return nil
    }

    // MARK: - Secrets.plist (DEV ONLY)
    private func loadSecretsPlist() -> [String: String]? {
        // Run at most once to avoid repeated disk access
        if SecureConfig.didAttemptSecretsImport { return nil }
        SecureConfig.didAttemptSecretsImport = true
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        var result: [String: String] = [:]
        if let u = dict["SUPABASE_URL"] as? String { result["SUPABASE_URL"] = u }
        if let k = dict["SUPABASE_ANON_KEY"] as? String { result["SUPABASE_ANON_KEY"] = k }
        return result
    }

    private func isPlaceholder(_ value: String) -> Bool {
        return value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("YOUR_SUPABASE_") || value.isEmpty
    }
    
    // MARK: - Development Helper
    #if DEBUG
    func initializeForDevelopment() {
        // These values should be set from a secure source or environment
        // DO NOT commit actual values to Git
        
        if getFromKeychain(key: .supabaseURL) == nil {
            SecureLogger.shared.warning("Please set SUPABASE_URL in Info.plist or call setSupabaseConfig()")
        }
        
        if getFromKeychain(key: .supabaseAnonKey) == nil {
            SecureLogger.shared.warning("Please set SUPABASE_ANON_KEY in Info.plist or call setSupabaseConfig()")
        }
    }
    #endif
}
