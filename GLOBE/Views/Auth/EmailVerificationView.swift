//======================================================================
// MARK: - EmailVerificationView.swift
// Purpose: Display email verification message after signup
// Path: GLOBE/Views/Auth/EmailVerificationView.swift
//======================================================================
import SwiftUI

struct EmailVerificationView: View {
    let email: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Email icon
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.0, green: 0.55, blue: 0.75))

                // Title
                Text("Verify Your Email")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(MinimalDesign.Colors.text)

                // Message
                VStack(spacing: 12) {
                    Text("We've sent a verification email to:")
                        .font(.system(size: 16))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)

                    Text(email)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    Text("Please check your inbox and click the verification link to activate your account.")
                        .font(.system(size: 14))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Back to login button
                Button(action: {
                    dismiss()
                }) {
                    Text("Back to Login")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.0, green: 0.55, blue: 0.75))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    EmailVerificationView(email: "user@example.com")
}
