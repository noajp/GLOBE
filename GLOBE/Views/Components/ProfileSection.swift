//======================================================================
// MARK: - ProfileSection.swift
// Purpose: Custom profile section component for GLOBE app
// Path: GLOBE/Core/Components/ProfileSection.swift
//======================================================================
import SwiftUI

// MARK: - Custom Style Profile Section
struct ProfileSection: View {
    // MARK: - Properties
    let authManager: AuthManager
    let postManager: PostManager
    var onEdit: () -> Void = {}
    
    var body: some View {
        VStack(spacing: MinimalDesign.Spacing.lg) {
            // Profile Header
            HStack(spacing: MinimalDesign.Spacing.md) {
                // Profile Image
                AsyncImage(url: URL(string: "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(MinimalDesign.Colors.secondary)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(MinimalDesign.Colors.tertiary)
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                
                Spacer()
                
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
            
            // User Info
            VStack(alignment: .leading, spacing: MinimalDesign.Spacing.xs) {
                if let user = authManager.currentUser {
                    Text(user.email ?? "Unknown User")
                        .font(MinimalDesign.Typography.headline)
                        .foregroundColor(MinimalDesign.Colors.primary)

                    Text("Bio goes here...")
                        .font(MinimalDesign.Typography.body)
                        .foregroundColor(MinimalDesign.Colors.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MinimalDesign.Spacing.md)
            
            // Action Buttons - Edit Profileのみ表示
            HStack(spacing: MinimalDesign.Spacing.sm) {
                Button("Edit Profile") { onEdit() }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MinimalDesign.Spacing.sm)
                .background(MinimalDesign.Colors.secondary)
                .foregroundColor(MinimalDesign.Colors.primary)
                .cornerRadius(MinimalDesign.Radius.sm)
                
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
        }
        .padding(.vertical, MinimalDesign.Spacing.md)
        .background(MinimalDesign.Colors.background)
    }
}

