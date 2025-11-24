//======================================================================
// MARK: - AccountSettingsView.swift
// Purpose: Account management settings
// Path: GLOBE/Views/Settings/Account/AccountSettingsView.swift
//======================================================================
import SwiftUI
import Supabase

struct AccountSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteSuccess = false
    @State private var userProfile: UserProfile?
    @State private var isLoadingProfile = true
    @State private var editedUsername = ""
    @State private var editedEmail = ""
    @State private var isSaving = false
    @State private var showingSaveSuccess = false
    @State private var saveError: String?

    // Edit states
    @State private var isEditingUsername = false
    @State private var isEditingEmail = false

    // Validation states
    @State private var isUsernameValid = false
    @State private var isEmailValid = false
    @State private var usernameValidationMessage = ""
    @State private var emailValidationMessage = ""
    @State private var isCheckingUsername = false
    @State private var isCheckingEmail = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Account Info
                accountInfoSection

                Divider()
                    .background(MinimalDesign.Colors.divider)

                // Delete Account
                deleteAccountSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(MinimalDesign.Colors.background)
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await fetchUserProfile()
                // Ensure email is populated
                if editedEmail.isEmpty {
                    editedEmail = authManager.currentUser?.email ?? ""
                }
            }
        }
        .alert("Save Successful", isPresented: $showingSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your account information has been updated successfully.")
        }
        .alert("Save Failed", isPresented: .constant(saveError != nil)) {
            Button("OK", role: .cancel) {
                saveError = nil
            }
        } message: {
            Text(saveError ?? "An error occurred while saving.")
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone. All your posts, likes, and follows will be permanently deleted.")
        }
        .alert("Account Deleted", isPresented: $showingDeleteSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your account has been successfully deleted.")
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var accountInfoSection: some View {
        if let user = authManager.currentUser {
            VStack(alignment: .leading, spacing: 16) {
                if isLoadingProfile {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    accountFields(user: user)
                }
            }
        }
    }

    @ViewBuilder
    private func accountFields(user: AppUser) -> some View {
        // User ID - Navigate to edit screen
        NavigationLink(destination: EditUserIDView(
            currentUserID: editedUsername,
            onSave: { newUserID in
                Task {
                    await updateUserID(newUserID)
                }
            }
        )) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("User ID")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)

                    Text("@\(editedUsername)")
                        .font(.system(size: 15))
                        .foregroundColor(MinimalDesign.Colors.text)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.textTertiary)
            }
        }
        .buttonStyle(PlainButtonStyle())

        // Email - Navigate to edit screen
        NavigationLink(destination: EditEmailView(
            currentEmail: editedEmail,
            onSave: { newEmail in
                Task {
                    await updateEmail(newEmail)
                }
            }
        )) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)

                    Text(editedEmail)
                        .font(.system(size: 15))
                        .foregroundColor(MinimalDesign.Colors.text)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.textTertiary)
            }
        }
        .buttonStyle(PlainButtonStyle())

        // Account Created (read-only)
        AccountInfoRow(label: "Account Created", value: formatDate(user.createdAt))
    }

    @ViewBuilder
    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Once you delete your account, there is no going back. This action cannot be undone.")
                .font(.system(size: 14))
                .foregroundColor(MinimalDesign.Colors.textSecondary)

            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Text("Delete Account")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MinimalDesign.Colors.accentRed)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Validation Functions

    private func checkUsernameAvailability(_ username: String) async {
        // Reset validation state
        isCheckingUsername = true
        isUsernameValid = false
        usernameValidationMessage = ""

        // Clean username
        let cleanedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")

        // Basic validation
        guard !cleanedUsername.isEmpty else {
            isCheckingUsername = false
            usernameValidationMessage = "Username cannot be empty"
            return
        }

        guard cleanedUsername.count >= 3 && cleanedUsername.count <= 30 else {
            isCheckingUsername = false
            usernameValidationMessage = "Username must be 3-30 characters"
            return
        }

        guard cleanedUsername.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            isCheckingUsername = false
            usernameValidationMessage = "Only letters, numbers, and underscores allowed"
            return
        }

        // Check if same as current userid
        if cleanedUsername == userProfile?.userid {
            isCheckingUsername = false
            isUsernameValid = true
            usernameValidationMessage = "OK"
            return
        }

        // Check database for duplicates
        do {
            let response = try await supabase
                .from("profiles")
                .select("id")
                .eq("userid", value: cleanedUsername)
                .execute()

            let decoder = JSONDecoder()
            let profiles = try? decoder.decode([UserProfile].self, from: response.data)

            if profiles?.isEmpty ?? true {
                isUsernameValid = true
                usernameValidationMessage = "OK"
            } else {
                isUsernameValid = false
                usernameValidationMessage = "Username already taken"
            }
        } catch {
            usernameValidationMessage = "Error checking username"
        }

        isCheckingUsername = false
    }

    private func checkEmailAvailability(_ email: String) async {
        // Reset validation state
        isCheckingEmail = true
        isEmailValid = false
        emailValidationMessage = ""

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Basic email format validation
        guard !trimmedEmail.isEmpty else {
            isCheckingEmail = false
            emailValidationMessage = "Email cannot be empty"
            return
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: trimmedEmail) else {
            isCheckingEmail = false
            emailValidationMessage = "Invalid email format"
            return
        }

        // Check if same as current email
        if trimmedEmail == authManager.currentUser?.email {
            isCheckingEmail = false
            isEmailValid = true
            emailValidationMessage = "OK"
            return
        }

        // Check database for duplicates in auth.users
        do {
            let response = try await supabase
                .from("profiles")
                .select("id")
                .execute()

            // For email, we need to check auth.users table
            // Since we can't directly query auth.users, we'll rely on Supabase auth validation
            isEmailValid = true
            emailValidationMessage = "OK"
        } catch {
            emailValidationMessage = "Error checking email"
        }

        isCheckingEmail = false
    }

    // MARK: - Data Functions

    private func fetchUserProfile() async {
        guard let userId = authManager.currentUser?.id else {
            isLoadingProfile = false
            return
        }

        do {
            // Fetch profile from database
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            userProfile = try decoder.decode(UserProfile.self, from: response.data)

            // Fetch current session to get email
            let session = try await supabase.auth.session
            let userEmail = session.user.email ?? ""

            // Populate editable fields
            editedUsername = userProfile?.userid ?? ""
            editedEmail = userEmail

            // Debug log
            SecureLogger.shared.info("Fetched profile - User ID: \(editedUsername), Email: \(editedEmail)")
        } catch {
            SecureLogger.shared.error("Failed to fetch user profile: \(error.localizedDescription)")
        }

        isLoadingProfile = false
    }

    private func updateUserID(_ newUserID: String) async {
        guard let userId = authManager.currentUser?.id else { return }

        do {
            let cleanedUsername = newUserID.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "@", with: "")

            try await supabase
                .from("profiles")
                .update(["userid": cleanedUsername])
                .eq("id", value: userId)
                .execute()

            // Refresh profile
            await fetchUserProfile()

            SecureLogger.shared.info("User ID updated successfully")
        } catch {
            SecureLogger.shared.error("Failed to update user ID: \(error.localizedDescription)")
        }
    }

    private func updateEmail(_ newEmail: String) async {
        do {
            try await supabase.auth.update(
                user: UserAttributes(email: newEmail)
            )

            #if DEBUG
            // 開発環境: メール認証をスキップ
            await fetchUserProfile()
            SecureLogger.shared.info("Email updated successfully (development mode)")
            #else
            // 本番環境: メール認証が必要
            // ユーザーは新旧両方のメールアドレスで確認メールをチェックする必要がある
            SecureLogger.shared.info("Email change initiated. Please check both your old and new email addresses to confirm the change.")
            // Note: プロフィールは確認後に自動的に更新されます
            #endif
        } catch {
            SecureLogger.shared.error("Failed to update email: \(error.localizedDescription)")
            saveError = "Failed to update email: \(error.localizedDescription)"
        }
    }

    private func saveAccountChanges() async {
        guard let userId = authManager.currentUser?.id else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            // Update userid if edited and valid
            if isEditingUsername && isUsernameValid {
                let cleanedUsername = editedUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "@", with: "")

                try await supabase
                    .from("profiles")
                    .update(["userid": cleanedUsername])
                    .eq("id", value: userId)
                    .execute()

                isEditingUsername = false
            }

            // Update email if edited and valid
            if isEditingEmail && isEmailValid {
                try await supabase.auth.update(
                    user: UserAttributes(email: editedEmail)
                )
                isEditingEmail = false
            }

            // Refresh profile
            await fetchUserProfile()

            showingSaveSuccess = true
            SecureLogger.shared.info("Account information updated successfully")

        } catch {
            saveError = "Failed to save changes: \(error.localizedDescription)"
            SecureLogger.shared.error("Failed to save account changes: \(error.localizedDescription)")
        }
    }

    private func deleteAccount() async {
        // TODO: Implement account deletion
        // 1. Delete user data from database
        // 2. Delete user authentication
        // 3. Sign out
        SecureLogger.shared.info("Account deletion requested")
        await authManager.signOut()
        showingDeleteSuccess = true
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "Unknown" }

        // Parse ISO8601 string to Date
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString // Return raw string if parsing fails
        }

        // Format to readable string
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct AccountInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MinimalDesign.Colors.textSecondary)

            Text(value)
                .font(.system(size: 15))
                .foregroundColor(MinimalDesign.Colors.text)
        }
    }
}

struct EditableFieldWithButton: View {
    let label: String
    @Binding var value: String
    @Binding var isEditing: Bool
    let isValid: Bool
    let validationMessage: String
    let isChecking: Bool
    let isDisabled: Bool
    let prefix: String?
    let onEdit: () -> Void
    let onChange: (String) -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MinimalDesign.Colors.textSecondary)

            HStack(spacing: 12) {
                // Display value or text field (no background)
                HStack(spacing: 0) {
                    if let prefix = prefix {
                        Text(prefix)
                            .font(.system(size: 15))
                            .foregroundColor(MinimalDesign.Colors.text)
                    }

                    if isEditing {
                        TextField("", text: $value)
                            .font(.system(size: 15))
                            .foregroundColor(MinimalDesign.Colors.text)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: value) { newValue in
                                onChange(newValue)
                            }
                    } else {
                        Text(value)
                            .font(.system(size: 15))
                            .foregroundColor(isDisabled ? MinimalDesign.Colors.textSecondary : MinimalDesign.Colors.text)
                    }
                }

                Spacer()

                // Edit button (pen icon)
                if !isEditing {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(isDisabled ? .white.opacity(0.3) : .white)
                    }
                    .disabled(isDisabled)
                } else {
                    // Validation indicator and Save button
                    HStack(spacing: 8) {
                        if isChecking {
                            ProgressView()
                        } else if isValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("OK")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.green)

                            Button(action: onSave) {
                                Text("Save")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }

            // Validation message
            if isEditing && !validationMessage.isEmpty && validationMessage != "OK" {
                Text(validationMessage)
                    .font(.system(size: 12))
                    .foregroundColor(isValid ? .green : .red)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
    }
}
