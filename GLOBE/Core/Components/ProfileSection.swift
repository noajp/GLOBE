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
                
                // Stats
                HStack(spacing: MinimalDesign.Spacing.lg) {
                    StatItem(value: postManager.posts.count, label: "Posts")
                    StatItem(value: 156, label: "Followers")  
                    StatItem(value: 89, label: "Following")
                }
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
            
            // User Info
            VStack(alignment: .leading, spacing: MinimalDesign.Spacing.xs) {
                if let user = authManager.currentUser {
                    Text(user.username ?? "Unknown")
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
            
            // Action Buttons
            HStack(spacing: MinimalDesign.Spacing.sm) {
                Button("Edit Profile") {
                    // Edit profile action
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MinimalDesign.Spacing.sm)
                .background(MinimalDesign.Colors.secondary)
                .foregroundColor(MinimalDesign.Colors.primary)
                .cornerRadius(MinimalDesign.Radius.sm)
                
                Button("Share Profile") {
                    // Share profile action
                }
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

// MARK: - Helper Views

struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: MinimalDesign.Spacing.xs) {
            Text("\(value)")
                .font(MinimalDesign.Typography.headline)
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Text(label)
                .font(MinimalDesign.Typography.caption)
                .foregroundColor(MinimalDesign.Colors.tertiary)
        }
    }
}