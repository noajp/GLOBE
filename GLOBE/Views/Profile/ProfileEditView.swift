//======================================================================
// MARK: - ProfileEditView.swift
// Purpose: Profile editing screen for user information
// Path: GLOBE/Views/Profile/ProfileEditView.swift
//======================================================================

import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared

    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var email: String = ""

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false

    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // User ID Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("User ID")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.secondary)

                        TextField("Username", text: $username)
                            .font(.system(size: 16))
                            .padding()
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                            )
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }

                    // Display Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.secondary)

                        TextField("Display name", text: $displayName)
                            .font(.system(size: 16))
                            .padding()
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                            )
                    }

                    // Email Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.secondary)

                        TextField("Email address", text: $email)
                            .font(.system(size: 16))
                            .padding()
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }

                    // Save Button
                    Button(action: saveProfile) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(MinimalDesign.Colors.accentRed)
                    .cornerRadius(10)
                    .disabled(isLoading)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserData()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been updated successfully.")
        }
    }

    private func loadUserData() {
        if let user = authManager.currentUser {
            username = user.username ?? ""
            email = user.email ?? ""
            // displayName is not in AppUser, would need to fetch from profiles table
            displayName = user.username ?? ""
        }
    }

    private func saveProfile() {
        guard !username.isEmpty else {
            errorMessage = "Username cannot be empty"
            showError = true
            return
        }

        guard !email.isEmpty else {
            errorMessage = "Email cannot be empty"
            showError = true
            return
        }

        isLoading = true

        // TODO: Implement actual profile update with Supabase
        // For now, just show success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            showSuccessAlert = true
        }
    }
}

#Preview {
    ProfileEditView()
}
