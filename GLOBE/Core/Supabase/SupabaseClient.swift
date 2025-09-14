import Foundation
import Supabase

let supabase: SupabaseClient = {
    let url = SecureConfig.shared.supabaseURL
    let key = SecureConfig.shared.supabaseAnonKey
    
    guard let supabaseURL = URL(string: url) else {
        fatalError("Invalid Supabase URL: \(url)")
    }
    
    print("🔗 Connecting to Supabase: \(url)")
    return SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
}()