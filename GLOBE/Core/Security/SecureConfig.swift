//======================================================================
// MARK: - SecureConfig.swift
// Purpose: Secure configuration management using Keychain and environment variables (Keychainと環境変数を使用したセキュアな設定管理)
// Path: GLOBE/Core/Security/SecureConfig.swift
//======================================================================

import Foundation
import Security

struct SecureConfig {
    static let shared = SecureConfig()
    
    private init() {}
    
    // MARK: - Keychain Keys
    private enum KeychainKey: String {
        case supabaseURL = "supabase_url"
        case supabaseAnonKey = "supabase_anon_key"
    }
    
    // MARK: - Configuration Properties
    var supabaseURL: String {
        // Try to get from Keychain first
        if let keychainURL = getFromKeychain(key: .supabaseURL) {
            return keychainURL
        }
        
        // Fallback to Info.plist
        if let url = Bundle.main.infoDictionary?["SupabaseURL"] as? String {
            return url
        }
        
        // Emergency fallback - should not happen in production
        SecureLogger.shared.error("No Supabase URL found in Keychain or Info.plist")
        return ""
    }
    
    var supabaseAnonKey: String {
        // Try to get from Keychain first
        if let keychainKey = getFromKeychain(key: .supabaseAnonKey) {
            return keychainKey
        }
        
        // Fallback to Info.plist
        if let key = Bundle.main.infoDictionary?["SupabaseAnonKey"] as? String {
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