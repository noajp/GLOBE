//======================================================================
// MARK: - ProfileImageView.swift
// Purpose: Cached profile image component with automatic loading and caching
// Path: GLOBE/Views/Components/ProfileImageView.swift
//======================================================================

import SwiftUI

struct ProfileImageView: View {
    let userProfile: UserProfile?
    let size: CGFloat

    @State private var cachedImage: UIImage?
    @State private var isLoading = false

    private var userId: String {
        userProfile?.id ?? ""
    }

    private var avatarUrl: String? {
        userProfile?.avatarUrl
    }

    var body: some View {
        // COMMENTED OUT for v1.0 release - profile images disabled
        /*
        Group {
            if let cachedImage = cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                // Show loading placeholder
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                        .scaleEffect(0.8)
                }
            } else {
                // Show default placeholder
                profilePlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear {
            loadProfileImage()
        }
        .onChange(of: avatarUrl) { _, _ in
            loadProfileImage()
        }
        */

        // v1.0: Always show placeholder
        profilePlaceholder
            .frame(width: size, height: size)
            .clipShape(Circle())
    }

    private var profilePlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.gray.opacity(0.5))
        }
    }

    private func loadProfileImage() {
        // First check if we already have a cached image
        if let cached = ProfileImageCacheManager.shared.getCachedImage(for: userId) {
            cachedImage = cached
            return
        }

        // If we have an avatar URL, load it
        guard let avatarUrl = avatarUrl, !avatarUrl.isEmpty else {
            cachedImage = nil
            return
        }

        isLoading = true

        Task {
            let loadedImage = await ProfileImageCacheManager.shared.getImage(for: avatarUrl, userId: userId)

            await MainActor.run {
                self.cachedImage = loadedImage
                self.isLoading = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ProfileImageView(
            userProfile: nil,
            size: 70
        )

        ProfileImageView(
            userProfile: UserProfile(
                id: "test-id",
                displayName: "Test User",
                bio: "Test bio",
                avatarUrl: "https://via.placeholder.com/150",
                postCount: 0,
                followerCount: 0,
                followingCount: 0
            ),
            size: 70
        )
    }
    .padding()
}