//======================================================================
// MARK: - ProfileEditView.swift
// Purpose: Profile editing screen for user information
// Path: GLOBE/Views/Profile/ProfileEditView.swift
//======================================================================

import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MyPageViewModel()

    @State private var displayName: String = ""
    @State private var bio: String = ""

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

                    // Bio Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.secondary)

                        TextEditor(text: $bio)
                            .font(.system(size: 16))
                            .frame(height: 100)
                            .padding(4)
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                            )
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
        Task {
            await viewModel.loadUserData()
            displayName = viewModel.userProfile?.displayName ?? ""
            bio = viewModel.userProfile?.bio ?? ""
        }
    }

    private func saveProfile() {
        guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Display name cannot be empty"
            showError = true
            return
        }

        isLoading = true

        Task {
            await viewModel.updateProfile(displayName: displayName, bio: bio)

            if let error = viewModel.errorMessage {
                errorMessage = error
                showError = true
                isLoading = false
            } else {
                isLoading = false
                showSuccessAlert = true
            }
        }
    }
}

#Preview {
    ProfileEditView()
}
