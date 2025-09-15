import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    private var _client: SupabaseClient?

    private init() {}

    var client: SupabaseClient {
        get async {
            if let existingClient = _client {
                return existingClient
            }

            let url = SecureConfig.shared.supabaseURLSync()
            let key = SecureConfig.shared.supabaseAnonKey

            guard let supabaseURL = URL(string: url) else {
                fatalError("Invalid Supabase URL: \(url)")
            }

            print("🔗 Connecting to Supabase: \(url)")
            let newClient = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
            _client = newClient
            return newClient
        }
    }

    // Synchronous accessor for contexts that cannot await (e.g., DI factories)
    // Creates or returns cached client using synchronous SecureConfig accessors.
    var syncClient: SupabaseClient {
        if let existing = _client { return existing }
        let urlString = SecureConfig.shared.supabaseURLSync()
        guard let url = URL(string: urlString) else {
            fatalError("Invalid Supabase URL: \(urlString)")
        }
        let key = SecureConfig.shared.supabaseAnonKey
        let client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        _client = client
        print("🔗 Connecting to Supabase (sync): \(urlString)")
        return client
    }
}

// Convenience accessor for backward compatibility
var supabase: SupabaseClient {
    get async {
        await SupabaseManager.shared.client
    }
}

// Synchronous convenience accessor
var supabaseSync: SupabaseClient { SupabaseManager.shared.syncClient }
