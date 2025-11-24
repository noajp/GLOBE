//======================================================================
// MARK: - AuthManager.swift
// Function: Authentication Manager
// Overview: User authentication, session management, security checks
// Processing: Supabase Auth integration, input validation, device security monitoring
//======================================================================

import Foundation
import Supabase
import Combine
import AuthenticationServices
import CryptoKit

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

    private init() {
        // 初期化時は現在のセッションをチェック
        Task {
            let _ = await checkCurrentUser()
        }
    }

    // Publisher exposure for protocol requirement
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { $isAuthenticated.eraseToAnyPublisher() }

    //###########################################################################
    // MARK: - Session Management
    // Function: checkCurrentUser
    // Overview: Verify and restore existing user session
    // Processing: Fetch Supabase session → Update currentUser → Return auth status
    //###########################################################################

    func checkCurrentUser() async -> Bool {
        do {
            let session = try await (await supabase).auth.session
            let user = session.user

            // プロフィール情報を取得してhome_countryを含める
            let homeCountry = try? await fetchUserHomeCountry(userId: user.id.uuidString)

            currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format(),
                homeCountry: homeCountry
            )
            isAuthenticated = true
            return true

        } catch {
            logger.info("No current user session found")
            isAuthenticated = false
            currentUser = nil
            return false
        }
    }
    
    //###########################################################################
    // MARK: - Sign Up
    // Function: signUp
    // Overview: Create new user account with email and password
    // Processing: Validate input → Create Supabase auth user → Create profile → Return success
    //###########################################################################

    func signUp(email: String, password: String, displayName: String, username: String) async throws {
        logger.info("AuthManager.signUp: begin for \(email)")
        // 入力検証
        let emailValidation = InputValidator.validateEmail(email)
        guard emailValidation.isValid, let validEmail = emailValidation.value else {
            logger.error("AuthManager.signUp: invalid email")
            throw AuthError.invalidInput("有効なメールアドレスを入力してください")
        }

        #if !DEBUG
        // 本番環境のみパスワード検証
        let passwordValidation = InputValidator.validatePassword(password)
        guard passwordValidation.isValid else {
            logger.error("AuthManager.signUp: weak password")
            throw AuthError.weakPassword(["パスワードは8文字以上で、英字と数字を含む必要があります"])
        }
        #endif

        // Display name validation: 1-50 characters
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDisplayName.isEmpty && trimmedDisplayName.count >= 1 && trimmedDisplayName.count <= 50 else {
            logger.error("AuthManager.signUp: invalid display name")
            throw AuthError.invalidInput("表示名は1-50文字で入力してください")
        }
        let validDisplayName = trimmedDisplayName

        // Username validation: 3-30 characters, lowercase alphanumeric with underscores
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedUsername.isEmpty && trimmedUsername.count >= 3 && trimmedUsername.count <= 30 else {
            logger.error("AuthManager.signUp: invalid username length")
            throw AuthError.invalidInput("ユーザーネームは3-30文字で入力してください")
        }
        guard trimmedUsername.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            logger.error("AuthManager.signUp: invalid username format")
            throw AuthError.invalidInput("ユーザーネームは英数字とアンダースコアのみ使用できます")
        }
        let validUsername = trimmedUsername

        isLoading = true
        defer { isLoading = false }

        logger.info("Sign up attempt for: \(validEmail)")
        SecureLogger.shared.authEvent("sign_up_attempt", userID: nil)

        do {
            let response = try await (await supabase).auth.signUp(
                email: validEmail,
                password: password,
                data: [
                    "display_name": AnyJSON.string(validDisplayName),
                    "username": AnyJSON.string(validUsername)
                ]
            )

            let user = response.user
            print("✅ [AuthManager] Sign up SUCCESS for user: \(user.id.uuidString), email: \(user.email ?? "none")")
            logger.info("Sign up successful for user: \(user.id.uuidString)")
            logger.info("AuthManager.signUp: success user=\(user.id.uuidString)")
            SecureLogger.shared.authEvent("sign_up_success", userID: user.id.uuidString)

            #if DEBUG
            // 開発環境: メール認証をスキップして直接認証済み状態にする
            currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format(),
                homeCountry: nil // サインアップ直後はhome_countryなし
            )
            isAuthenticated = true
            logger.info("Development mode: Email verification skipped")
            #else
            // 本番環境: メール認証が必要
            // ユーザーは認証メールを確認してログインする必要がある
            currentUser = nil
            isAuthenticated = false
            logger.info("Production mode: Email verification required. Please check your email to verify your account.")
            #endif

            // handle_new_user関数が自動的にプロフィールを作成するため、
            // ここでは作成しない（RLSポリシー違反を避ける）
            logger.info("Profile will be created by handle_new_user trigger with username: \(validUsername)")

        } catch {
            print("❌ [AuthManager] Sign up FAILED: \(error.localizedDescription)")
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

            // プロフィール情報を取得してhome_countryを含める
            let homeCountry = try? await fetchUserHomeCountry(userId: user.id.uuidString)

            currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format(),
                homeCountry: homeCountry
            )
            isAuthenticated = true

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

                SecureLogger.shared.authEvent("sign_in_failed_\(nsError.code)", userID: nil)
                throw AuthError.unknown(errorMessage)
            }

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

    // MARK: - Apple Sign In

    func signInWithApple() async throws {
        logger.info("AuthManager.signInWithApple: Starting Apple Sign In")

        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        // Create coordinator to handle the response
        let coordinator = AppleSignInCoordinator(
            nonce: nonce,
            onSuccess: { [weak self] idToken, displayName in
                Task { @MainActor in
                    do {
                        try await self?.handleAppleSignInSuccess(idToken: idToken, nonce: nonce, displayName: displayName)
                    } catch {
                        self?.logger.error("Failed to complete Apple Sign In: \(error.localizedDescription)")
                    }
                }
            },
            onFailure: { [weak self] error in
                self?.logger.error("Apple Sign In failed: \(error.localizedDescription)")
            }
        )

        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator
        authorizationController.performRequests()

        // Keep coordinator alive
        objc_setAssociatedObject(self, "appleSignInCoordinator", coordinator, .OBJC_ASSOCIATION_RETAIN)
    }

    private func handleAppleSignInSuccess(idToken: String, nonce: String, displayName: String?) async throws {
        let response = try await (await supabase).auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )

        let user = response.user
        logger.info("Apple Sign In successful for user: \(user.id.uuidString)")

        // プロフィール情報を取得してhome_countryを含める
        let homeCountry = try? await fetchUserHomeCountry(userId: user.id.uuidString)

        currentUser = AppUser(
            id: user.id.uuidString,
            email: user.email,
            createdAt: user.createdAt.ISO8601Format(),
            homeCountry: homeCountry
        )
        isAuthenticated = true

        // Create profile if this is first sign in
        if let name = displayName, !name.isEmpty {
            await createUserProfile(userId: user.id.uuidString, displayName: name, email: user.email ?? "")
        }

        SecureLogger.shared.authEvent("apple_sign_in_success", userID: user.id.uuidString)
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
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
        // Rate limiting disabled
        return true
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
    
    private func createUserProfile(userId: String, displayName: String, email: String) async {
        logger.info("Creating user profile for: \(displayName)")

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
                    "display_name": displayName,
                    "created_at": ISO8601DateFormatter().string(from: Date())
                ]

                try await supabase
                    .from("profiles")
                    .insert(profile)
                    .execute()

                logger.info("User profile created successfully for: \(displayName)")
            } else {
                logger.info("Profile already exists for: \(displayName)")
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

    /// 開発環境用の認証状態を設定（DBから最新ユーザーを動的に取得）
    func enableDevelopmentAuth() {
        Task {
            do {
                // Service roleキーを使用してDBから直接ユーザー情報を取得
                // 注意: これは開発環境専用で、本番では絶対に使用しないこと
                let response = try await (await supabase)
                    .from("profiles")
                    .select("id, display_name, created_at")
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                struct SimpleProfile: Codable {
                    let id: String
                    let display_name: String?
                    let created_at: Date
                }

                if let profiles = try? decoder.decode([SimpleProfile].self, from: response.data),
                   let latestProfile = profiles.first {


                    let devUser = AppUser(
                        id: latestProfile.id,
                        email: "dev@localhost.test", // 開発用ダミーメール
                        createdAt: latestProfile.created_at.ISO8601Format(),
                        homeCountry: nil // 開発モードではhome_countryなし
                    )

                    await MainActor.run {
                        self.currentUser = devUser
                        self.isAuthenticated = true
                    }
                } else {
                    // DBにユーザーがいない場合は認証状態をクリア
                    await MainActor.run {
                        self.logger.warning("No users found in DB for development auth")
                        self.currentUser = nil
                        self.isAuthenticated = false
                    }
                }
            } catch {
                // エラー時は認証状態をクリア
                await MainActor.run {
                    self.logger.error("Failed to enable development auth: \(error.localizedDescription)")
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
        }
    }

    /// 開発環境ログインスキップの有効化
    func enableDevelopmentLoginSkip() {
        UserDefaults.standard.set(true, forKey: "DEV_SKIP_LOGIN")
        logger.info("Development login skip enabled")

        // 非同期で認証状態を設定
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

    //###########################################################################
    // MARK: - Helper: Fetch User Home Country
    // Function: fetchUserHomeCountry
    // Overview: Fetch user's home_country from profiles table
    // Processing: Query profiles → Extract home_country → Return country code
    //###########################################################################

    private func fetchUserHomeCountry(userId: String) async throws -> String? {
        let response = try await (await supabase)
            .from("profiles")
            .select("home_country")
            .eq("id", value: userId)
            .single()
            .execute()

        struct HomeCountryResponse: Codable {
            let home_country: String?
        }

        let decoder = JSONDecoder()
        let result = try? decoder.decode(HomeCountryResponse.self, from: response.data)
        return result?.home_country
    }
}
