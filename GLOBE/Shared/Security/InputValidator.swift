//======================================================================
// MARK: - InputValidator
// Purpose: ユーザー入力の検証・サニタイズシステム
// Usage: InputValidator.sanitizeText(), InputValidator.validateEmail()
//======================================================================
import Foundation

/// 入力検証・サニタイズシステム
struct InputValidator {
    
    // MARK: - Text Sanitization
    
    /// テキストのサニタイズ（XSS・インジェクション攻撃対策）
    static func sanitizeText(_ input: String, maxLength: Int = 1000) -> String {
        var sanitized = input
        
        // 長さ制限
        if sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
        }
        
        // 危険なHTMLタグの除去
        sanitized = removeDangerousHTML(sanitized)
        
        // SQLインジェクション対策
        sanitized = escapeSQLCharacters(sanitized)
        
        // 制御文字の除去
        sanitized = removeControlCharacters(sanitized)
        
        // 前後の空白文字を除去
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// HTML特殊文字のエスケープ
    static func escapeHTML(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
            .replacingOccurrences(of: "/", with: "&#x2F;")
    }
    
    private static func removeDangerousHTML(_ input: String) -> String {
        let dangerousPatterns = [
            "<script[^>]*>.*?</script>",
            "<iframe[^>]*>.*?</iframe>",
            "<object[^>]*>.*?</object>",
            "<embed[^>]*>.*?</embed>",
            "<form[^>]*>.*?</form>",
            "javascript:",
            "vbscript:",
            "data:",
            "on\\w+\\s*="
        ]
        
        var cleaned = input
        for pattern in dangerousPatterns {
            cleaned = cleaned.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return cleaned
    }
    
    private static func escapeSQLCharacters(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "'", with: "''")
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    private static func removeControlCharacters(_ input: String) -> String {
        return input.filter { !$0.isNewline && !$0.isWhitespace || $0 == " " || $0 == "\n" }
    }
    
    // MARK: - Email Validation
    
    /// メールアドレスの検証
    static func validateEmail(_ email: String) -> ValidationResult {
        let sanitizedEmail = sanitizeText(email, maxLength: 254)
        
        // 基本的な形式チェック
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: sanitizedEmail) else {
            return .invalid("Invalid email format")
        }
        
        // 危険なパターンチェック
        let dangerousPatterns = ["javascript:", "data:", "vbscript:"]
        for pattern in dangerousPatterns {
            if sanitizedEmail.lowercased().contains(pattern) {
                return .invalid("Email contains dangerous content")
            }
        }
        
        return .valid(sanitizedEmail)
    }

    // MARK: - Username Validation
    
    /// ユーザー名の検証
    static func validateUsername(_ username: String) -> ValidationResult {
        // 長さをチェック（sanitizeする前に）
        if username.count > 20 {
            return .invalid("Username must be 3-20 characters long.")
        }

        let sanitizedUsername = sanitizeText(username, maxLength: 20)

        let usernameRegex = #"^[a-zA-Z0-9_]{3,20}$"#
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)

        guard usernamePredicate.evaluate(with: sanitizedUsername) else {
            return .invalid("Username must be 3-20 characters long and can only contain letters, numbers, and underscores.")
        }

        return .valid(sanitizedUsername)
    }
    
    // MARK: - Password Validation
    
    /// パスワードの検証
    static func validatePassword(_ password: String) -> ValidationResult {
        let passwordRegex = #"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&#]{8,}$"#
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)

        if passwordPredicate.evaluate(with: password) {
            return .valid(password)
        } else {
            return .invalid("Password must be at least 8 characters long and contain at least one letter and one number.")
        }
    }
    
    /// URL の検証
    static func validateURL(_ urlString: String) -> ValidationResult {
        let sanitized = sanitizeText(urlString, maxLength: 2048)
        
        guard let url = URL(string: sanitized) else {
            return .invalid("Invalid URL format")
        }
        
        // HTTPSのみ許可
        guard url.scheme == "https" else {
            return .invalid("Only HTTPS URLs are allowed")
        }
        
        // 危険なドメインチェック
        if isDangerousDomain(url.host) {
            return .invalid("Domain not allowed")
        }
        
        return .valid(sanitized)
    }
    
    private static func isDangerousDomain(_ host: String?) -> Bool {
        guard let host = host?.lowercased() else { return true }
        
        let blockedDomains = [
            "localhost", "127.0.0.1", "0.0.0.0", "::1",
            "bit.ly", "tinyurl.com", "t.co" // 短縮URLサービス
        ]
        
        return blockedDomains.contains(host)
    }
    
    // MARK: - Phone Number Validation
    
    /// 電話番号の検証
    static func validatePhoneNumber(_ phone: String) -> ValidationResult {
        let sanitized = phone.replacingOccurrences(of: "[^0-9+\\-\\s()]", with: "", options: .regularExpression)
        
        // 日本の電話番号形式
        let phoneRegex = "^(\\+81|0)[0-9\\-\\s]{9,13}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        if phonePredicate.evaluate(with: sanitized) {
            return .valid(sanitized)
        }
        
        return .invalid("Invalid phone number format")
    }
}

// MARK: - Result Types

enum ValidationResult {
    case valid(String)
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var value: String? {
        switch self {
        case .valid(let value): return value
        case .invalid: return nil
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let message): return message
        }
    }
}

// MARK: - Content Validation

extension InputValidator {
    
    /// 投稿コンテンツの検証
    /// 投稿コンテンツの検証（強化版）
    static func validatePostContent(_ content: String) -> ValidationResult {
        let sanitized = sanitizeText(content, maxLength: 2000)
        
        // 空の投稿チェック
        if sanitized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid("Post content cannot be empty")
        }
        
        // 最小文字数チェック（1文字以上）
        if sanitized.count < 1 {
            return .invalid("Post must contain at least one character")
        }
        
        // スパムパターンチェック（強化版）
        if containsSpamPattern(sanitized) {
            return .invalid("Content appears to be spam")
        }
        
        // 有害コンテンツチェック
        if containsHarmfulContent(sanitized) {
            return .invalid("Content contains harmful material")
        }
        
        // 個人情報漏洩チェック
        if containsPersonalInformation(sanitized) {
            return .invalid("Content may contain personal information")
        }
        
        // 外部リンクチェック
        if containsSuspiciousLinks(sanitized) {
            return .invalid("Content contains suspicious links")
        }
        
        return .valid(sanitized)
    }
    
    private static func containsSpamPattern(_ content: String) -> Bool {
        let spamPatterns = [
            // 商業スパム
            "buy now", "click here", "free money", "guaranteed",
            "limited time", "act now", "call now", "urgent",
            "無料", "今すぐ", "限定", "保証", "儲ける", "稼ぐ",
            
            // 繰り返しパターン
            "!!!!!!!", "??????", ">>>>>>>>",
            
            // URL スパム
            "http://bit.ly", "http://tinyurl", ".tk/", ".ml/",
            
            // 宣伝パターン
            "follow me", "check out", "visit my", "subscribe",
            "フォローして", "チェック", "見て", "登録"
        ]
        
        let lowercased = content.lowercased()
        
        // パターンマッチング
        for pattern in spamPatterns {
            if lowercased.contains(pattern) {
                return true
            }
        }
        
        // 大文字の過度な使用をチェック
        let uppercaseCount = content.filter { $0.isUppercase }.count
        if uppercaseCount > content.count / 2 && content.count > 10 {
            return true
        }
        
        // 同じ文字の繰り返しチェックを無効化（ユーザーリクエストにより）
        // if hasExcessiveRepeatingCharacters(content) {
        //     return true
        // }
        
        return false
    }

    // MARK: - Enhanced Security Validation
    
    /// 有害コンテンツのチェック
    private static func containsHarmfulContent(_ content: String) -> Bool {
        let harmfulPatterns = [
            // 暴力的表現
            "kill", "murder", "violence", "attack", "bomb",
            "殺す", "殺害", "暴力", "攻撃", "爆弾", "テロ",
            
            // ヘイトスピーチ
            "hate", "racism", "discrimination",
            "差別", "憎悪", "ヘイト",
            
            // 自傷・自殺関連
            "suicide", "self-harm", "cutting",
            "自殺", "自傷", "リストカット",
            
            // 薬物・違法行為
            "drugs", "illegal", "cocaine", "heroin",
            "薬物", "違法", "コカイン", "ヘロイン", "覚醒剤"
        ]
        
        let lowercased = content.lowercased()
        return harmfulPatterns.contains { lowercased.contains($0) }
    }
    
    /// 個人情報の漏洩チェック
    private static func containsPersonalInformation(_ content: String) -> Bool {
        // クレジットカード番号パターン
        let creditCardPattern = #"\b[0-9]{4}[\s-]?[0-9]{4}[\s-]?[0-9]{4}[\s-]?[0-9]{4}\b"#
        if content.range(of: creditCardPattern, options: .regularExpression) != nil {
            return true
        }
        
        // 電話番号パターン（日本）
        let phonePattern = #"\b0[0-9]{1,3}-[0-9]{4}-[0-9]{4}\b"#
        if content.range(of: phonePattern, options: .regularExpression) != nil {
            return true
        }
        
        // メールアドレスパターン
        let emailPattern = #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"#
        if content.range(of: emailPattern, options: .regularExpression) != nil {
            return true
        }
        
        // 住所の可能性が高いパターン
        let addressPatterns = [
            "東京都", "大阪府", "愛知県", "神奈川県", "北海道",
            "番地", "丁目", "区", "市", "町", "村"
        ]
        
        let foundAddressTerms = addressPatterns.filter { content.contains($0) }.count
        if foundAddressTerms >= 2 {
            return true
        }
        
        return false
    }
    
    /// 疑わしいリンクのチェック
    private static func containsSuspiciousLinks(_ content: String) -> Bool {
        // 短縮URLサービス
        let suspiciousURLPatterns = [
            "bit.ly", "tinyurl.com", "t.co", "goo.gl",
            "ow.ly", "is.gd", "buff.ly", "adf.ly"
        ]
        
        let lowercased = content.lowercased()
        for pattern in suspiciousURLPatterns {
            if lowercased.contains(pattern) {
                return true
            }
        }
        
        // HTTPSではないURLをチェック
        let httpPattern = #"http://[^\s]+"#
        if content.range(of: httpPattern, options: .regularExpression) != nil {
            return true
        }
        
        // 疑わしいTLD
        let suspiciousTLDs = [".tk", ".ml", ".ga", ".cf"]
        for tld in suspiciousTLDs {
            if lowercased.contains(tld) {
                return true
            }
        }
        
        return false
    }
    
    /// 過度な文字の繰り返しをチェック
    private static func hasExcessiveRepeatingCharacters(_ content: String) -> Bool {
        var currentChar: Character?
        var repeatCount = 0
        var maxRepeats = 0
        
        for char in content {
            if char == currentChar {
                repeatCount += 1
            } else {
                maxRepeats = max(maxRepeats, repeatCount)
                currentChar = char
                repeatCount = 1
            }
        }
        
        maxRepeats = max(maxRepeats, repeatCount)
        
        // 日本語の母音延長や感情表現は正当な表現なのでより寛容に
        // ひらがな・カタカナの母音、促音、長音符は最大15回まで許可
        if let currentChar = currentChar {
            let japaneseEmotionalChars: Set<Character> = ["あ", "い", "う", "え", "お", "ー", "ア", "イ", "ウ", "エ", "オ", "っ", "ッ", "ょ", "ゅ", "ゃ", "ョ", "ュ", "ャ"]
            if japaneseEmotionalChars.contains(currentChar) {
                return maxRepeats > 15 // 日本語感情表現文字は15回まで許可
            }
        }
        
        // その他の文字は5回以上で疑わしいとする
        return maxRepeats > 5
    }
    
    /// 位置情報の安全性チェック
    static func validateLocationSafety(latitude: Double, longitude: Double) -> ValidationResult {
        // 座標の妥当性チェック
        if latitude < -90 || latitude > 90 {
            return .invalid("Invalid latitude value")
        }
        
        if longitude < -180 || longitude > 180 {
            return .invalid("Invalid longitude value")
        }
        
        // 危険地域チェック（例：軍事施設、政府施設など）
        if isDangerousLocation(latitude: latitude, longitude: longitude) {
            return .invalid("Location posting not allowed in this area")
        }
        
        return .valid("\(latitude),\(longitude)")
    }
    
    /// 危険地域判定（基本的な実装例）
    private static func isDangerousLocation(latitude: Double, longitude: Double) -> Bool {
        // 基本的な実装例：政府機関や軍事施設の周辺エリア
        // 実際の実装では、より詳細な地理的データベースを使用
        
        // 皇居周辺（例）
        let imperialPalaceLat = 35.685175
        let imperialPalaceLon = 139.752799
        let distance = calculateDistance(lat1: latitude, lon1: longitude, 
                                       lat2: imperialPalaceLat, lon2: imperialPalaceLon)
        
        if distance < 0.5 { // 500m以内
            return true
        }
        
        // 他の制限区域もここに追加
        
        return false
    }
    
    /// 2点間の距離を計算（km）
    private static func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0 // 地球の半径（km）
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
}