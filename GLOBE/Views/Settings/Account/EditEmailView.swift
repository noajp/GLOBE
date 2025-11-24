//======================================================================
// MARK: - EditEmailView.swift
// Purpose: Edit email with validation
// Path: GLOBE/Views/Settings/Account/EditEmailView.swift
//======================================================================
import SwiftUI
import Supabase

struct EditEmailView: View {
    let currentEmail: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedEmail: String = ""
    @State private var isValid = false
    @State private var validationMessage = ""
    @State private var isSaving = false

    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // Input field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)

                    TextField("", text: $editedEmail)
                        .font(.system(size: 17))
                        .foregroundColor(MinimalDesign.Colors.text)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .onChange(of: editedEmail) { newValue in
                            validateEmail(newValue)
                        }
                        .padding(12)
                        .background(MinimalDesign.Colors.secondaryBackground)
                        .cornerRadius(8)
                }

                // Validation status
                if !validationMessage.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isValid ? .green : .red)
                        Text(validationMessage)
                            .font(.system(size: 14))
                            .foregroundColor(isValid ? .green : .red)
                    }
                }

                // Info text
                Text("Your email address is used for account recovery and important notifications. Make sure you have access to this email.")
                    .font(.system(size: 13))
                    .foregroundColor(MinimalDesign.Colors.textSecondary)
                    .lineSpacing(4)

                Spacer()

                // Save button
                Button(action: {
                    Task {
                        await saveEmail()
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .background(isValid && !isSaving ? Color.blue : Color.gray)
                .cornerRadius(8)
                .disabled(!isValid || isSaving)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Edit Email")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editedEmail = currentEmail
        }
    }

    private func validateEmail(_ email: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Basic validation
        guard !trimmedEmail.isEmpty else {
            isValid = false
            validationMessage = "Email cannot be empty"
            return
        }

        // Email format validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        guard emailPredicate.evaluate(with: trimmedEmail) else {
            isValid = false
            validationMessage = "Invalid email format"
            return
        }

        // Check if same as current
        if trimmedEmail == currentEmail {
            isValid = true
            validationMessage = "This is your current email"
            return
        }

        isValid = true
        validationMessage = "✓ Valid email format"
    }

    private func saveEmail() async {
        isSaving = true

        let trimmedEmail = editedEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(trimmedEmail)

        isSaving = false
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EditEmailView(currentEmail: "user@example.com", onSave: { _ in })
    }
}
