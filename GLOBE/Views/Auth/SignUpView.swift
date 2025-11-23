//======================================================================
// MARK: - SignUpView.swift
// Function: Sign Up View
// Overview: User registration with email, password, display name, and username
// Processing: Collect user input → Validate fields → Check username availability → Call AuthManager → Handle registration result
//======================================================================

import SwiftUI
import Supabase

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var username = ""
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool? = nil
    @State private var showError = false
    @State private var errorMessage = ""

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case displayName, username, email, password
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
                    // 表示名入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        TextField("Your Name", text: $displayName)
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
                            .autocorrectionDisabled()
                            .textContentType(.name)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .displayName)
                            .onSubmit {
                                focusedField = .username
                            }
                    }

                    // ユーザーネーム入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        HStack(spacing: 0) {
                            Text("@")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.leading, 16)

                            TextField("username", text: $username)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.leading, 4)
                                .padding(.trailing, 16)
                                .padding(.vertical, 16)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .textContentType(.username)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .username)
                                .onChange(of: username) { _, newValue in
                                    // Convert to lowercase and filter invalid characters
                                    let filtered = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
                                    if filtered != newValue {
                                        username = filtered
                                    }
                                    // Check username availability
                                    Task {
                                        await checkUsernameAvailability()
                                    }
                                }
                                .onSubmit {
                                    focusedField = .email
                                }

                            // Availability indicator
                            if isCheckingUsername {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 16)
                            } else if let available = usernameAvailable, !username.isEmpty {
                                Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(available ? .green : .red)
                                    .padding(.trailing, 16)
                            }
                        }
                        .background(.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(usernameAvailable == false && !username.isEmpty ? Color.red.opacity(0.5) : .white.opacity(0.2), lineWidth: 1)
                        )

                        if usernameAvailable == false && !username.isEmpty {
                            Text("This username is already taken")
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.8))
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
                            .textContentType(.none)
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
                    .disabled(authManager.isLoading || displayName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || usernameAvailable != true)
                    .opacity((authManager.isLoading || displayName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || usernameAvailable != true) ? 0.6 : 1.0)
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
            // Auto-focus displayName field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .displayName
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
    
    //###########################################################################
    // MARK: - Username Availability Check
    // Function: checkUsernameAvailability
    // Overview: Verify if username is unique in the database
    // Processing: Validate length → Query profiles table → Update availability state
    //###########################################################################

    private func checkUsernameAvailability() async {
        // Reset if username is empty
        guard !username.isEmpty else {
            usernameAvailable = nil
            return
        }

        // Minimum length check
        guard username.count >= 3 else {
            usernameAvailable = false
            return
        }

        isCheckingUsername = true
        defer { isCheckingUsername = false }

        do {
            let client = await SupabaseManager.shared.client
            let result = try await client
                .from("profiles")
                .select("username")
                .eq("username", value: username)
                .execute()

            // If we get any results, username is taken
            let decoder = JSONDecoder()
            let profiles = try? decoder.decode([[String: String]].self, from: result.data)
            usernameAvailable = profiles?.isEmpty ?? true
        } catch {
            SecureLogger.shared.error("Failed to check username availability: \(error.localizedDescription)")
            usernameAvailable = nil
        }
    }

    //###########################################################################
    // MARK: - Sign Up Handler
    // Function: signUp
    // Overview: Process user registration with validated credentials
    // Processing: Validate username → Call AuthManager sign up → Handle success/error → Dismiss on success
    //###########################################################################

    private func signUp() async {
        ConsoleLogger.shared.forceLog("SignUpView: Starting sign up for \(email)")

        // Validate username one more time before signup
        guard usernameAvailable == true else {
            errorMessage = "Please choose an available username"
            showError = true
            return
        }

        do {
            try await authManager.signUp(
                email: email,
                password: password,
                displayName: displayName,
                username: username
            )
            ConsoleLogger.shared.forceLog("SignUpView: Sign up SUCCESS")
        } catch {
            ConsoleLogger.shared.logError("SignUpView sign up failed", error: error)
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
