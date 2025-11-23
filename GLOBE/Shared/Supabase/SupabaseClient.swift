import Foundation
import Supabase

class SupabaseManager {
    private let logger = SecureLogger.shared
    static let shared = SupabaseManager()

    private var _client: SupabaseClient?

    private init() {}

    var client: SupabaseClient {
        get async {
            if let existingClient = _client {
                return existingClient
            }

            await MainActor.run {
                let url = SecureConfig.shared.supabaseURLSync()
                let key = SecureConfig.shared.supabaseAnonKey

                guard let supabaseURL = URL(string: url) else {
                    logger.error("Invalid Supabase URL configuration")
                    fatalError("Invalid Supabase URL configuration")
                }

                let newClient = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
                _client = newClient
            }

            return _client!
        }
    }

    // Synchronous accessor for contexts that cannot await (e.g., DI factories)
    // WARNING: This should only be called from MainActor context
    @MainActor
    var syncClient: SupabaseClient {
        if let existing = _client { return existing }
        let urlString = SecureConfig.shared.supabaseURLSync()
        guard let url = URL(string: urlString) else {
            logger.error("Invalid Supabase URL configuration (sync)")
            fatalError("Invalid Supabase URL configuration")
        }
        let key = SecureConfig.shared.supabaseAnonKey
        let client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        _client = client
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
@MainActor
var supabaseSync: SupabaseClient { SupabaseManager.shared.syncClient }
