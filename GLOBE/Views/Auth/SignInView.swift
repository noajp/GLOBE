import SwiftUI
import Combine
import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPasswordReset = false
    @State private var resetMessage = ""
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var authManager = AuthManager.shared
    @FocusState private var focusedField: Field?
    
    private let logger = DebugLogger.shared
    
    enum Field: Hashable {
        case email, password
    }
    
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
                
                // ロゴエリア - Liquid Glass Card
                VStack(spacing: 12) {
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Text("Sign in to GLOBE")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(0.5)
                }
                .padding(.bottom, 60)
                
                // フォーム - Liquid Glass Container
                VStack(spacing: 20) {
                    // メールアドレス入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("email@example.com", text: $email)
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
            
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    
                    // パスワード入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        SecureField("••••••••", text: $password)
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
                            .submitLabel(.go)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                Task {
                                    await signIn()
                                }
                            }
            
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                
                // ボタン
                VStack(spacing: 16) {
                    // ログインボタン（メイン）
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
                .padding(.bottom, 60)
                
                // フッター
                VStack(spacing: 12) {
                    // パスワードを忘れた場合のリンク
                    Button(action: {
                        Task {
                            await resetPassword()
                        }
                    }) {
                        Text("Forgot Password?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .underline()
                    }
                    
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button(action: {
                            dismiss()
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
        .onAppear {
            // Auto-focus email field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .email
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .alert("Password Reset", isPresented: $showPasswordReset) {
            Button("OK") {}
        } message: {
            Text(resetMessage)
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
    
    private func signIn() async {
        ConsoleLogger.shared.forceLog("SignInView: Starting sign in process for \(email)")
        
        logger.info("Starting sign in process", category: "SignInView", details: [
            "email": email,
            "password_length": password.count,
            "has_email": !email.isEmpty,
            "has_password": !password.isEmpty
        ])
        
        do {
            try await authManager.signIn(
                email: email,
                password: password
            )
            ConsoleLogger.shared.forceLog("SignInView: Sign in SUCCESS")
            logger.success("Sign in completed successfully", category: "SignInView")
        } catch {
            ConsoleLogger.shared.logError("SignInView sign in failed", error: error)
            
            logger.error("Sign in failed", category: "SignInView", details: [
                "error": error.localizedDescription,
                "error_type": String(describing: type(of: error)),
                "email": email
            ])
            
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func resetPassword() async {
        guard !email.isEmpty else {
            logger.warning("Password reset attempted without email", category: "SignInView")
            errorMessage = "パスワードリセットを行うにはメールアドレスを入力してください"
            showError = true
            return
        }
        
        logger.info("Starting password reset", category: "SignInView", details: [
            "email": email
        ])
        
        do {
            try await authManager.sendPasswordResetEmail(email: email)
            logger.success("Password reset email sent successfully", category: "SignInView", details: [
                "email": email
            ])
            resetMessage = "パスワードリセットメールを送信しました。メールをご確認ください。"
            showPasswordReset = true
        } catch {
            logger.error("Password reset failed", category: "SignInView", details: [
                "email": email,
                "error": error.localizedDescription
            ])
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}