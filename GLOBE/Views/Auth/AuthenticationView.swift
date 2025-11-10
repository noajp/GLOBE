import SwiftUI
import Combine

struct AuthenticationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // ダークモード対応の背景
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // シンプルなヘッダー
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(MinimalDesign.Colors.primary.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)

                    // ロゴエリア
                    VStack(spacing: 12) {
                        Text("GLOBE")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .tracking(2)

                        Text("Connect with the World")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.primary.opacity(0.7))
                            .tracking(1)
                    }
                    .padding(.bottom, 60)

                    // タブ切り替え
                    HStack(spacing: 0) {
                        Button(action: { withAnimation { isSignUp = false } }) {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isSignUp ? MinimalDesign.Colors.secondary : MinimalDesign.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }

                        Button(action: { withAnimation { isSignUp = true } }) {
                            Text("Sign Up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isSignUp ? MinimalDesign.Colors.primary : MinimalDesign.Colors.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 8)

                    // アンダーライン
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(MinimalDesign.Colors.accentRed)
                            .frame(width: geometry.size.width / 2, height: 2)
                            .offset(x: isSignUp ? geometry.size.width / 2 : 0)
                            .animation(.easeInOut(duration: 0.3), value: isSignUp)
                    }
                    .frame(height: 2)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)

                    // フォーム
                    VStack(spacing: 20) {
                        // Display Name (Sign Up only)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Display Name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(MinimalDesign.Colors.secondary)

                                TextField("Your Name", text: $displayName)
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .font(.system(size: 16))
                                    .padding()
                                    .background(MinimalDesign.Colors.secondaryBackground)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                                    )
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(MinimalDesign.Colors.secondary)

                            TextField("email@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .font(.system(size: 16))
                                .padding()
                                .background(MinimalDesign.Colors.secondaryBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                                )
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(MinimalDesign.Colors.secondary)

                            SecureField("••••••••", text: $password)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .font(.system(size: 16))
                                .padding()
                                .background(MinimalDesign.Colors.secondaryBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                                )
                        }

                        // ボタン
                        Button(action: {
                            Task {
                                await handleAuthentication()
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(MinimalDesign.Colors.accentRed)
                        .cornerRadius(26)
                        .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty))
                        .opacity((isLoading || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty)) ? 0.6 : 1.0)
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)

                    // フッター
                    VStack(spacing: 8) {
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(MinimalDesign.Colors.tertiary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 40)
                }
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
    }

    private func handleAuthentication() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if isSignUp {
                // サインアップ
                try await authManager.signUp(email: email, password: password, displayName: displayName)
            } else {
                // サインイン
                try await authManager.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}



#Preview {
    AuthenticationView()
}
