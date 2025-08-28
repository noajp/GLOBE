//======================================================================
// MARK: - EditProfileView.swift
// Purpose: Custom profile editing interface
// Path: GLOBE/Views/EditProfileView.swift
//======================================================================
import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MyPageViewModel()
    @StateObject private var authManager = AuthManager.shared
    
    @State private var displayName = ""
    @State private var bio = ""
    @State private var userId = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    // Input limits
    private let maxDisplayNameLength = 30
    private let maxBioLength = 150
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: MinimalDesign.Spacing.lg) {
                    // Profile Image Section
                    VStack(spacing: MinimalDesign.Spacing.md) {
                        let avatarUrl = viewModel.userProfile?.avatarUrl
                        
                        PhotosPicker(selection: $selectedPhotoItem,
                                   matching: .images,
                                   photoLibrary: .shared()) {
                            if let avatarUrl = avatarUrl,
                               let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    profilePlaceholder
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                profilePlaceholder
                                    .frame(width: 100, height: 100)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button("Change Photo") {
                            // PhotosPicker will handle this
                        }
                        .font(MinimalDesign.Typography.body)
                        .foregroundColor(MinimalDesign.Colors.accent)
                    }
                    
                    // User ID Display (Read-only)
                    VStack(alignment: .leading, spacing: MinimalDesign.Spacing.xs) {
                        Text("User ID")
                            .font(MinimalDesign.Typography.caption)
                            .foregroundColor(MinimalDesign.Colors.secondary)
                        
                        Text(userId.isEmpty ? "Loading..." : String(userId.prefix(8)))
                            .font(MinimalDesign.Typography.body)
                            .foregroundColor(MinimalDesign.Colors.tertiary)
                            .padding(MinimalDesign.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(MinimalDesign.Colors.secondaryBackground.opacity(0.5))
                            .cornerRadius(MinimalDesign.Radius.sm)
                    }
                    .padding(.horizontal, MinimalDesign.Spacing.md)
                    
                    // Form Fields
                    VStack(spacing: MinimalDesign.Spacing.md) {
                        // Display Name Field
                        VStack(alignment: .leading, spacing: MinimalDesign.Spacing.xs) {
                            HStack {
                                Text("Display Name")
                                    .font(MinimalDesign.Typography.caption)
                                    .foregroundColor(MinimalDesign.Colors.secondary)
                                Spacer()
                                Text("\(displayName.count)/\(maxDisplayNameLength)")
                                    .font(MinimalDesign.Typography.caption)
                                    .foregroundColor(displayName.count > maxDisplayNameLength ? .red : MinimalDesign.Colors.tertiary)
                            }
                            
                            TextField("Enter display name", text: $displayName)
                                .onChange(of: displayName) { _, newValue in
                                    if newValue.count > maxDisplayNameLength {
                                        displayName = String(newValue.prefix(maxDisplayNameLength))
                                    }
                                }
                                .padding(MinimalDesign.Spacing.sm)
                                .background(MinimalDesign.Colors.secondaryBackground)
                                .cornerRadius(MinimalDesign.Radius.sm)
                                .foregroundColor(MinimalDesign.Colors.primary)
                        }
                        
                        // Bio Field
                        VStack(alignment: .leading, spacing: MinimalDesign.Spacing.xs) {
                            HStack {
                                Text("Bio")
                                    .font(MinimalDesign.Typography.caption)
                                    .foregroundColor(MinimalDesign.Colors.secondary)
                                Spacer()
                                Text("\(bio.count)/\(maxBioLength)")
                                    .font(MinimalDesign.Typography.caption)
                                    .foregroundColor(bio.count > maxBioLength ? .red : MinimalDesign.Colors.tertiary)
                            }
                            
                            TextEditor(text: $bio)
                                .onChange(of: bio) { _, newValue in
                                    if newValue.count > maxBioLength {
                                        bio = String(newValue.prefix(maxBioLength))
                                    }
                                }
                                .frame(height: 100)
                                .padding(MinimalDesign.Spacing.sm)
                                .background(MinimalDesign.Colors.secondaryBackground)
                                .cornerRadius(MinimalDesign.Radius.sm)
                                .foregroundColor(MinimalDesign.Colors.primary)
                                .scrollContentBackground(.hidden)
                        }
                    }
                    .padding(.horizontal, MinimalDesign.Spacing.md)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top, MinimalDesign.Spacing.lg)
            }
            .background(MinimalDesign.Colors.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MinimalDesign.Colors.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .foregroundColor(MinimalDesign.Colors.accent)
                    .disabled(isLoading || displayName.isEmpty)
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Profile updated successfully")
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                }
            }
        }
    }
    
    private var profilePlaceholder: some View {
        Circle()
            .fill(MinimalDesign.Colors.secondary)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(MinimalDesign.Colors.tertiary)
                    .font(.system(size: 40))
            )
    }
    
    private func loadCurrentProfile() {
        Task {
            await viewModel.loadUserData()
            
            if let profile = viewModel.userProfile {
                displayName = profile.displayName ?? profile.username
                bio = profile.bio ?? ""
                userId = profile.id
            }
        }
    }
    
    private func saveProfile() async {
        // Input validation
        guard validateInputs() else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // Keep the existing username, only update display name and bio
        let currentUsername = viewModel.userProfile?.username ?? "user"
        
        await viewModel.updateProfile(
            username: currentUsername,  // Keep existing username
            displayName: displayName,
            bio: bio
        )
        
        if let error = viewModel.errorMessage, !error.isEmpty {
            errorMessage = error
            showError = true
        } else {
            showSuccess = true
        }
    }
    
    private func validateInputs() -> Bool {
        // Display name validation
        if displayName.isEmpty {
            errorMessage = "Please enter a display name"
            showError = true
            return false
        }
        
        if displayName.count < 2 {
            errorMessage = "Display name must be at least 2 characters"
            showError = true
            return false
        }
        
        return true
    }
}