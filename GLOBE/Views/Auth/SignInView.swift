//======================================================================
// MARK: - SignInView.swift
// Purpose: Sign in screen with Apple authentication
// Path: GLOBE/Views/Auth/SignInView.swift
//======================================================================

import SwiftUI
import AuthenticationServices
import Supabase

struct SignInView: View {
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSignUp = false

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
                    Text("GLOBE")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)

                    Text("Break free from the timeline,\nexpand your world")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()

                // Apple Sign In Button
                VStack(spacing: 24) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await handleAppleSignIn(result)
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .cornerRadius(26)

                    // Sign Up リンク
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))

                        Button(action: {
                            showSignUp = true
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
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
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpFlowView()
                .environmentObject(authManager)
        }
    }

    @MainActor
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
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

                if profileExists {
                    // 既存ユーザー → AuthManagerを更新してログイン完了
                    SecureLogger.shared.info("Existing user detected, validating session...")
                    let isValid = try await authManager.validateSession()
                    SecureLogger.shared.info("Session validation result: \(isValid)")
                    // onChangeでdismiss()が呼ばれるのを待つ
                } else {
                    // Sign In画面からアカウントがないユーザーがサインインしようとした場合
                    // サインアウトしてSign Up画面へ誘導
                    SecureLogger.shared.warning("No profile found for this account. Please sign up first.")
                    try? await supabase.auth.signOut()
                    errorMessage = "No account found. Please sign up first."
                    showError = true
                }
            } catch {
                SecureLogger.shared.error("Apple Sign In failed: \(error.localizedDescription)")
                errorMessage = "Sign in failed. Please try again."
                showError = true
            }

        case .failure(let error):
            SecureLogger.shared.error("Apple Sign In authorization failed: \(error.localizedDescription)")
            if (error as NSError).code != 1001 { // 1001 = user cancelled
                errorMessage = "Sign in failed. Please try again."
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
