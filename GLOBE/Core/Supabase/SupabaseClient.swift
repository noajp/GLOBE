import Foundation
import Supabase

// Fallback to existing Config if SecureConfig fails
private func getSupabaseConfig() -> (url: String, key: String) {
    #if DEBUG
    // For development, try existing Config first for stability
    print("🔧 Loading Supabase config for development...")
    
    // Try existing Config system first
    let url = Config.supabaseURL
    let key = Config.supabaseAnonKey
    print("✅ Using existing Config system")
    return (url, key)
    
    // Note: If Config fails with fatalError, we can't catch it
    // SecureConfig as backup would need to be implemented differently
    #else
    return (SecureConfig.shared.supabaseURL, SecureConfig.shared.supabaseAnonKey)
    #endif
}

let supabase: SupabaseClient = {
    let config = getSupabaseConfig()
    guard let url = URL(string: config.url) else {
        fatalError("Invalid Supabase URL: \(config.url)")
    }
    
    print("🔗 Connecting to Supabase: \(config.url)")
    return SupabaseClient(supabaseURL: url, supabaseKey: config.key)
}()