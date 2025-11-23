//======================================================================
// MARK: - MyPageViewModel.swift
// Purpose: Manages the user's profile page state and operations
// Path: GLOBE/Features/Profile/MyPageViewModel.swift
//======================================================================
import SwiftUI
import Foundation
import Combine
import Supabase
import CoreLocation

@MainActor
final class MyPageViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var userProfile: UserProfile?
    @Published var userPosts: [Post] = []
    @Published var postsCount: Int = 0
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private var authService: (any AuthServiceProtocol)?

    // MARK: - Private Properties

    private var hasLoadedInitially = false
    private var currentUserId: String? {
        authService?.currentUser?.id
    }

    // NEW: Flag to prevent auto-loading when viewing another user's profile
    private var shouldAutoLoad: Bool = true

    private let logger = SecureLogger.shared
    private var cancellables = Set<AnyCancellable>()

    func clearUserData() {
        userProfile = nil
        userPosts = []
        postsCount = 0
        followersCount = 0
        followingCount = 0
        hasLoadedInitially = false
    }

    // MARK: - Initialization

    nonisolated init(authService: (any AuthServiceProtocol)? = nil, shouldAutoLoad: Bool = true) {
        // Setup must happen on MainActor
        Task { @MainActor in
            // Set authService on MainActor to avoid isolation issues
            self.authService = authService ?? AuthManager.shared
            self.shouldAutoLoad = shouldAutoLoad

            // Only auto-load if shouldAutoLoad is true (for viewing own profile)
            if shouldAutoLoad {
                self.loadInitialData()
            }
        }
    }

    // MARK: - Setup

    deinit {
        cancellables.removeAll()
    }

    private func loadInitialData() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            // まずプロフィールと認証情報を同期
            await self.syncProfileWithAuthData()
            await self.loadUserDataIfNeeded()
        }
    }
    
    // MARK: - Public Methods
    
    func loadUserDataIfNeeded() async {
        guard !hasLoadedInitially else { return }
        await loadUserData()
    }
    
    func loadUserData() async {
        guard let userId = currentUserId else {
            SecureLogger.shared.warning("Load user data attempted without user ID")
            return
        }

        SecureLogger.shared.info("Starting to load user data user_id=\(userId)")
        isLoading = true

        do {
            // Get Supabase client
            let client = await SupabaseManager.shared.client

            // Load profile directly from Supabase
            let profileResult = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.lowercased())
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                let profiles = try decoder.decode([UserProfile].self, from: profileResult.data)

                if let profile = profiles.first {
                    userProfile = profile
                    SecureLogger.shared.info("Profile loaded successfully display_name=\(profile.displayName ?? "none") username=\(profile.username ?? "none")")
                } else {
                    // プロフィールが存在しない場合、認証情報から作成
                    SecureLogger.shared.warning("Profile not found in DB for user: \(userId)")
                    await createProfileFromAuthData()
                    hasLoadedInitially = true
                    isLoading = false
                    return
                }
            } catch {
                SecureLogger.shared.error("Failed to decode profile: \(error.localizedDescription)")
                SecureLogger.shared.error("Profile data: \(String(data: profileResult.data, encoding: .utf8) ?? "invalid")")
                errorMessage = "プロフィールのデコードに失敗しました"
                hasLoadedInitially = true
                isLoading = false
                return
            }

            // Load user posts directly from Supabase
            let postsResult = try await client
                .from("posts")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()

            let posts = try? decoder.decode([Post].self, from: postsResult.data)
            userPosts = posts ?? []
            postsCount = userPosts.count

            SecureLogger.shared.info("Loaded \(userPosts.count) posts for user, \(userPosts.filter { $0.imageUrl != nil }.count) have images")

            // Update local user profile with post count
            if var profile = userProfile {
                profile = UserProfile(
                    id: profile.id,
                    username: profile.username,
                    displayName: profile.displayName,
                    bio: profile.bio,
                    avatarUrl: profile.avatarUrl,
                    postCount: postsCount,
                    followerCount: profile.followerCount,
                    followingCount: profile.followingCount
                )
                userProfile = profile
            }

            // Load follower/following counts from Supabase
            followersCount = await SupabaseService.shared.getFollowerCount(userId: userId)
            followingCount = await SupabaseService.shared.getFollowingCount(userId: userId)

            SecureLogger.shared.info("User data loaded successfully posts=\(postsCount) followers=\(followersCount) following=\(followingCount)")

            hasLoadedInitially = true
            isLoading = false

        } catch {
            SecureLogger.shared.error("Error loading user data: \(error.localizedDescription)")
            errorMessage = AppError.from(error).localizedDescription
            isLoading = false
        }
    }

    
    // MARK: - Profile Creation
    
    /// 認証情報からプロフィールを作成
    private func createProfileFromAuthData() async {
        // Supabaseのセッションから実際のユーザーIDを取得
        do {
            // Get Supabase client
            let client = await SupabaseManager.shared.client

            let session = try await client.auth.session
            let userId = session.user.id.uuidString
            let _ = session.user.userMetadata["username"]?.stringValue ??
                         session.user.email?.components(separatedBy: "@").first ?? "user"

            logger.info("Checking profile for user: \(userId)")

            // まずプロフィールが既に存在するか確認
            let existingProfile = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let profiles = try? decoder.decode([UserProfile].self, from: existingProfile.data)

            if let profile = profiles?.first {
                logger.info("Profile already exists for user: \(userId)")
                userProfile = profile
            } else {
                // プロフィールが存在しない場合、handle_new_userトリガーが作成するのを待つ
                logger.warning("Waiting for profile to be created by database trigger...")

                // 少し待ってから再度確認
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機

                let retryProfile = try await client
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .execute()

                let retryProfiles = try? decoder.decode([UserProfile].self, from: retryProfile.data)
                if let profile = retryProfiles?.first {
                    logger.info("Profile found after retry")
                    userProfile = profile

                    // プロフィールが見つかった場合のみ、投稿データを読み込む
                    let postsResult = try await client
                        .from("posts")
                        .select()
                        .eq("user_id", value: userId)
                        .order("created_at", ascending: false)
                        .execute()

                    let posts = try? decoder.decode([Post].self, from: postsResult.data)
                    userPosts = posts ?? []
                    postsCount = userPosts.count
                } else {
                    logger.warning("Profile still not found after retry")
                    errorMessage = "プロフィールの作成を待っています。しばらくしてから再度お試しください。"
                }
            }

        } catch {
            logger.error("Failed during profile check: \(error.localizedDescription)")
            if error.localizedDescription.contains("sessionMissing") {
                errorMessage = "セッションが無効です。再度ログインしてください。"
                // AuthManagerに再認証を促す
                _ = await authService?.checkCurrentUser()
            } else {
                errorMessage = "プロフィール取得に失敗しました: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    /// プロフィールと認証情報の整合性をチェックし、必要に応じて修正
    @MainActor
    func syncProfileWithAuthData() async {
        guard let _ = authService?.currentUser,
              let userId = currentUserId else {
            logger.warning("No current user for sync")
            return
        }

        logger.info("Syncing profile with auth data")

        do {
            // Get Supabase client
            let client = await SupabaseManager.shared.client

            // 現在のプロフィール情報を取得
            let profileData = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let profiles: [UserProfile] = try decoder.decode([UserProfile].self, from: profileData.data)

            if let existingProfile = profiles.first {
                // プロフィールが存在する場合、ローカルに反映
                userProfile = existingProfile
                logger.info("Profile synced successfully")
            } else {
                // プロフィールが存在しない場合は作成
                await createProfileFromAuthData()
            }

        } catch {
            logger.error("Failed to sync profile: \(error.localizedDescription)")
        }
    }
    
    func updateProfile(displayName: String, bio: String) async {
        guard let userId = currentUserId else {
            logger.error("No current user ID")
            errorMessage = "ユーザーIDが取得できません"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Get Supabase client
            let client = await SupabaseManager.shared.client

            // 入力検証
            let validatedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let validatedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

            // Display name validation (1-50 characters)
            guard !validatedDisplayName.isEmpty && validatedDisplayName.count >= 1 && validatedDisplayName.count <= 50 else {
                errorMessage = "表示名は1-50文字で入力してください"
                logger.warning("Display name validation failed")
                return
            }

            let updatedProfile = UserProfile(
                id: userId,
                username: userProfile?.username,
                displayName: validatedDisplayName,
                bio: validatedBio.isEmpty ? nil : validatedBio,
                avatarUrl: userProfile?.avatarUrl,
                postCount: userProfile?.postCount,
                followerCount: userProfile?.followerCount,
                followingCount: userProfile?.followingCount
            )

            let updateDict: [String: AnyJSON] = [
                "display_name": AnyJSON.string(validatedDisplayName),
                "bio": validatedBio.isEmpty ? AnyJSON.null : AnyJSON.string(validatedBio),
                "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ]

            logger.info("Executing UPDATE with userId: \(userId)")

            // Try without .lowercased() - the database should handle UUID comparison
            let response = try await client
                .from("profiles")
                .update(updateDict)
                .eq("id", value: userId)
                .select()
                .execute()

            let responseData = String(data: response.data, encoding: .utf8) ?? "nil"
            logger.info("UPDATE response: \(responseData)")

            userProfile = updatedProfile
            errorMessage = nil
            logger.info("Profile updated successfully")

        } catch {
            logger.error("Failed to update profile: \(error.localizedDescription)")
            errorMessage = "プロフィールの更新に失敗しました: \(error.localizedDescription)"
        }
    }

    func deletePost(_ post: Post) async {
        do {
            // Get Supabase client
            let client = await SupabaseManager.shared.client

            try await client
                .from("posts")
                .delete()
                .eq("id", value: post.id.uuidString)
                .execute()

            await loadUserData() // Reload all data

        } catch {
            logger.error("Error deleting post: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Avatar Update
    func updateAvatar(imageData: Data) async {
        guard let userId = currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // Get Supabase client
            let client = await SupabaseManager.shared.client

            // Compress to JPEG if needed (<= ~600KB target)
            let jpegData: Data
            if let ui = UIImage(data: imageData), let d = ui.jpegData(compressionQuality: 0.85) {
                jpegData = d
            } else {
                jpegData = imageData
            }

            let fileName = "\(userId)/avatar_\(UUID().uuidString).jpg"
            logger.info("Uploading avatar for user to avatars/\(fileName)")

            // Upload to 'avatars' bucket (SDK default options)
            try await client.storage
                .from("avatars")
                .upload(fileName, data: jpegData)

            let publicURL = try client.storage
                .from("avatars")
                .getPublicURL(path: fileName)
                .absoluteString

            // Update profiles.avatar_url
            try await client
                .from("profiles")
                .update(["avatar_url": AnyJSON.string(publicURL)])
                .eq("id", value: userId)
                .execute()

            // Reflect in local state
            if var profile = userProfile {
                profile = UserProfile(
                    id: profile.id,
                    username: profile.username,
                    displayName: profile.displayName,
                    bio: profile.bio,
                    avatarUrl: publicURL,
                    postCount: profile.postCount,
                    followerCount: profile.followerCount,
                    followingCount: profile.followingCount
                )
                userProfile = profile
            } else {
                await loadUserData()
            }

            logger.info("Avatar updated successfully")
        } catch {
            logger.error("Failed to update avatar: \(error.localizedDescription)")
            errorMessage = "アバターの更新に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - Follow/Unfollow

    /// Check if current user is following a specific user
    func isFollowing(userId: String) async -> Bool {
        return await SupabaseService.shared.isFollowing(userId: userId)
    }

    /// Follow a user
    func followUser(userId: String) async -> Bool {
        let success = await SupabaseService.shared.followUser(userId: userId)
        if success {
            // Reload follower/following counts
            followersCount = await SupabaseService.shared.getFollowerCount(userId: userId)
            followingCount = await SupabaseService.shared.getFollowingCount(userId: userId)
        }
        return success
    }

    /// Unfollow a user
    func unfollowUser(userId: String) async -> Bool {
        let success = await SupabaseService.shared.unfollowUser(userId: userId)
        if success {
            // Reload follower/following counts
            followersCount = await SupabaseService.shared.getFollowerCount(userId: userId)
            followingCount = await SupabaseService.shared.getFollowingCount(userId: userId)
        }
        return success
    }

    /// Get follower count for a user
    func getFollowerCount(userId: String) async -> Int {
        return await SupabaseService.shared.getFollowerCount(userId: userId)
    }

    /// Get following count for a user
    func getFollowingCount(userId: String) async -> Int {
        return await SupabaseService.shared.getFollowingCount(userId: userId)
    }

    //###########################################################################
    // MARK: - Other User Profile Loading
    // Function: loadOtherUserProfile
    // Overview: Load another user's profile, posts, and follower counts
    // Processing: Query profile → Query posts → Get follower counts → Update published properties
    //###########################################################################

    func loadOtherUserProfile(userId: String) async {
        logger.info("Loading profile for user: \(userId)")
        isLoading = true
        errorMessage = nil

        do {
            let client = await SupabaseManager.shared.client

            // Load user profile
            let profileResult = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.lowercased())
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let profiles = try? decoder.decode([UserProfile].self, from: profileResult.data)
            guard let profile = profiles?.first else {
                logger.error("Profile not found for userId: \(userId)")
                errorMessage = "User profile not found"
                isLoading = false
                return
            }

            logger.info("Profile loaded - displayName: \(profile.displayName ?? "none")")

            // Load user's posts
            let postsResult = try await client
                .from("posts")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()

            let posts = (try? decoder.decode([Post].self, from: postsResult.data)) ?? []
            logger.info("Loaded \(posts.count) posts for user")

            // Load follower/following counts
            let followers = await SupabaseService.shared.getFollowerCount(userId: userId)
            let following = await SupabaseService.shared.getFollowingCount(userId: userId)

            // Update all properties on MainActor
            userProfile = profile
            userPosts = posts
            postsCount = posts.count
            followersCount = followers
            followingCount = following
            isLoading = false

            logger.info("Profile loading complete - Followers: \(followers), Following: \(following)")

        } catch {
            logger.error("Failed to load other user profile: \(error.localizedDescription)")
            errorMessage = AppError.from(error).localizedDescription
            isLoading = false
        }
    }
}
