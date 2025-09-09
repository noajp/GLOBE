import Foundation
import Supabase

let supabase: SupabaseClient = {
    let url = Config.supabaseURL
    let key = Config.supabaseAnonKey
    
    guard let supabaseURL = URL(string: url) else {
        fatalError("Invalid Supabase URL: \(url)")
    }
    
    print("🔗 Connecting to Supabase: \(url)")
    return SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
}()