//======================================================================
// MARK: - AuthManager.swift
// Purpose: Authentication manager with simple logging for GLOBE
// Path: GLOBE/Core/Auth/AuthManager.swift
//======================================================================

import Foundation
import Supabase
import SwiftUI
import Combine

// MARK: - Security Severity Levels

enum SecuritySeverity {
    case low
    case medium
    case high
    case critical
}

@MainActor
class AuthManager: AuthServiceProtocol {
    static let shared = AuthManager()
    
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let logger = SecureLogger.shared
    
    /// 最大ログイン試行回数
    private let maxLoginAttempts = 5
    
    /// アカウントロック期間（15分）
    private let lockoutDuration: TimeInterval = 900
    
    /// ログイン試行回数の追跡
    private var loginAttempts: [String: (count: Int, lastAttempt: Date)] = [:]
    
    private init() {
        // 開発環境でのログインスキップチェック
        #if DEBUG
        if isDevelopmentLoginSkipEnabled() {
            enableDevelopmentAuth()
            logger.info("AuthManager initialized with development login skip")
            return
        }
        #endif

        // 初期化時は現在のセッションをチェック
        Task {
            let _ = await checkCurrentUser()
        }
        logger.info("AuthManager initialized")
    }

    // Publisher exposure for protocol requirement
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { $isAuthenticated.eraseToAnyPublisher() }
    
    // MARK: - Session Management
    
    func checkCurrentUser() async -> Bool {
        do {
            let session = try await (await supabase).auth.session
            let user = session.user

            currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                username: user.userMetadata["username"]?.stringValue,
                createdAt: user.createdAt.ISO8601Format()
            )
            isAuthenticated = true
            logger.info("Current user session found: \(user.email ?? "")")
            return true

        } catch {
            logger.info("No current user session found")
            isAuthenticated = false
            currentUser = nil
            return false
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, username: String) async throws {
        logger.info("AuthManager.signUp: begin for \(email)")
        // 入力検証
        let emailValidation = InputValidator.validateEmail(email)
        guard emailValidation.isValid, let validEmail = emailValidation.value else {
            logger.error("AuthManager.signUp: invalid email")
            throw AuthError.invalidInput("有効なメールアドレスを入力してください")
        }
        
        let passwordValidation = InputValidator.validatePassword(password)
        guard passwordValidation.isValid else {
            logger.error("AuthManager.signUp: weak password")
            throw AuthError.weakPassword(["パスワードは8文字以上で、英字と数字を含む必要があります"])
        }
        
        let usernameValidation = InputValidator.validateUsername(username)
        guard usernameValidation.isValid, let validUsername = usernameValidation.value else {
            logger.error("AuthManager.signUp: invalid username")
            throw AuthError.invalidInput("ユーザー名は3-20文字で、英字、数字、アンダースコアのみ使用できます")
        }
        
        isLoading = true
        defer { isLoading = false }
        
        logger.info("Sign up attempt for: \(validEmail)")
        SecureLogger.shared.authEvent("sign_up_attempt", userID: nil)
        
        do {
            let response = try await (await supabase).auth.signUp(
                email: validEmail,
                password: password,
                data: [
                    "username": AnyJSON.string(validUsername)
                ]
            )
            
            let user = response.user
            logger.info("Sign up successful for user: \(user.id.uuidString)")
            logger.info("AuthManager.signUp: success user=\(user.id.uuidString)")
            SecureLogger.shared.authEvent("sign_up_success", userID: user.id.uuidString)
            
            // メール認証をスキップして直接認証済み状態にする
            currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                username: validUsername,
                createdAt: user.createdAt.ISO8601Format()
            )
            isAuthenticated = true
            
            // handle_new_user関数が自動的にプロフィールを作成するため、
            // ここでは作成しない（RLSポリシー違反を避ける）
            logger.info("Profile will be created by handle_new_user trigger")
            
        } catch {
            logger.error("Sign up failed: \(error.localizedDescription)")
            let ns = error as NSError
            logger.error("AuthManager.signUp failed: \(error.localizedDescription)")
            SecureLogger.shared.authEvent("sign_up_failed_\(ns.domain)_\(ns.code)")
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        logger.info("AuthManager.signIn: begin for \(email)")
        // 入力検証
        let emailValidation = InputValidator.validateEmail(email)
        guard emailValidation.isValid, let validEmail = emailValidation.value else {
            logger.error("AuthManager.signIn: invalid email")
            throw AuthError.invalidInput("有効なメールアドレスを入力してください")
        }
        
        guard !password.isEmpty else {
            logger.error("AuthManager.signIn: empty password")
            throw AuthError.invalidInput("パスワードを入力してください")
        }
        
        // レート制限チェック
        try checkEmailRateLimit(for: validEmail)
        
        isLoading = true
        defer { isLoading = false }
        
        logger.info("Sign in attempt for: \(validEmail)")
        SecureLogger.shared.authEvent("sign_in_attempt", userID: nil)
        
        do {
            // Normalize email casing; passwords are case-sensitive and must not be trimmed/altered
            let normalizedEmail = validEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            // Use SDK's signIn(email:password:) for this version
            let response = try await (await supabase).auth.signIn(
                email: normalizedEmail,
                password: password
            )
            
            let user = response.user
            logger.info("Sign in successful for user: \(user.id.uuidString)")
            logger.info("AuthManager.signIn: success user=\(user.id.uuidString)")
            SecureLogger.shared.authEvent("sign_in_success", userID: user.id.uuidString)
            
            currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                username: user.userMetadata["username"]?.stringValue,
                createdAt: user.createdAt.ISO8601Format()
            )
            isAuthenticated = true
            
            // ログイン成功時はレート制限をリセット
            resetLoginAttempts(for: validEmail)
            
        } catch {
            logger.error("Sign in failed for \(validEmail): \(error.localizedDescription)")
            
            // Supabase特有のエラーハンドリング
            if let nsError = error as NSError? {
                logger.error("AuthManager.signIn: failed domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription)")
                let errorMessage: String
                switch nsError.code {
                case 400:
                    if nsError.localizedDescription.contains("Invalid login credentials") {
                        errorMessage = "メールアドレスまたはパスワードが正しくありません"
                    } else if nsError.localizedDescription.contains("Email not confirmed") {
                        errorMessage = "メールアドレスが確認されていません。確認メールをチェックしてください"
                    } else {
                        errorMessage = "認証に失敗しました: \(nsError.localizedDescription)"
                    }
                case 422:
                    errorMessage = "入力データが無効です。メールアドレスとパスワードを確認してください"
                case 429:
                    errorMessage = "試行回数が上限に達しました。しばらく待ってから再度お試しください"
                default:
                    errorMessage = "サインインに失敗しました: \(nsError.localizedDescription)"
                }
                
                recordFailedLoginAttempt(for: validEmail)
                SecureLogger.shared.authEvent("sign_in_failed_\(nsError.code)", userID: nil)
                throw AuthError.unknown(errorMessage)
            }
            
            recordFailedLoginAttempt(for: validEmail)
            SecureLogger.shared.authEvent("sign_in_failed_unknown", userID: nil)
            throw AuthError.unknown("サインインに失敗しました: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Password Reset
    
    func sendPasswordResetEmail(email: String) async throws {
        let emailValidation = InputValidator.validateEmail(email)
        guard emailValidation.isValid, let validEmail = emailValidation.value else {
            throw AuthError.invalidInput("有効なメールアドレスを入力してください")
        }
        
        logger.info("Password reset request for: \(validEmail)")
        
        do {
            try await (await supabase).auth.resetPasswordForEmail(validEmail)
            logger.info("Password reset email sent to: \(validEmail)")
        } catch {
            logger.error("Password reset failed: \(error.localizedDescription)")
            throw AuthError.unknown("パスワードリセットメールの送信に失敗しました")
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        logger.info("Sign out attempt")

        do {
            try await (await supabase).auth.signOut()
            currentUser = nil
            isAuthenticated = false
            logger.info("Sign out successful")
        } catch {
            logger.error("Sign out failed: \(error.localizedDescription)")
            // Don't throw error for signOut - just log it
        }
    }
    
    // MARK: - Rate Limiting

    func checkRateLimit(for operation: String) -> Bool {
        // Default implementation for protocol conformance
        return true
    }

    private func checkEmailRateLimit(for email: String) throws {
        let now = Date()
        if let attempt = loginAttempts[email] {
            let timeSinceLastAttempt = now.timeIntervalSince(attempt.lastAttempt)
            
            if timeSinceLastAttempt < lockoutDuration && attempt.count >= maxLoginAttempts {
                let remainingTime = lockoutDuration - timeSinceLastAttempt
                logger.warning("Rate limit exceeded for: \(email)")
                throw AuthError.rateLimitExceeded(remainingTime)
            }
        }
    }
    
    private func recordFailedLoginAttempt(for email: String) {
        let now = Date()
        if let attempt = loginAttempts[email] {
            let timeSinceLastAttempt = now.timeIntervalSince(attempt.lastAttempt)
            
            if timeSinceLastAttempt > lockoutDuration {
                // ロックアウト期間を過ぎているのでリセット
                loginAttempts[email] = (count: 1, lastAttempt: now)
            } else {
                // カウントを増やす
                loginAttempts[email] = (count: attempt.count + 1, lastAttempt: now)
            }
        } else {
            // 初回試行
            loginAttempts[email] = (count: 1, lastAttempt: now)
        }
        
        let currentCount = loginAttempts[email]?.count ?? 0
        logger.warning("Failed login recorded for: \(email) (attempts: \(currentCount))")
    }
    
    private func resetLoginAttempts(for email: String) {
        loginAttempts.removeValue(forKey: email)
        logger.info("Login attempts reset for: \(email)")
    }
    
    // MARK: - Session Validation
    
    func validateSession() async throws -> Bool {
        do {
            _ = try await (await supabase).auth.session
            logger.info("Session validation successful")
            return true
        } catch {
            logger.warning("Session validation failed: \(error.localizedDescription)")
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Security Methods (Simplified for GLOBE)
    
    func getDeviceSecurityInfo() -> [String: Any] {
        var info: [String: Any] = [:]

        #if targetEnvironment(simulator)
        info["is_simulator"] = true
        #else
        info["is_simulator"] = false
        #endif

        // 簡単なJailbreak検出
        info["is_jailbroken"] = isJailbroken()

        return info
    }
    
    func reportSecurityEvent(_ event: String, severity: SecuritySeverity, details: [String: String]) {
        let severityText: String
        switch severity {
        case .low:
            severityText = "LOW"
        case .medium:
            severityText = "MEDIUM"
        case .high:
            severityText = "HIGH"
        case .critical:
            severityText = "CRITICAL"
        }
        
        logger.warning("Security Event [\(severityText)]: \(event) - \(details)")
    }
    
    private func isJailbroken() -> Bool {
        // 基本的なJailbreak検出（簡略版）
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/usr/sbin/sshd",
            "/bin/bash",
            "/etc/apt"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Profile Creation
    
    private func createUserProfile(userId: String, username: String, email: String) async {
        logger.info("Creating user profile for: \(username)")
        
        do {
            // まずプロフィールが既に存在するか確認
            let existingProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
            
            let decoder = JSONDecoder()
            let profiles = try? decoder.decode([UserProfile].self, from: existingProfile.data)
            
            if profiles?.isEmpty ?? true {
                // プロフィールが存在しない場合のみ作成
                let profile = [
                    "id": userId,
                    "username": username,
                    "display_name": username, // Use username as default display name
                    "created_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                try await supabase
                    .from("profiles")
                    .insert(profile)
                    .execute()
                
                logger.info("User profile created successfully for: \(username)")
            } else {
                logger.info("Profile already exists for user: \(username)")
            }
        } catch {
            logger.error("Failed to create user profile: \(error.localizedDescription)")
            // プロフィール作成に失敗してもアカウント作成は成功させる
        }
    }

    // MARK: - Development Login Skip

    #if DEBUG
    /// 開発環境でのログインスキップが有効かチェック
    private func isDevelopmentLoginSkipEnabled() -> Bool {
        // UserDefaultsまたは環境変数でチェック
        return UserDefaults.standard.bool(forKey: "DEV_SKIP_LOGIN")
    }

    /// 開発環境用の認証状態を設定
    func enableDevelopmentAuth() {
        let devUser = AppUser(
            id: "dev-user-\(UUID().uuidString.prefix(8))",
            email: "dev@globe.app",
            username: "dev_user",
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        currentUser = devUser
        isAuthenticated = true
        logger.info("Development authentication enabled for user: \(devUser.id)")
    }

    /// 開発環境ログインスキップの有効化
    func enableDevelopmentLoginSkip() {
        UserDefaults.standard.set(true, forKey: "DEV_SKIP_LOGIN")
        logger.info("Development login skip enabled")

        // 即座に認証状態を設定
        enableDevelopmentAuth()
    }

    /// 開発環境ログインスキップの無効化
    func disableDevelopmentLoginSkip() {
        UserDefaults.standard.removeObject(forKey: "DEV_SKIP_LOGIN")
        currentUser = nil
        isAuthenticated = false
        logger.info("Development login skip disabled")
    }
    #endif
}
