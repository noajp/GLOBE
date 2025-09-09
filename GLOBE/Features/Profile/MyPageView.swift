//======================================================================
// MARK: - MyPageView.swift
// Purpose: Main profile view with header and content
// Path: GLOBE/Features/Profile/MyPageView.swift
//======================================================================
import SwiftUI
// PhotosUI not needed here (avatar changes only in EditProfileView)

struct MyPageView: View {
    // MARK: - Properties
    @StateObject private var viewModel = MyPageViewModel()
    @StateObject private var authManager = AuthManager.shared
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showUserSearch = false
    // Avatar changes are handled only in EditProfileView (no picker here)
    @State private var selectedPost: Post?
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Unified header at the very top
            UnifiedHeader(
                title: "PROFILE",
                showBackButton: true,
                rightButton: HeaderButton(icon: "custom.three.lines") {
                    showSettings = true
                },
                extraRightButton: HeaderButton(icon: "magnifyingglass") {
                    showUserSearch = true
                },
                onBack: {
                    dismiss()
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
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showUserSearch) {
            UserSearchView()
        }
    }
    
    
    // MARK: - Profile Content
    private var profileContent: some View {
        LazyVStack(spacing: 0) {
            // Profile Section
            profileSection
            // Stories (followed users)
            storiesSection
            
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
                    if let displayName = viewModel.userProfile?.displayName, !displayName.isEmpty {
                        Text(displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .lineLimit(1)
                    } else if let username = viewModel.userProfile?.username {
                        Text(username)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .lineLimit(1)
                    }
                    
                    // User ID
                    if let userId = viewModel.userProfile?.id {
                        Text("ID: \(userId.prefix(8))")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(MinimalDesign.Colors.tertiary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Edit Profile Button
                    Button(action: {
                        showEditProfile = true
                    }) {
                        Text("Edit Profile")
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            
            // Stats Section
            HStack(spacing: 32) {
                StatItem(value: viewModel.postsCount, label: "Posts")
                StatItem(value: viewModel.followersCount, label: "Followers")
                StatItem(value: viewModel.followingCount, label: "Following")
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            
            // Bio Section
            if let bio = viewModel.userProfile?.bio, !bio.isEmpty {
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
        let userProfile = viewModel.userProfile
        let avatarUrl = userProfile?.avatarUrl

        return Group {
            if let avatarUrl = avatarUrl, let url = URL(string: avatarUrl) {
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
        .frame(width: 70, height: 70)
        .clipShape(Circle())
    }

    // MARK: - Stories Section
    private var storiesSection: some View {
        Group {
            if !viewModel.stories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Stories")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.primary)
                        Spacer()
                    }
                    StoriesView(stories: viewModel.stories) {
                        // 通知でメイン画面に投稿ポップアップを出す
                        NotificationCenter.default.post(name: Notification.Name("PostAtCurrentLocation"), object: nil)
                        dismiss()
                    }
                }
                .padding(.vertical, MinimalDesign.Spacing.sm)
            }
        }
    }
    
    private var profilePlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "person.fill")
                .font(.system(size: 30))
                .foregroundColor(.gray.opacity(0.5))
        }
    }
    
    // MARK: - Posts Grid
    private var postsGrid: some View {
        Group {
            if viewModel.userPosts.filter({ $0.imageUrl != nil || $0.imageData != nil }).isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ], spacing: 2) {
                    ForEach(viewModel.userPosts.filter { $0.imageUrl != nil || $0.imageData != nil }) { post in
                        PostGridItem(post: post, selectedPost: $selectedPost)
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
            
            Text("Share your first photo to get started")
                .font(.system(size: 14))
                .foregroundColor(MinimalDesign.Colors.secondary)
        }
        .frame(height: 300)
    }
}

// MARK: - Supporting Views
struct PostGridItem: View {
    let post: Post
    @Binding var selectedPost: Post?
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                selectedPost = post
            }) {
                if let imageUrl = post.imageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: { Color.clear }
                } else if let data = post.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // No photo: do not render a placeholder item
                    EmptyView()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
