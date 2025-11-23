//======================================================================
// MARK: - ProfileEditView.swift
// Purpose: Profile editing screen for user information
// Path: GLOBE/Views/Profile/ProfileEditView.swift
//======================================================================

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MyPageViewModel()

    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Black background
            Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Profile Photo Section
                    VStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                // Avatar
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Group {
                                            if let photoData = selectedPhotoData,
                                               let uiImage = UIImage(data: photoData) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(Circle())
                                            } else if let avatarUrl = viewModel.userProfile?.avatarUrl,
                                                      let url = URL(string: avatarUrl) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 100, height: 100)
                                                        .clipShape(Circle())
                                                } placeholder: {
                                                    Text(displayName.prefix(1).uppercased())
                                                        .font(.system(size: 36, weight: .bold))
                                                        .foregroundColor(.white.opacity(0.7))
                                                }
                                            } else {
                                                Text(displayName.prefix(1).uppercased())
                                                    .font(.system(size: 36, weight: .bold))
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                    )

                                // Edit icon badge
                                Circle()
                                    .fill(Color(red: 0.0, green: 0.55, blue: 0.75))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0), lineWidth: 3)
                                    )
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task { @MainActor in
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedPhotoData = data
                                }
                            }
                        }

                        Text("Change Profile Photo")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // Display Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        TextField("Display name", text: $displayName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Bio Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $bio)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(height: 100)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)

                            if bio.isEmpty {
                                Text("Tell us about yourself...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.3))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
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
                    .background(Color(red: 0.0, green: 0.55, blue: 0.75))
                    .cornerRadius(10)
                    .disabled(isLoading)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            SecureLogger.shared.info("ProfileEditView: onAppear - loading user data")
            loadUserData()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func loadUserData() {
        Task {
            SecureLogger.shared.info("ProfileEditView: loadUserData - starting")
            await viewModel.loadUserData()
            displayName = viewModel.userProfile?.displayName ?? ""
            bio = viewModel.userProfile?.bio ?? ""
            SecureLogger.shared.info("ProfileEditView: loadUserData - loaded displayName=\(displayName), bio=\(bio)")
        }
    }

    private func saveProfile() {
        guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Display name cannot be empty"
            showError = true
            return
        }

        SecureLogger.shared.info("ProfileEditView: Saving profile - displayName=\(displayName), bio=\(bio)")
        isLoading = true

        Task {
            // Upload avatar if changed
            if let photoData = selectedPhotoData {
                SecureLogger.shared.info("ProfileEditView: Uploading avatar")
                await viewModel.updateAvatar(imageData: photoData)
            }

            // Update profile info
            SecureLogger.shared.info("ProfileEditView: Updating profile with displayName=\(displayName)")
            await viewModel.updateProfile(displayName: displayName, bio: bio)

            if let error = viewModel.errorMessage {
                SecureLogger.shared.error("ProfileEditView: Update failed - \(error)")
                errorMessage = error
                showError = true
                isLoading = false
            } else {
                SecureLogger.shared.info("ProfileEditView: Update successful, dismissing")
                isLoading = false
                // Dismiss screen after successful save
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileEditView()
    }
}
