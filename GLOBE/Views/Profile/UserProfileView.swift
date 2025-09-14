//======================================================================
// MARK: - UserProfileView.swift
// Purpose: User profile view for displaying other users' information
// Path: GLOBE/Views/UserProfileView.swift
//======================================================================

import SwiftUI
import Supabase

struct UserProfileView: View {
    let userName: String
    let userId: String
    @Binding var isPresented: Bool
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @StateObject private var postManager = PostManager.shared
    @ObservedObject private var authManager = AuthManager.shared
    
    // 現在のユーザーかどうか
    private var isCurrentUser: Bool {
        return userId == authManager.currentUser?.id
    }
    
    // このユーザーの投稿を取得
    private var userPosts: [Post] {
        return postManager.posts.filter { $0.userId == userId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Unified header at the very top
            UnifiedHeader(
                title: "PROFILE",
                showBackButton: true,
                onBack: {
                    isPresented = false
                }
            )
            .padding(.top) // Add top safe area padding
            
            // Profile content in scrollview
            ScrollView(showsIndicators: false) {
                profileContent
            }
            .background(MinimalDesign.Colors.background)
        }
        .background(MinimalDesign.Colors.background)
        .onAppear {
            Task {
                await loadUserProfile()
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(MinimalDesign.Colors.background.opacity(0.8))
            }
        }
    }
    
    
    // MARK: - Profile Content
    private var profileContent: some View {
        LazyVStack(spacing: 0) {
            // Profile Section
            profileSection
            
            // Posts Grid
            postsGrid
            
            // Bottom padding for tab bar
            Color.clear
                .frame(height: 110)
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Profile Image
                profileImage
                
                // Profile Info
                VStack(alignment: .leading, spacing: 8) {
                    // Display Name
                    if let profile = userProfile {
                        if let displayName = profile.displayName, !displayName.isEmpty {
                            Text(displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(MinimalDesign.Colors.primary)
                                .lineLimit(1)
                        } else {
                            Text(profile.username)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(MinimalDesign.Colors.primary)
                                .lineLimit(1)
                        }
                        
                        // User ID
                        Text("ID: \(profile.id.prefix(8))")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(MinimalDesign.Colors.tertiary)
                            .lineLimit(1)
                    } else if !isLoading {
                        // Fallback to passed parameters if profile not loaded
                        Text(userName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .lineLimit(1)
                        
                        Text("ID: \(userId.prefix(8))")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(MinimalDesign.Colors.tertiary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Follow Button (if not current user)
                    if !isCurrentUser {
                        Button(action: {
                            // Follow action
                        }) {
                            Text("Follow")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(MinimalDesign.Colors.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            
            // Stats Section
            HStack(spacing: 32) {
                StatItem(value: userProfile?.postCount ?? userPosts.count, label: "Posts")
                StatItem(value: userProfile?.followerCount ?? 0, label: "Followers")
                StatItem(value: userProfile?.followingCount ?? 0, label: "Following")
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            
            // Bio Section
            if let profile = userProfile, let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, MinimalDesign.Spacing.sm)
            }
        }
        .padding(.top, MinimalDesign.Spacing.sm)
        .padding(.bottom, MinimalDesign.Spacing.md)
    }
    
    // MARK: - Profile Image
    private var profileImage: some View {
        let avatarUrl = userProfile?.avatarUrl
        let displayName = userProfile?.displayName ?? userProfile?.username ?? userName
        
        return Group {
            if let avatarUrl = avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    profilePlaceholder(for: displayName)
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
            } else {
                profilePlaceholder(for: displayName)
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
            }
        }
    }
    
    private func profilePlaceholder(for name: String) -> some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Text(name.prefix(1).uppercased())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    // MARK: - Posts Grid
    private var postsGrid: some View {
        Group {
            if userPosts.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ], spacing: 2) {
                    ForEach(userPosts) { post in
                        PostGridItem(post: post, selectedPost: .constant(nil))
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera")
                .font(.system(size: 48))
                .foregroundColor(MinimalDesign.Colors.tertiary)
            
            Text("No Posts Yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(MinimalDesign.Colors.primary)
            
            if isCurrentUser {
                Text("Share your first photo to get started")
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.secondary)
            } else {
                Text("\(userName) hasn't shared any posts yet")
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.secondary)
            }
        }
        .frame(height: 300)
    }
    
    // MARK: - Data Loading
    
    private func loadUserProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // プロフィールデータを取得
            let profileData = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
            
            let decoder = JSONDecoder()
            let profiles = try decoder.decode([UserProfile].self, from: profileData.data)
            
            if let profile = profiles.first {
                await MainActor.run {
                    userProfile = profile
                }
                print("✅ UserProfileView: Profile loaded for \(profile.username)")
            } else {
                await MainActor.run {
                    errorMessage = "プロフィールが見つかりませんでした"
                }
                print("❌ UserProfileView: Profile not found for userId: \(userId)")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "プロフィールの読み込みに失敗しました: \(error.localizedDescription)"
            }
            print("❌ UserProfileView: Failed to load profile: \(error)")
        }
    }
}



#Preview {
    UserProfileView(
        userName: "John Doe", 
        userId: "12345678", 
        isPresented: .constant(true)
    )
}