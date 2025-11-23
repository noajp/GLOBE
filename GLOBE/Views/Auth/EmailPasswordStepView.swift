//======================================================================
// MARK: - EmailPasswordStepView.swift
// Purpose: Step 1 - Email and Password input
// Path: GLOBE/Views/Auth/EmailPasswordStepView.swift
//======================================================================

import SwiftUI
import Supabase

struct EmailPasswordStepView: View {
    @Binding var email: String
    @Binding var password: String
    let onNext: () -> Void

    @State private var showPasswordError = false
    @State private var passwordErrorMessage = ""

    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private var isValidPassword: Bool {
        // 開発環境ではパスワード制約なし
        #if DEBUG
        return !password.isEmpty
        #else
        guard password.count >= 8 else { return false }
        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasLetter && hasNumber
        #endif
    }

    private var passwordRequirements: String {
        #if DEBUG
        return "" // 開発環境では制約表示なし
        #else
        var missing: [String] = []
        if password.count < 8 {
            missing.append("8+ characters")
        }
        if password.range(of: "[A-Za-z]", options: .regularExpression) == nil {
            missing.append("letters")
        }
        if password.range(of: "[0-9]", options: .regularExpression) == nil {
            missing.append("numbers")
        }
        return missing.isEmpty ? "" : "Required: " + missing.joined(separator: ", ")
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(spacing: 12) {
                Text("Create your account")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1)

                Text("Enter your email and create a password")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.5)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 60)

            // Form
            VStack(spacing: 20) {
                // Email
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 0) {
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.gray))
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .tint(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                    }
                    .background(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )

                    // Email validation feedback
                    if !email.isEmpty && !isValidEmail {
                        Text("Please enter a valid email address")
                            .font(.system(size: 12))
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }

                // Password
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
                                .stroke(
                                    !password.isEmpty && !isValidPassword ? Color.red.opacity(0.5) : .white.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        .textContentType(.newPassword)

                    // Password requirements feedback
                    if !password.isEmpty && !isValidPassword {
                        Text(passwordRequirements)
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    } else if !password.isEmpty && isValidPassword {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            Text("Password meets requirements")
                                .font(.system(size: 12))
                                .foregroundColor(.green.opacity(0.8))
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)

            // Next Button
            Button(action: {
                if !isValidEmail {
                    showPasswordError = true
                    passwordErrorMessage = "Please enter a valid email address"
                } else if !isValidPassword {
                    showPasswordError = true
                    passwordErrorMessage = "Password must be at least 8 characters and contain both letters and numbers"
                } else {
                    onNext()
                }
            }) {
                Text("Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MinimalDesign.Colors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.white)
                    .cornerRadius(26)
            }
            .disabled(email.isEmpty || password.isEmpty || !isValidEmail || !isValidPassword)
            .opacity((email.isEmpty || password.isEmpty || !isValidEmail || !isValidPassword) ? 0.6 : 1.0)
            .padding(.horizontal, 32)
        }
        .alert("Invalid Input", isPresented: $showPasswordError) {
            Button("OK") {}
        } message: {
            Text(passwordErrorMessage)
        }
    }
}
