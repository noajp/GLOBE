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
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var isDeleting = false
    @State private var userProfile: UserProfile?
    @State private var isLoadingProfile = true
    @State private var editedUsername = ""

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
            }
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
        .alert("Delete Failed", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
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
                if isDeleting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                } else {
                    Text("Delete Account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .background(isDeleting ? Color.gray : MinimalDesign.Colors.accentRed)
            .cornerRadius(8)
            .disabled(isDeleting)
        }
    }

    // MARK: - Data Functions

    private func fetchUserProfile() async {
        guard let userId = authManager.currentUser?.id else {
            isLoadingProfile = false
            return
        }

        do {
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            userProfile = try decoder.decode(UserProfile.self, from: response.data)
            editedUsername = userProfile?.userid ?? ""

            SecureLogger.shared.info("Fetched profile - User ID: \(editedUsername)")
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

    private func deleteAccount() async {
        isDeleting = true

        guard let userId = authManager.currentUser?.id else {
            SecureLogger.shared.error("Account deletion failed: No authenticated user")
            deleteErrorMessage = "Not authenticated. Please sign in again."
            showingDeleteError = true
            isDeleting = false
            return
        }

        SecureLogger.shared.info("Account deletion requested for user: \(userId)")

        do {
            // Delete in order of dependencies using direct queries
            // RLS policies ensure user can only delete their own data

            // 1. Delete notifications (where user is recipient or actor)
            try await supabase
                .from("notifications")
                .delete()
                .or("recipient_id.eq.\(userId),actor_id.eq.\(userId)")
                .execute()

            // 2. Delete likes by user
            try await supabase
                .from("likes")
                .delete()
                .eq("user_id", value: userId)
                .execute()

            // 3. Delete comments by user
            try await supabase
                .from("comments")
                .delete()
                .eq("user_id", value: userId)
                .execute()

            // 4. Delete follows (both directions)
            try await supabase
                .from("follows")
                .delete()
                .or("follower_id.eq.\(userId),following_id.eq.\(userId)")
                .execute()

            // 5. Get user's post IDs first
            let postsResponse = try await supabase
                .from("posts")
                .select("id")
                .eq("user_id", value: userId)
                .execute()

            struct PostId: Decodable { let id: String }
            let postIds = (try? JSONDecoder().decode([PostId].self, from: postsResponse.data))?.map { $0.id } ?? []

            // 6. Delete likes and comments on user's posts
            for postId in postIds {
                try await supabase.from("likes").delete().eq("post_id", value: postId).execute()
                try await supabase.from("comments").delete().eq("post_id", value: postId).execute()
                try await supabase.from("notifications").delete().eq("post_id", value: postId).execute()
            }

            // 7. Delete user's posts
            try await supabase
                .from("posts")
                .delete()
                .eq("user_id", value: userId)
                .execute()

            // 8. Delete profile
            try await supabase
                .from("profiles")
                .delete()
                .eq("id", value: userId)
                .execute()

            SecureLogger.shared.info("User data deleted from database")

            // 9. Sign out (this clears local session)
            await authManager.signOut()

            // 10. Show success
            showingDeleteSuccess = true
            SecureLogger.shared.info("Account deletion completed successfully")

        } catch {
            SecureLogger.shared.error("Account deletion failed: \(error.localizedDescription)")
            deleteErrorMessage = "Failed to delete account. Please try again."
            showingDeleteError = true
        }

        isDeleting = false
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

#Preview {
    NavigationStack {
        AccountSettingsView()
    }
}
