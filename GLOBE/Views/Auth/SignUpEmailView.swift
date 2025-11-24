//======================================================================
// MARK: - SignUpEmailView.swift
// Purpose: Step 1 - Email input and send verification code
// Path: GLOBE/Views/Auth/SignUpEmailView.swift
//======================================================================
import SwiftUI
import Supabase

struct SignUpEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigateToVerification = false
    @State private var verificationEmail = ""

    var body: some View {
        NavigationStack {
            ZStack {
                MinimalDesign.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(MinimalDesign.Colors.text)

                        Text("Enter your email address to get started")
                            .font(.system(size: 16))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)

                    // Email input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)

                        TextField("", text: $email)
                            .font(.system(size: 17))
                            .foregroundColor(MinimalDesign.Colors.text)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.emailAddress)
                            .padding(16)
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                    }

                    Spacer()

                    // Continue button
                    Button(action: {
                        Task {
                            await sendVerificationCode()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .background(email.isEmpty || isLoading ? Color.gray : Color(red: 0.0, green: 0.55, blue: 0.75))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .disabled(email.isEmpty || isLoading)

                    // Back to sign in
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Already have an account? Sign In")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.0, green: 0.55, blue: 0.75))
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $navigateToVerification) {
                SignUpVerificationView(email: verificationEmail)
            }
        }
    }

    private func sendVerificationCode() async {
        errorMessage = nil
        isLoading = true

        // Validate email format
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        guard emailPredicate.evaluate(with: trimmedEmail) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }

        do {
            // Send OTP to email
            try await supabase.auth.signInWithOTP(
                email: trimmedEmail
            )

            verificationEmail = trimmedEmail
            navigateToVerification = true
            SecureLogger.shared.info("Verification code sent to: \(trimmedEmail)")
        } catch {
            errorMessage = "Failed to send verification code. Please try again."
            SecureLogger.shared.error("Failed to send OTP: \(error.localizedDescription)")
        }

        isLoading = false
    }
}

#Preview {
    SignUpEmailView()
}
