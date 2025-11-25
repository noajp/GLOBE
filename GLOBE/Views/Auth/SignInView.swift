//======================================================================
// MARK: - SignInView.swift
// Purpose: Sign in screen with email/password and Apple Sign In
// Path: GLOBE/Views/Auth/SignInView.swift
//======================================================================

import SwiftUI
import AuthenticationServices
import Supabase

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showAppleProfileSetup = false
    @State private var appleUserSession: Session?

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager

    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background

    var body: some View {
        ZStack {
            // シンプルな黒背景
            customBlack
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 60)

                // シンプルなヘッダー
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)

                // ロゴエリア
                VStack(spacing: 12) {
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)

                    Text("Sign in to continue")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(0.5)
                }
                .padding(.bottom, 60)

                // フォーム
                VStack(spacing: 20) {
                    // メールアドレス入力
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray))
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .tint(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                    }

                    // パスワード入力
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.gray))
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .textContentType(.password)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

                // サインインボタン
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await signIn()
                        }
                    }) {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: customBlack))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(.white)
                                .cornerRadius(26)

                        } else {
                            Text("Sign In")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(customBlack)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(.white)
                                .cornerRadius(26)

                        }
                    }
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                    .opacity((authManager.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                }
                .padding(.horizontal, 32)

                // Divider
                HStack(spacing: 16) {
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(height: 1)

                    Text("OR")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(height: 1)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)

                // Apple Sign Up Button
                SignInWithAppleButton(.signUp) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        await handleAppleSignIn(result)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .cornerRadius(26)
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
        .navigationDestination(isPresented: $showAppleProfileSetup) {
            if let session = appleUserSession {
                AppleSignUpProfileSetupView(session: session)
                    .environmentObject(authManager)
            }
        }
    }

    private func signIn() async {
        ConsoleLogger.shared.forceLog("SignInView: Starting sign in for \(email)")

        do {
            try await authManager.signIn(email: email, password: password)
            ConsoleLogger.shared.forceLog("SignInView: Sign in SUCCESS")
        } catch {
            ConsoleLogger.shared.logError("SignInView sign in failed", error: error)
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        SecureLogger.shared.info("🔵 NEW CODE: handleAppleSignIn called - Build timestamp: \(Date())")
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                SecureLogger.shared.error("Failed to get Apple ID credential")
                return
            }

            guard let identityToken = appleIDCredential.identityToken,
                  let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                SecureLogger.shared.error("Failed to get identity token")
                return
            }

            do {
                // Supabaseに認証情報を送信
                let session = try await supabase.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: identityTokenString
                    )
                )

                SecureLogger.shared.info("Apple Sign In successful: \(session.user.id)")

                // プロフィールが存在するかチェック
                let profileExists = try await checkProfileExists(userId: session.user.id.uuidString)
                SecureLogger.shared.info("Profile exists check: \(profileExists)")

                if profileExists {
                    // 既存ユーザー → ログイン完了
                    SecureLogger.shared.info("Existing user - calling checkCurrentUser()")
                    await authManager.checkCurrentUser()
                    SecureLogger.shared.info("checkCurrentUser() completed, isAuthenticated: \(authManager.isAuthenticated)")
                } else {
                    // 新規ユーザー → プロフィール設定画面へ
                    SecureLogger.shared.info("New user - showing profile setup")
                    appleUserSession = session
                    showAppleProfileSetup = true
                }
            } catch {
                SecureLogger.shared.error("Apple Sign In failed: \(error.localizedDescription)")
                errorMessage = "Apple Sign In failed. Please try again."
                showError = true
            }

        case .failure(let error):
            SecureLogger.shared.error("Apple Sign In authorization failed: \(error.localizedDescription)")
            if (error as NSError).code != 1001 { // 1001 = user cancelled
                errorMessage = "Apple Sign In failed. Please try again."
                showError = true
            }
        }
    }

    private func checkProfileExists(userId: String) async throws -> Bool {
        let response = try await supabase
            .from("profiles")
            .select("id")
            .eq("id", value: userId)
            .execute()

        let decoder = JSONDecoder()
        let profiles = try? decoder.decode([UserProfile].self, from: response.data)

        return !(profiles?.isEmpty ?? true)
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthManager.shared)
}
