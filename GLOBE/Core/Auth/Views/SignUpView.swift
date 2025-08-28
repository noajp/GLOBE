import SwiftUI
import Combine
import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var authManager = AuthManager.shared
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case username, email, password
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
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Text("Connect with the world on GLOBE")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(0.5)
                }
                .padding(.bottom, 60)
                
                // フォーム
                VStack(spacing: 20) {
                    // ユーザー名入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("globe_user", text: $username)
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
                            .textContentType(.username)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .username)
                            .onSubmit {
                                focusedField = .email
                            }
                    }
                    
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
                        Text("Password (8+ characters)")
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
                                    await signUp()
                                }
                            }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                
                // ボタン
                VStack(spacing: 16) {
                    // サインアップボタン（メイン）
                    Button(action: {
                        Task {
                            await signUp()
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
                            Text("Create Account")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(customBlack)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(.white)
                                .cornerRadius(26)
                
                        }
                    }
                    .disabled(authManager.isLoading || username.isEmpty || email.isEmpty || password.isEmpty)
                    .opacity((authManager.isLoading || username.isEmpty || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                
                // フッター
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Sign In")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                    
                    Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Auto-focus username field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .username
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
    
    private func signUp() async {
        do {
            try await authManager.signUp(
                email: email,
                password: password,
                username: username
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}