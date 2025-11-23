//======================================================================
// MARK: - DisplayNameStepView.swift
// Purpose: Step 3 - Display Name input and account creation
// Path: GLOBE/Views/Auth/DisplayNameStepView.swift
//======================================================================

import SwiftUI

struct DisplayNameStepView: View {
    let email: String
    let password: String
    let username: String
    @Binding var displayName: String
    let onComplete: () -> Void

    @State private var showError = false
    @State private var errorMessage = ""
    @ObservedObject private var authManager = AuthManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(spacing: 12) {
                Text("What's your name?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1)

                Text("This is how you'll appear to others.\nYou can use your real name or a nickname.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.5)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 60)

            // Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("", text: $displayName, prompt: Text("Name").foregroundColor(.gray))
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
                }

                // Summary
                VStack(spacing: 12) {
                    HStack {
                        Text("Email:")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(email)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    HStack {
                        Text("Username:")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text("@\(username)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(16)
                .background(.white.opacity(0.05))
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)

            // Create Account Button
            Button(action: {
                Task {
                    await createAccount()
                }
            }) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: MinimalDesign.Colors.background))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.white)
                        .cornerRadius(26)
                } else {
                    Text("Create Account")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.white)
                        .cornerRadius(26)
                }
            }
            .disabled(displayName.isEmpty || authManager.isLoading)
            .opacity((displayName.isEmpty || authManager.isLoading) ? 0.6 : 1.0)
            .padding(.horizontal, 32)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func createAccount() async {
        ConsoleLogger.shared.forceLog("DisplayNameStepView: Creating account for \(email)")
        do {
            try await authManager.signUp(
                email: email,
                password: password,
                displayName: displayName,
                username: username
            )
            ConsoleLogger.shared.forceLog("DisplayNameStepView: Account created successfully")
            onComplete()
        } catch {
            ConsoleLogger.shared.logError("DisplayNameStepView: Account creation failed", error: error)

            // Check if error is due to duplicate email
            let errorDescription = error.localizedDescription
            if errorDescription.contains("already") || errorDescription.contains("duplicate") || errorDescription.contains("User already registered") {
                errorMessage = "This email is already registered. Please sign in instead or use a different email."
            } else {
                errorMessage = errorDescription
            }
            showError = true
        }
    }
}
