import SwiftUI

struct ProfileViewWithStories: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var postManager = PostManager.shared
    @StateObject private var followService = FollowService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditProfile = false
    @State private var userPosts: [Post] = []

    @State private var stories: [Story] = Story.mockStories
    @State private var showingCreatePost = false
    @State private var showUserSearch = false
    @State private var showNotifications = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Custom style header
                    profileHeader
                    
                    // Modern profile section
                    ProfileSection(
                        authManager: authManager,
                        postManager: postManager,
                        onEdit: { showingEditProfile = true }
                    )
                    
                    // Content area - Posts only
                    postsSection
                    
                    // Bottom padding
                    Color.clear
                        .frame(height: 110)
                }
            }
            .background(MinimalDesign.Colors.background)
            .navigationBarHidden(true)
            .onAppear { loadUserPosts() }
            .navigationDestination(isPresented: $showingEditProfile) {
                EditProfileView()
            }
        }
        .sheet(isPresented: $showingCreatePost) {
            CreatePostView(isPresented: $showingCreatePost, mapManager: MapManager())
        }
        .fullScreenCover(isPresented: $showUserSearch) {
            UserSearchView()
        }
        .fullScreenCover(isPresented: $showNotifications) {
            NotificationsView()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Custom Style Profile Header
    private var profileHeader: some View {
        HStack {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(MinimalDesign.Colors.primary)
            }
            
            // Title
            Text("PROFILE")
                .font(MinimalDesign.Typography.title)
                .foregroundColor(MinimalDesign.Colors.primary)
                .fontWeight(.bold)
            
            Spacer()
            
            // Right buttons
            HStack(spacing: 12) {
                // Search button
                Button(action: {
                    showUserSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(MinimalDesign.Colors.primary)
                }
                .frame(width: 36, height: 36)
                
                // Notification bell button
                Button(action: {
                    showNotifications = true
                }) {
                    Image(systemName: "bell")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(MinimalDesign.Colors.primary)
                }
                .frame(width: 36, height: 36)
                
                // Settings button (three lines)
                Button(action: {
                    showSettings = true
                }) {
                    VStack(spacing: 5) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(MinimalDesign.Colors.primary)
                                .frame(width: 22, height: 1.5)
                        }
                    }
                }
                .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, MinimalDesign.Spacing.md)
        .padding(.vertical, MinimalDesign.Spacing.sm)
        .frame(height: 44)
        .background(MinimalDesign.Colors.background)
    }
    
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if userPosts.isEmpty {
                emptyPostsView
            } else {
                postsGrid
            }
        }
    }
    
    private var followersSection: some View {
        VStack(spacing: 12) {
            if followService.followers.isEmpty {
                Text("フォロワーはまだいません")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            } else {
                ForEach(Array(followService.followers), id: \.self) { userId in
                    UserRow(userId: userId, isFollowing: followService.isFollowing(userId))
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var followingSection: some View {
        VStack(spacing: 12) {
            if followService.following.isEmpty {
                Text("まだ誰もフォローしていません")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            } else {
                ForEach(Array(followService.following), id: \.self) { userId in
                    UserRow(userId: userId, isFollowing: true)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var storiesSection: some View {
        VStack(spacing: 16) {
            // Create story button
            Button(action: {
                showingCreatePost = true
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text("ストーリーを作成")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Stories grid
            if stories.isEmpty {
                Text("ストーリーはありません")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                    ForEach(stories) { story in
                        StoryGridItem(story: story)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var notificationsSection: some View {
        VStack(spacing: 12) {
            Text("通知")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // Mock notifications
            ForEach(0..<5, id: \.self) { index in
                NotificationRow(
                    title: "新しいフォロワー",
                    message: "田中太郎があなたをフォローしました",
                    time: "2時間前"
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyPostsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("まだ投稿がありません")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("地球上のどこかで最初の投稿をしてみましょう！")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    private var postsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
            ForEach(userPosts) { post in
                PostCard(post: post)
            }
        }
        .padding(.top, 16)
    }
    
    private var profileBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color(red: 0.05, green: 0.1, blue: 0.2),
                Color.black
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func loadUserPosts() {
        guard let userId = authManager.currentUser?.id else { return }
        userPosts = postManager.posts.filter { $0.authorId == userId }
    }
}

// TabButton moved to TabSelection.swift

struct StoryGridItem: View {
    let story: Story
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    VStack {
                        Text(story.userName.prefix(1))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(story.userName)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// NotificationRow moved to NotificationsView.swift

#Preview {
    ProfileViewWithStories()
}
