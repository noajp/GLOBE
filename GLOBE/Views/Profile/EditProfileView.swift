//======================================================================
// MARK: - EditProfileView.swift
// Purpose: Custom profile editing interface
// Path: GLOBE/Views/EditProfileView.swift
//======================================================================
import SwiftUI
import PhotosUI
import UIKit

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
    // Success popup is not shown per request; dismiss after save instead
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var localAvatarImage: UIImage?
    
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
                            Group {
                                if let image = localAvatarImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else if let avatarUrl = avatarUrl, let url = URL(string: avatarUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        profilePlaceholder
                                    }
                                } else {
                                    profilePlaceholder
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            Text("Change Photo")
                                .font(MinimalDesign.Typography.body)
                                .foregroundColor(MinimalDesign.Colors.accent)
                        }
                        .buttonStyle(PlainButtonStyle())
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
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let item = newItem else { return }
                Task { @MainActor in
                    do {
                        if let data = try await item.loadTransferable(type: Data.self) {
                            if let ui = UIImage(data: data) {
                                localAvatarImage = ui
                            }
                            await viewModel.updateAvatar(imageData: data)
                        }
                    } catch {
                        errorMessage = "Failed to load selected image"
                        showError = true
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            // Success popup removed: we dismiss on successful save
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
                displayName = profile.displayName ?? ""
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

        await viewModel.updateProfile(
            displayName: displayName,
            bio: bio
        )
        
        if let error = viewModel.errorMessage, !error.isEmpty {
            errorMessage = error
            showError = true
        } else {
            // Do not show success popup; close the screen silently
            dismiss()
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
