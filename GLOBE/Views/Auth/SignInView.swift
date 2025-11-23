//======================================================================
// MARK: - SignInView.swift
// Purpose: Sign in screen with Sign Up button at bottom
// Path: GLOBE/Views/Auth/SignInView.swift
//======================================================================

import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSignUp = false

    @Environment(\.dismiss) var dismiss
    @ObservedObject private var authManager = AuthManager.shared

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
                .padding(.bottom, 40)

                Spacer()

                // Sign Up ボタン（下部）
                VStack(spacing: 16) {
                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 32)

                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))

                        Button(action: {
                            showSignUp = true
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                }
                .padding(.bottom, 40)
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
}

#Preview {
    SignInView()
}
