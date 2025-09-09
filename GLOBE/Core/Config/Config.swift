import Foundation

enum Config {
    private static let secrets: [String: String] = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("⚠️ Secrets.plist not found - using SecureConfig fallback")
            return [:]
        }
        print("✅ Secrets.plist loaded successfully")
        
        var stringDict: [String: String] = [:]
        for (key, value) in dict {
            if let stringValue = value as? String {
                stringDict[key] = stringValue
            }
        }
        return stringDict
    }()
    
    private static func isPlaceholder(_ value: String) -> Bool {
        return value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("YOUR_SUPABASE_") || value.isEmpty
    }
    
    static let supabaseURL: String = {
        if let url = secrets["SUPABASE_URL"], !isPlaceholder(url) {
            print("🔵 Supabase URL from Secrets.plist: \(url)")
            return url
        }
        
        // Fallback to SecureConfig
        let secureURL = SecureConfig.shared.supabaseURL
        if !secureURL.isEmpty {
            print("🔵 Supabase URL from SecureConfig: \(secureURL)")
            return secureURL
        }
        
        print("❌ No valid Supabase URL found")
        fatalError("No valid SUPABASE_URL found. Please configure Secrets.plist or Info.plist")
    }()
    
    static let supabaseAnonKey: String = {
        if let key = secrets["SUPABASE_ANON_KEY"], !isPlaceholder(key) {
            print("🔵 Supabase Key from Secrets.plist: \(String(key.prefix(20)))...")
            return key
        }
        
        // Fallback to SecureConfig
        let secureKey = SecureConfig.shared.supabaseAnonKey
        if !secureKey.isEmpty {
            print("🔵 Supabase Key from SecureConfig: \(String(secureKey.prefix(20)))...")
            return secureKey
        }
        
        print("❌ No valid Supabase Anon Key found")
        fatalError("No valid SUPABASE_ANON_KEY found. Please configure Secrets.plist or Info.plist")
    }()
}