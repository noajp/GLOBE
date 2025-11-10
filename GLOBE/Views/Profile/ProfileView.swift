//======================================================================
// MARK: - ProfileView.swift
// Purpose: Instagram-style profile view with photo grid
// Path: GLOBE/Views/Profile/ProfileView.swift
//======================================================================

import SwiftUI

struct ProfileView: View {
    let userId: String? // If nil, shows current user's profile

    @StateObject private var viewModel = MyPageViewModel()
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedPost: Post?
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingAuth = false
    @State private var isFollowing = false
    @State private var isLoadingFollow = false

    // Grid layout configuration
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    init(userId: String? = nil) {
        self.userId = userId
    }

    var body: some View {
        ZStack {
            // Background layer (solid black #121212)
            Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0)
                .ignoresSafeArea()

            // Content layer
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    ProfileHeaderView(
                        userProfile: viewModel.userProfile,
                        postsCount: photoPosts.count,
                        followersCount: viewModel.followersCount,
                        followingCount: viewModel.followingCount,
                        isOwnProfile: isOwnProfile,
                        isFollowing: isFollowing,
                        isLoadingFollow: isLoadingFollow,
                        onEditProfile: {
                            showingEditProfile = true
                        },
                        onFollowToggle: {
                            Task {
                                await toggleFollow()
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // Photo Grid
                    if photoPosts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.5))

                            Text("No Photos Yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            Text("Share photos to see them here")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(photoPosts) { post in
                                PhotoGridItem(post: post)
                                    .onTapGesture {
                                        selectedPost = post
                                    }
                            }
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadProfile()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView(isPresented: $showingSettings, showingAuth: $showingAuth)) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            NavigationStack {
                ProfileEditView()
            }
        }
        .sheet(item: $selectedPost) { post in
            PostDetailSheet(post: post)
        }
    }

    // Filter posts to only show those with images
    private var photoPosts: [Post] {
        viewModel.userPosts.filter { post in
            post.imageUrl != nil || post.imageData != nil
        }
    }

    // Check if this is the current user's own profile
    private var isOwnProfile: Bool {
        guard let currentUserId = authManager.currentUser?.id else { return false }
        return userId == nil || userId == currentUserId
    }

    // Load profile data
    private func loadProfile() async {
        // If userId is provided, load that user's data
        // Otherwise load current user's data
        await viewModel.loadUserData()

        // Check follow status if viewing someone else's profile
        if let targetUserId = userId, !isOwnProfile {
            isFollowing = await viewModel.isFollowing(userId: targetUserId)
        }
    }

    // Toggle follow/unfollow
    private func toggleFollow() async {
        guard let targetUserId = userId, !isOwnProfile else { return }

        isLoadingFollow = true

        if isFollowing {
            let success = await viewModel.unfollowUser(userId: targetUserId)
            if success {
                isFollowing = false
            }
        } else {
            let success = await viewModel.followUser(userId: targetUserId)
            if success {
                isFollowing = true
            }
        }

        isLoadingFollow = false
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let userProfile: UserProfile?
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let isOwnProfile: Bool
    let isFollowing: Bool
    let isLoadingFollow: Bool
    let onEditProfile: () -> Void
    let onFollowToggle: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                // Profile Avatar
                Circle()
                    .fill(MinimalDesign.Colors.secondaryBackground)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Group {
                            if let avatarUrl = userProfile?.avatarUrl,
                               let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipShape(Circle())
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Text(userProfile?.displayName?.prefix(1).uppercased() ?? "?")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    )

                // Stats
                HStack(spacing: 24) {
                    StatView(count: postsCount, label: "Posts")

                    if let profileUserId = userProfile?.id {
                        NavigationLink(destination: FollowListView(userId: profileUserId, listType: .followers)) {
                            VStack(spacing: 2) {
                                Text("\(followersCount)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Followers")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: FollowListView(userId: profileUserId, listType: .following)) {
                            VStack(spacing: 2) {
                                Text("\(followingCount)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Following")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        StatView(count: followersCount, label: "Followers")
                        StatView(count: followingCount, label: "Following")
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Display Name & Bio
            VStack(alignment: .leading, spacing: 4) {
                if let displayName = userProfile?.displayName {
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                if let bio = userProfile?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Edit Profile or Follow Button
            if isOwnProfile {
                // Edit Profile Button
                Button(action: onEditProfile) {
                    Text("Edit Profile")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            } else {
                // Follow/Following Button
                Button(action: onFollowToggle) {
                    HStack(spacing: 4) {
                        if isLoadingFollow {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Text(isFollowing ? "Following" : "Follow")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(isFollowing ? .white : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(isFollowing ? Color.white.opacity(0.15) : Color.cyan)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFollowing ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .disabled(isLoadingFollow)
            }
        }
    }
}

// MARK: - Stat View
struct StatView: View {
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Photo Grid Item
struct PhotoGridItem: View {
    let post: Post

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let imageUrl = post.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.width)
                                .clipped()
                        case .failure(_):
                            placeholderView(size: geometry.size.width)
                        case .empty:
                            ProgressView()
                                .frame(width: geometry.size.width, height: geometry.size.width)
                        @unknown default:
                            placeholderView(size: geometry.size.width)
                        }
                    }
                } else if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                } else {
                    placeholderView(size: geometry.size.width)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func placeholderView(size: CGFloat) -> some View {
        Rectangle()
            .fill(MinimalDesign.Colors.secondaryBackground)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(MinimalDesign.Colors.tertiary)
            )
    }
}

// MARK: - Post Detail Sheet
struct PostDetailSheet: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Post Image
                    if let imageUrl = post.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Post Info
                    VStack(alignment: .leading, spacing: 8) {
                        // Author Info
                        if !post.isAnonymous {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(MinimalDesign.Colors.secondaryBackground)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Group {
                                            if let avatarUrl = post.authorAvatarUrl,
                                               let url = URL(string: avatarUrl) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .clipShape(Circle())
                                                } placeholder: {
                                                    Text(post.authorName.prefix(1).uppercased())
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(MinimalDesign.Colors.tertiary)
                                                }
                                            } else {
                                                Text(post.authorName.prefix(1).uppercased())
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(MinimalDesign.Colors.tertiary)
                                            }
                                        }
                                    )

                                Text(post.authorName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(MinimalDesign.Colors.primary)
                            }
                        }

                        // Post Text
                        if !post.text.isEmpty {
                            Text(post.text)
                                .font(.system(size: 14))
                                .foregroundColor(MinimalDesign.Colors.primary)
                        }

                        // Location
                        if let locationName = post.locationName {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(MinimalDesign.Colors.tertiary)

                                Text(locationName)
                                    .font(.system(size: 12))
                                    .foregroundColor(MinimalDesign.Colors.secondary)
                            }
                        }

                        // Stats
                        HStack(spacing: 16) {
                            Label("\(post.likeCount)", systemImage: "heart")
                                .font(.system(size: 12))
                                .foregroundColor(MinimalDesign.Colors.secondary)

                            Label("\(post.commentCount)", systemImage: "bubble.right")
                                .font(.system(size: 12))
                                .foregroundColor(MinimalDesign.Colors.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .background(MinimalDesign.Colors.background)
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
