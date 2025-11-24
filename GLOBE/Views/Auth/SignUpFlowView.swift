//======================================================================
// MARK: - SignUpFlowView.swift
// Purpose: Sign up with Apple Sign In only
// Path: GLOBE/Views/Auth/SignUpFlowView.swift
//======================================================================

import SwiftUI
import AuthenticationServices
import Supabase

struct SignUpFlowView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var showAppleSignUpProfileSetup = false
    @State private var appleUserSession: Session?

    var body: some View {
        NavigationStack {
            ZStack {
                MinimalDesign.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with close button
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                    Spacer(minLength: 80)

                    // Title
                    VStack(spacing: 12) {
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1)

                        Text("Sign up with your Apple ID")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(0.5)
                    }
                    .padding(.bottom, 60)

                    // Apple Sign In Button
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

                    // Terms & Privacy
                    VStack(spacing: 8) {
                        Text("By signing up, you agree to our")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))

                        HStack(spacing: 4) {
                            Button(action: {
                                // Terms of Service
                            }) {
                                Text("Terms of Service")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .underline()
                            }

                            Text("and")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))

                            Button(action: {
                                // Privacy Policy
                            }) {
                                Text("Privacy Policy")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .underline()
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $showAppleSignUpProfileSetup) {
                if let session = appleUserSession {
                    AppleSignUpProfileSetupView(session: session)
                }
            }
        }
    }

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
                    // 既存ユーザー → ログイン完了
                    _ = try? await authManager.validateSession()
                    dismiss()
                } else {
                    // 新規ユーザー → プロフィール設定画面へ
                    appleUserSession = session
                    showAppleSignUpProfileSetup = true
                }
            } catch {
                SecureLogger.shared.error("Apple Sign In failed: \(error.localizedDescription)")
            }

        case .failure(let error):
            SecureLogger.shared.error("Apple Sign In authorization failed: \(error.localizedDescription)")
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
    SignUpFlowView()
        .environmentObject(AuthManager.shared)
}
