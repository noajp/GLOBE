//======================================================================
// MARK: - SignUpPasswordSetupView.swift
// Purpose: Step 3 - Set password, user ID, and display name
// Path: GLOBE/Views/Auth/SignUpPasswordSetupView.swift
//======================================================================
import SwiftUI
import Supabase

struct SignUpPasswordSetupView: View {
    let email: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var userId = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isUserIdValid = false
    @State private var isCheckingUserId = false
    @State private var userIdValidationMessage = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Complete Your Profile")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(MinimalDesign.Colors.text)

                        Text("Set up your password and profile information")
                            .font(.system(size: 16))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 20) {
                        // User ID input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("User ID")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MinimalDesign.Colors.textSecondary)

                            HStack(spacing: 0) {
                                Text("@")
                                    .font(.system(size: 17))
                                    .foregroundColor(MinimalDesign.Colors.text)

                                TextField("", text: $userId)
                                    .font(.system(size: 17))
                                    .foregroundColor(MinimalDesign.Colors.text)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: userId) { newValue in
                                        Task {
                                            await checkUserIdAvailability(newValue)
                                        }
                                    }
                            }
                            .padding(16)
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(12)

                            // Validation status
                            if isCheckingUserId {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Checking...")
                                        .font(.system(size: 12))
                                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                                }
                            } else if !userIdValidationMessage.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: isUserIdValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(isUserIdValid ? .green : .red)
                                    Text(userIdValidationMessage)
                                        .font(.system(size: 12))
                                        .foregroundColor(isUserIdValid ? .green : .red)
                                }
                            }
                        }

                        // Display Name input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MinimalDesign.Colors.textSecondary)

                            TextField("", text: $displayName)
                                .font(.system(size: 17))
                                .foregroundColor(MinimalDesign.Colors.text)
                                .padding(16)
                                .background(MinimalDesign.Colors.secondaryBackground)
                                .cornerRadius(12)
                        }

                        // Password input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MinimalDesign.Colors.textSecondary)

                            HStack {
                                if showPassword {
                                    TextField("", text: $password)
                                        .font(.system(size: 17))
                                        .foregroundColor(MinimalDesign.Colors.text)
                                } else {
                                    SecureField("", text: $password)
                                        .font(.system(size: 17))
                                        .foregroundColor(MinimalDesign.Colors.text)
                                }

                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                                }
                            }
                            .padding(16)
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(12)

                            Text("At least 8 characters with letters and numbers")
                                .font(.system(size: 12))
                                .foregroundColor(MinimalDesign.Colors.textSecondary)
                        }

                        // Confirm Password input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MinimalDesign.Colors.textSecondary)

                            HStack {
                                if showConfirmPassword {
                                    TextField("", text: $confirmPassword)
                                        .font(.system(size: 17))
                                        .foregroundColor(MinimalDesign.Colors.text)
                                } else {
                                    SecureField("", text: $confirmPassword)
                                        .font(.system(size: 17))
                                        .foregroundColor(MinimalDesign.Colors.text)
                                }

                                Button(action: {
                                    showConfirmPassword.toggle()
                                }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                                }
                            }
                            .padding(16)
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(12)
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

                    // Create Account button
                    Button(action: {
                        Task {
                            await createAccount()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Create Account")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .background(canCreateAccount ? Color(red: 0.0, green: 0.55, blue: 0.75) : Color.gray)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .disabled(!canCreateAccount || isLoading)
                    .padding(.bottom, 40)
                }
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
    }

    private var canCreateAccount: Bool {
        !userId.isEmpty &&
        isUserIdValid &&
        !displayName.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }

    private func checkUserIdAvailability(_ userid: String) async {
        isCheckingUserId = true
        isUserIdValid = false
        userIdValidationMessage = ""

        let cleanedUserId = userid.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !cleanedUserId.isEmpty else {
            isCheckingUserId = false
            return
        }

        guard cleanedUserId.count >= 3 && cleanedUserId.count <= 30 else {
            userIdValidationMessage = "User ID must be 3-30 characters"
            isCheckingUserId = false
            return
        }

        guard cleanedUserId.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            userIdValidationMessage = "Only lowercase letters, numbers, and underscores"
            isCheckingUserId = false
            return
        }

        do {
            let response = try await supabase
                .from("profiles")
                .select("id")
                .eq("userid", value: cleanedUserId)
                .execute()

            let decoder = JSONDecoder()
            let profiles = try? decoder.decode([UserProfile].self, from: response.data)

            if profiles?.isEmpty ?? true {
                isUserIdValid = true
                userIdValidationMessage = "✓ Available"
            } else {
                isUserIdValid = false
                userIdValidationMessage = "Already taken"
            }
        } catch {
            userIdValidationMessage = "Error checking availability"
        }

        isCheckingUserId = false
    }

    private func createAccount() async {
        errorMessage = nil
        isLoading = true

        // Validate passwords match
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }

        // Validate password strength
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            isLoading = false
            return
        }

        let cleanedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await authManager.signUp(
                email: email,
                password: password,
                displayName: trimmedDisplayName,
                username: cleanedUserId
            )

            SecureLogger.shared.info("Account created successfully")
            // Dismiss entire navigation stack
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            SecureLogger.shared.error("Account creation failed: \(error.localizedDescription)")
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        SignUpPasswordSetupView(email: "user@example.com")
            .environmentObject(AuthManager.shared)
    }
}
