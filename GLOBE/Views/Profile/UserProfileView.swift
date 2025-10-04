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
                    .background(.ultraThinMaterial.opacity(0.8))
            }
        }
    }
    
    
    // MARK: - Profile Content
    private var profileContent: some View {
        LazyVStack(spacing: 16) {
            // Profile Section
            profileSection

            // Bottom padding for tab bar
            Color.clear
                .frame(height: 110)
        }
        .background(Color.clear)
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

                            // User ID with @ prefix
                            Text("@\(profile.id.prefix(8))")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(MinimalDesign.Colors.secondary)
                                .lineLimit(1)
                        } else if !isLoading {
                            // Fallback to passed parameters if profile not loaded
                            Text(userName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text("ID: \(userId.prefix(8))")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        // Follow Button (if not current user) with glass effect
                        if !isCurrentUser {
                            followButtonWithGlass
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Stats Section
                statsSection

                // Bio Section
                if let profile = userProfile, let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        .padding(.horizontal, 16)
        .padding(.top, MinimalDesign.Spacing.sm)
    }
    
    // MARK: - Profile Image with Glass Effect
    private var profileImageWithGlass: some View {
        let avatarUrl = userProfile?.avatarUrl
        let displayName = userProfile?.displayName ?? userProfile?.username ?? userName

        return ZStack {
            // Glass backdrop
            Circle()
                .fill(.ultraThinMaterial.opacity(0.3))
                .frame(width: 78, height: 78)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )

            // Profile image content
            Group {
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
    }

    // MARK: - Profile Image (Legacy)
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

    // MARK: - Follow Button with Glass Effect
    private var followButtonWithGlass: some View {
        Button(action: {
            // Follow action
        }) {
            Text("Follow")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Stats with Glass Effect
    private var statsSection: some View {
        HStack(spacing: 16) {
            statItem(count: userPosts.count, label: "投稿")
            statItem(count: userProfile?.followingCount ?? 0, label: "フォロー中")
            statItem(count: userProfile?.followerCount ?? 0, label: "フォロワー")
        }
        .frame(maxWidth: .infinity)
    }

    private func statItem(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(MinimalDesign.Colors.primary)
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MinimalDesign.Colors.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statsWithGlass: some View {
        HStack(spacing: 32) {
            GlassStatItem(value: userProfile?.postCount ?? userPosts.count, label: "Posts")
            GlassStatItem(value: userProfile?.followerCount ?? 0, label: "Followers")
            GlassStatItem(value: userProfile?.followingCount ?? 0, label: "Following")
        }
    }
    
    // MARK: - Posts Grid
    private var postsGrid: some View {
        Group {
            if userPosts.isEmpty {
                emptyStateWithGlass
            } else {
                LiquidGlassCard(
                    id: "posts-grid-\(userId)",
                    cornerRadius: 20,
                    tint: Color.white.opacity(0.02),
                    strokeColor: Color.white.opacity(0.1),
                    highlightColor: Color.white.opacity(0.2),
                    contentPadding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
                    contentBackdropOpacity: 0.03,
                    shadowColor: Color.black.opacity(0.05),
                    shadowRadius: 6,
                    shadowOffsetY: 2
                ) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(userPosts) { post in
                            PostGridItemWithGlass(post: post, selectedPost: .constant(nil))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
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

    private var emptyStateWithGlass: some View {
        LiquidGlassCard(
            id: "empty-state-\(userId)",
            cornerRadius: 20,
            tint: Color.white.opacity(0.02),
            strokeColor: Color.white.opacity(0.1),
            highlightColor: Color.white.opacity(0.2),
            contentPadding: EdgeInsets(top: 40, leading: 20, bottom: 40, trailing: 20),
            contentBackdropOpacity: 0.03
        ) {
            VStack(spacing: 16) {
                Image(systemName: "camera")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.6))

                Text("No Posts Yet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)

                if isCurrentUser {
                    Text("Share your first photo to get started")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("\(userName) hasn't shared any posts yet")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
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

// MARK: - Supporting Components

struct GlassStatItem: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct PostGridItemWithGlass: View {
    let post: Post
    @Binding var selectedPost: Post?

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial.opacity(0.4))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                VStack(spacing: 4) {
                    if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        Text(post.text.prefix(15))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .cornerRadius(12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.3)
            )
            .onTapGesture {
                selectedPost = post
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