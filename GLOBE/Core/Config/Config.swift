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
        print("🔍 Config: Loading Supabase URL...")
        
        if let url = secrets["SUPABASE_URL"] {
            print("🔍 Config: Found URL in Secrets.plist: '\(url)'")
            if !isPlaceholder(url) {
                print("🔵 Supabase URL from Secrets.plist: \(url)")
                return url
            } else {
                print("⚠️ Config: URL in Secrets.plist is placeholder")
            }
        } else {
            print("⚠️ Config: No URL found in Secrets.plist")
        }
        
        // Fallback to SecureConfig
        print("🔍 Config: Trying SecureConfig fallback...")
        let secureURL = SecureConfig.shared.supabaseURL
        print("🔍 Config: SecureConfig returned: '\(secureURL)'")
        if !secureURL.isEmpty && !isPlaceholder(secureURL) {
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