//======================================================================
// MARK: - SignUpVerificationView.swift
// Purpose: Step 2 - Verify email with OTP code
// Path: GLOBE/Views/Auth/SignUpVerificationView.swift
//======================================================================
import SwiftUI
import Supabase

struct SignUpVerificationView: View {
    let email: String

    @Environment(\.dismiss) private var dismiss
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigateToPasswordSetup = false
    @FocusState private var isCodeFieldFocused: Bool

    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color(red: 0.0, green: 0.55, blue: 0.75))

                    Text("Check Your Email")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    VStack(spacing: 4) {
                        Text("We sent a verification code to")
                            .font(.system(size: 16))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)

                        Text(email)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.text)
                    }
                }
                .padding(.top, 60)

                // Verification code input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification Code")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)

                    TextField("Enter 6-digit code", text: $verificationCode)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundColor(MinimalDesign.Colors.text)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .focused($isCodeFieldFocused)
                        .padding(16)
                        .background(MinimalDesign.Colors.secondaryBackground)
                        .cornerRadius(12)
                        .onChange(of: verificationCode) { newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                verificationCode = String(newValue.prefix(6))
                            }
                            // Auto-verify when 6 digits entered
                            if newValue.count == 6 {
                                Task {
                                    await verifyCode()
                                }
                            }
                        }
                }
                .padding(.horizontal, 32)

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                }

                // Resend code
                Button(action: {
                    Task {
                        await resendCode()
                    }
                }) {
                    Text("Resend Code")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.0, green: 0.55, blue: 0.75))
                }

                Spacer()

                // Verify button
                Button(action: {
                    Task {
                        await verifyCode()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Verify")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(verificationCode.count == 6 && !isLoading ? Color(red: 0.0, green: 0.55, blue: 0.75) : Color.gray)
                .cornerRadius(12)
                .padding(.horizontal, 32)
                .disabled(verificationCode.count != 6 || isLoading)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(MinimalDesign.Colors.text)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToPasswordSetup) {
            SignUpPasswordSetupView(email: email)
        }
        .onAppear {
            isCodeFieldFocused = true
        }
    }

    private func verifyCode() async {
        errorMessage = nil
        isLoading = true

        do {
            // Verify OTP
            try await supabase.auth.verifyOTP(
                email: email,
                token: verificationCode,
                type: .email
            )

            navigateToPasswordSetup = true
            SecureLogger.shared.info("Email verified successfully")
        } catch {
            errorMessage = "Invalid verification code. Please try again."
            verificationCode = ""
            SecureLogger.shared.error("OTP verification failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    private func resendCode() async {
        do {
            try await supabase.auth.signInWithOTP(email: email)
            SecureLogger.shared.info("Verification code resent")
        } catch {
            errorMessage = "Failed to resend code. Please try again."
            SecureLogger.shared.error("Failed to resend OTP: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NavigationStack {
        SignUpVerificationView(email: "user@example.com")
    }
}
