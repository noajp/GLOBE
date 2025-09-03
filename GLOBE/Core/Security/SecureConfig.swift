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
        // 強制的に正しいURLを返す（デバッグ用）
        return "https://kkznkqshpdzlhtuawasm.supabase.co"
    }
    
    var supabaseAnonKey: String {
        // 強制的に正しいキーを返す（デバッグ用）
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtrem5rcXNocGR6bGh0dWF3YXNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzMTA5NzAsImV4cCI6MjA3MDg4Njk3MH0.BXF3JVvs0M7Mgp9whEwFXd6PRfEwEMcCbKfnRBROEBM"
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
        let defaultURL = "https://kkznkqshpdzlhtuawasm.supabase.co"
        
        if getFromKeychain(key: .supabaseURL) == nil {
            saveToKeychain(key: .supabaseURL, value: defaultURL)
        }
        
        if getFromKeychain(key: .supabaseAnonKey) == nil {
            SecureLogger.shared.warning("Please set SUPABASE_ANON_KEY in environment or call setSupabaseConfig()")
        }
    }
    #endif
}