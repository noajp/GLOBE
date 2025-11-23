//======================================================================
// MARK: - TabBarProfileView.swift
// Purpose: Instagram-style profile view with photo grid (for own profile from tab bar)
// Path: GLOBE/Views/Profile/TabBarProfileView.swift
//======================================================================

import SwiftUI
import Supabase

struct TabBarProfileView: View {
    let userId: String? // If nil, shows current user's profile

    @StateObject private var viewModel: MyPageViewModel
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedPost: Post?
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingAuth = false
    @State private var isFollowing = false
    @State private var isLoadingFollow = false
    @State private var isLoadingProfile = true
    @State private var showingQRScanner = false
    @State private var scannedUserId: String?

    // Grid layout configuration
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    init(userId: String? = nil) {
        self.userId = userId

        // IMPORTANT: Prevent auto-loading when viewing another user's profile
        // If userId is provided, we'll manually load that user's data
        let shouldAutoLoad = (userId == nil)
        _viewModel = StateObject(wrappedValue: MyPageViewModel(shouldAutoLoad: shouldAutoLoad))

        SecureLogger.shared.info("TabBarProfileView.init: userId=\(userId ?? "nil"), shouldAutoLoad=\(shouldAutoLoad)")
    }

    var body: some View {
        ZStack {
            // Background layer (solid black #121212)
            Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0)
                .ignoresSafeArea()

            // Loading indicator
            if isLoadingProfile {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Loading profile...")
                        .foregroundColor(.white)
                }
            }

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
                        onQRScan: {
                            showingQRScanner = true
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
            .opacity(isLoadingProfile ? 0 : 1)
        }
        .onAppear {
            Task {
                await loadProfile()
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            // Clear data when user signs out
            if !isAuthenticated {
                viewModel.clearUserData()
            }
        }
        .onChange(of: showingEditProfile) { _, isShowing in
            // Reload profile when returning from edit screen
            if !isShowing {
                Task {
                    await loadProfile()
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwnProfile {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Notification Bell
                        NavigationLink(destination: NotificationListView()) {
                            Image(systemName: "bell")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }

                        // Settings Menu
                        NavigationLink(destination: SettingsView(isPresented: $showingSettings, showingAuth: $showingAuth)) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingEditProfile) {
            ProfileEditView()
        }
        .sheet(item: $selectedPost) { post in
            PostDetailSheet(post: post)
        }
        .fullScreenCover(isPresented: $showingQRScanner) {
            QRCodeScannerView(
                isPresented: $showingQRScanner,
                scannedUserId: $scannedUserId
            )
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
        guard let currentUserId = authManager.currentUser?.id else {
            SecureLogger.shared.info("TabBarProfileView: No current user, showing as other's profile")
            return false
        }
        let isOwn = userId == nil || userId?.lowercased() == currentUserId.lowercased()
        SecureLogger.shared.info("TabBarProfileView: userId=\(userId ?? "nil"), currentUserId=\(currentUserId), isOwnProfile=\(isOwn)")
        return isOwn
    }

    // Load profile data
    private func loadProfile() async {
        SecureLogger.shared.info("TabBarProfileView: loadProfile started for userId: \(userId ?? "nil")")
        isLoadingProfile = true

        // If userId is provided, load that user's data
        if let targetUserId = userId {
            SecureLogger.shared.info("TabBarProfileView: Loading other user's profile: \(targetUserId)")
            await loadOtherUserProfile(userId: targetUserId)

            // Check follow status if viewing someone else's profile
            if !isOwnProfile {
                SecureLogger.shared.info("TabBarProfileView: Checking follow status for: \(targetUserId)")
                isFollowing = await viewModel.isFollowing(userId: targetUserId)
                SecureLogger.shared.info("TabBarProfileView: Follow status result: \(isFollowing)")
            }
        } else {
            // Otherwise load current user's data
            SecureLogger.shared.info("TabBarProfileView: Loading current user's profile")
            await viewModel.loadUserData()
        }

        isLoadingProfile = false
        SecureLogger.shared.info("TabBarProfileView: loadProfile completed - displayName: \(viewModel.userProfile?.displayName ?? "none")")
    }

    //###########################################################################
    // MARK: - Other User Profile Loading
    // Function: loadOtherUserProfile
    // Overview: Load another user's profile via ViewModel (MVVM compliant)
    // Processing: Delegate to MyPageViewModel.loadOtherUserProfile()
    //###########################################################################

    private func loadOtherUserProfile(userId: String) async {
        SecureLogger.shared.info("TabBarProfileView: Loading profile for userId: \(userId)")

        // Delegate to ViewModel - proper MVVM architecture
        await viewModel.loadOtherUserProfile(userId: userId)

        SecureLogger.shared.info("TabBarProfileView: Profile loading complete")
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

        // Re-check follow status to ensure UI is in sync
        isFollowing = await viewModel.isFollowing(userId: targetUserId)
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
    let onQRScan: () -> Void
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

            // Display Name with Edit/Follow Button
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if let displayName = userProfile?.displayName {
                        Text(displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    if let username = userProfile?.username {
                        Text("@\(username)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    if let bio = userProfile?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(3)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Edit Profile or Follow Button (aligned with display name)
                if isOwnProfile {
                    // Edit Profile and QR Scan Buttons
                    HStack(spacing: 8) {
                        // Edit Profile Button
                        Button(action: onEditProfile) {
                            Text("Edit Profile")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 90, height: 28)
                                .background(Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        }

                        // QR Scan Button (square)
                        Button(action: onQRScan) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                } else {
                    // Follow/Following Button
                    Button(action: onFollowToggle) {
                        HStack(spacing: 4) {
                            if isLoadingFollow {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.7)
                            } else {
                                Text(isFollowing ? "Following" : "Follow")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(width: 90, height: 28)
                        .background(isFollowing ? Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0) : Color(red: 0.0, green: 0.55, blue: 0.75))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .disabled(isLoadingFollow)
                }
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
        TabBarProfileView()
    }
}
