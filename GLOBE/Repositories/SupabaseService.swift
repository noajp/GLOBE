//======================================================================
// MARK: - SupabaseService.swift
// Purpose: Supabase database operations for posts, likes, comments, and profiles
// Path: GLOBE/Services/SupabaseService.swift
//======================================================================

import Foundation
import Supabase
import CoreLocation
import Combine

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    private let secureConfig = SecureConfig.shared
    private let secureLogger = SecureLogger.shared
    private let postService = PostService.shared

    // Supabase client (sync accessor to avoid async init in singleton)
    private let supabaseClient: SupabaseClient

    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?

private init() {
        // Use sync client for singleton construction
        supabaseClient = SupabaseManager.shared.syncClient
    }
    
    // MARK: - Posts (Delegating to PostService)

    @available(*, deprecated, message: "Use PostService.shared.fetchUserPosts(userId:) instead")
    func fetchUserPosts(userId: String) async -> [Post] {
        return await postService.fetchUserPosts(userId: userId)
    }
    
    @available(*, deprecated, message: "Use PostService.shared.fetchPostsInBounds instead")
    func fetchPostsInBounds(
        minLat: Double,
        maxLat: Double,
        minLng: Double,
        maxLng: Double,
        zoomLevel: Double
    ) async {
        await postService.fetchPostsInBounds(
            minLat: minLat,
            maxLat: maxLat,
            minLng: minLng,
            maxLng: maxLng,
            zoomLevel: zoomLevel
        )
        // Sync published properties from PostService
        self.posts = postService.posts
        self.isLoading = postService.isLoading
        self.error = postService.error
    }

    @available(*, deprecated, message: "Use PostService.shared.fetchPosts() instead")
    func fetchPosts() async {
        await postService.fetchPosts()
        // Sync published properties from PostService
        self.posts = postService.posts
        self.isLoading = postService.isLoading
        self.error = postService.error
    }

    @available(*, deprecated, message: "Use PostService.shared.createPost instead")
    func createPostWithRPC(
        content: String,
        imageData: Data?,
        latitude: Double,
        longitude: Double,
        locationName: String?,
        isAnonymous: Bool = false
    ) async -> Bool {
        let success = await postService.createPost(
            content: content,
            imageData: imageData,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            isAnonymous: isAnonymous
        )
        // Sync published properties from PostService
        self.posts = postService.posts
        self.isLoading = postService.isLoading
        self.error = postService.error
        return success
    }

    // MARK: - Delete Posts (Delegating to PostService)

    @available(*, deprecated, message: "Use PostService.shared.deletePost instead")
    func deletePost(_ postId: UUID) async -> Bool {
        let success = await postService.deletePost(postId)
        // Sync published properties from PostService
        self.posts = postService.posts
        self.isLoading = postService.isLoading
        self.error = postService.error
        return success
    }
    
    // MARK: - Likes
    
    func toggleLike(postId: UUID, userId: String) async -> Bool {
        secureLogger.info("Toggling like for post: \(postId)")
        
        do {
            // まず現在のlike状態を確認
            let response = try await supabaseClient
                .from("likes")
                .select("*")
                .eq("post_id", value: postId.uuidString)
                .eq("user_id", value: userId)
                .execute()
            
            let decoder = JSONDecoder()
            let likes = try decoder.decode([DatabaseLike].self, from: response.data)
            
            if likes.isEmpty {
                // Like追加
                let likeData: [String: AnyJSON] = [
                    "post_id": .string(postId.uuidString),
                    "user_id": .string(userId)
                ]
                
                _ = try await supabaseClient
                    .from("likes")
                    .insert(likeData)
                    .execute()
                
                // ローカルで更新
                await MainActor.run {
                    if let index = posts.firstIndex(where: { $0.id == postId }) {
                        posts[index].isLikedByMe = true
                        posts[index].likeCount += 1
                    }
                }
                
            } else {
                // Like削除
                _ = try await supabaseClient
                    .from("likes")
                    .delete()
                    .eq("post_id", value: postId.uuidString)
                    .eq("user_id", value: userId)
                    .execute()
                
                // ローカルで更新
                await MainActor.run {
                    if let index = posts.firstIndex(where: { $0.id == postId }) {
                        posts[index].isLikedByMe = false
                        posts[index].likeCount = max(0, posts[index].likeCount - 1)
                    }
                }
            }
            
            return true
            
        } catch {
            secureLogger.error("Failed to toggle like: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "いいねの更新に失敗しました"
            }
            return false
        }
    }

    // MARK: - Follow/Unfollow

    /// Follow a user
    func followUser(userId: String) async -> Bool {
        secureLogger.info("Following user: \(userId)")

        do {
            // Get current user ID - prefer AuthManager for development mode support
            guard let currentUserIdString = AuthManager.shared.currentUser?.id,
                  let currentUserId = UUID(uuidString: currentUserIdString) else {
                secureLogger.warning("No authenticated user found")
                return false
            }

            secureLogger.info("Follow: currentUserId=\(currentUserId.uuidString), targetUserId=\(userId)")

            guard let followingUUID = UUID(uuidString: userId) else {
                secureLogger.warning("Invalid user ID format: \(userId)")
                return false
            }

            // Prevent self-follow
            if currentUserId.uuidString.lowercased() == followingUUID.uuidString.lowercased() {
                secureLogger.warning("Cannot follow yourself")
                await MainActor.run {
                    self.error = "自分自身をフォローすることはできません"
                }
                return false
            }

            // Check if already following
            let existing = try await supabaseClient
                .from("follows")
                .select()
                .eq("follower_id", value: currentUserId.uuidString.lowercased())
                .eq("following_id", value: followingUUID.uuidString.lowercased())
                .execute()

            let decoder = JSONDecoder()
            let existingFollows = try? decoder.decode([DatabaseFollow].self, from: existing.data)

            if !(existingFollows?.isEmpty ?? true) {
                secureLogger.info("Already following user \(userId)")
                return true
            }

            // Create follow record as dictionary
            let followData: [String: String] = [
                "id": UUID().uuidString.lowercased(),
                "follower_id": currentUserId.uuidString.lowercased(),
                "following_id": followingUUID.uuidString.lowercased(),
                "created_at": ISO8601DateFormatter().string(from: Date())
            ]

            _ = try await supabaseClient
                .from("follows")
                .insert(followData)
                .execute()

            secureLogger.info("Successfully followed user \(userId)")
            return true

        } catch {
            let errorMessage = error.localizedDescription

            // If already following (duplicate key error), treat as success
            if errorMessage.contains("duplicate key") || errorMessage.contains("follows_follower_id_following_id_key") {
                secureLogger.info("Already following user \(userId) (duplicate key)")
                return true
            }

            secureLogger.error("Failed to follow user: \(errorMessage)")
            await MainActor.run {
                if errorMessage.contains("session") || errorMessage.contains("auth") {
                    self.error = "認証エラー：再度ログインしてください"
                } else {
                    self.error = "フォローに失敗しました: \(errorMessage)"
                }
            }
            return false
        }
    }

    /// Unfollow a user
    func unfollowUser(userId: String) async -> Bool {
        secureLogger.info("Unfollowing user: \(userId)")

        do {
            // Get current user ID - prefer AuthManager for development mode support
            guard let currentUserIdString = AuthManager.shared.currentUser?.id,
                  let currentUserId = UUID(uuidString: currentUserIdString) else {
                secureLogger.warning("No authenticated user found")
                return false
            }

            guard let followingUUID = UUID(uuidString: userId) else {
                secureLogger.warning("Invalid user ID format: \(userId)")
                return false
            }

            // Delete follow record
            _ = try await supabaseClient
                .from("follows")
                .delete()
                .eq("follower_id", value: currentUserId.uuidString.lowercased())
                .eq("following_id", value: followingUUID.uuidString.lowercased())
                .execute()

            secureLogger.info("Successfully unfollowed user \(userId)")
            return true

        } catch {
            secureLogger.error("Failed to unfollow user: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "フォロー解除に失敗しました"
            }
            return false
        }
    }

    /// Check if current user is following a specific user
    func isFollowing(userId: String) async -> Bool {
        do {
            // Get current user ID - prefer AuthManager for development mode support
            guard let currentUserIdString = AuthManager.shared.currentUser?.id,
                  let currentUserId = UUID(uuidString: currentUserIdString) else {
                secureLogger.warning("No authenticated user found")
                return false
            }

            secureLogger.info("isFollowing check: currentUserId=\(currentUserId.uuidString), targetUserId=\(userId)")

            guard let followingUUID = UUID(uuidString: userId) else {
                secureLogger.warning("Invalid userId format in isFollowing: \(userId)")
                return false
            }

            let response = try await supabaseClient
                .from("follows")
                .select()
                .eq("follower_id", value: currentUserId.uuidString.lowercased())
                .eq("following_id", value: followingUUID.uuidString.lowercased())
                .execute()

            // Debug: Log the raw response
            if let responseString = String(data: response.data, encoding: .utf8) {
                secureLogger.info("isFollowing raw response: \(responseString)")
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let follows = try? decoder.decode([DatabaseFollow].self, from: response.data)

            let isFollowingResult = !(follows?.isEmpty ?? true)
            secureLogger.info("isFollowing result: \(isFollowingResult), follows count: \(follows?.count ?? 0)")
            return isFollowingResult

        } catch {
            secureLogger.error("Failed to check following status: \(error.localizedDescription)")
            return false
        }
    }

    /// Get follower count for a user
    func getFollowerCount(userId: String) async -> Int {
        do {
            guard let userUUID = UUID(uuidString: userId) else {
                return 0
            }

            let response = try await supabaseClient
                .from("follows")
                .select("id", head: false, count: .exact)
                .eq("following_id", value: userUUID.uuidString.lowercased())
                .execute()

            return response.count ?? 0

        } catch {
            secureLogger.error("Failed to get follower count: \(error.localizedDescription)")
            return 0
        }
    }

    /// Get following count for a user
    func getFollowingCount(userId: String) async -> Int {
        do {
            guard let userUUID = UUID(uuidString: userId) else {
                return 0
            }

            let response = try await supabaseClient
                .from("follows")
                .select("id", head: false, count: .exact)
                .eq("follower_id", value: userUUID.uuidString.lowercased())
                .execute()

            return response.count ?? 0

        } catch {
            secureLogger.error("Failed to get following count: \(error.localizedDescription)")
            return 0
        }
    }

    /// Get list of followers for a user
    func getFollowers(userId: String) async -> [UserProfile] {
        do {
            guard let userUUID = UUID(uuidString: userId) else {
                return []
            }

            // Step 1: Get follower IDs from follows table
            let followResponse = try await supabaseClient
                .from("follows")
                .select("follower_id")
                .eq("following_id", value: userUUID.uuidString.lowercased())
                .order("created_at", ascending: false)
                .execute()

            // Parse follower IDs
            let followData = try JSONDecoder().decode([[String: String]].self, from: followResponse.data)
            let followerIds = followData.compactMap { $0["follower_id"] }

            secureLogger.info("Found \(followerIds.count) followers for user \(userId)")

            guard !followerIds.isEmpty else {
                return []
            }

            // Step 2: Fetch profiles for those IDs
            let profilesResponse = try await supabaseClient
                .from("profiles")
                .select("id, display_name, avatar_url, bio, created_at, updated_at")
                .in("id", values: followerIds)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let profiles = try decoder.decode([UserProfile].self, from: profilesResponse.data)

            secureLogger.info("Fetched \(profiles.count) follower profiles")
            return profiles

        } catch {
            secureLogger.error("Failed to get followers: \(error.localizedDescription)")
            return []
        }
    }

    /// Get list of users being followed
    func getFollowing(userId: String) async -> [UserProfile] {
        do {
            guard let userUUID = UUID(uuidString: userId) else {
                return []
            }

            // Step 1: Get following IDs from follows table
            let followResponse = try await supabaseClient
                .from("follows")
                .select("following_id")
                .eq("follower_id", value: userUUID.uuidString.lowercased())
                .order("created_at", ascending: false)
                .execute()

            // Parse following IDs
            let followData = try JSONDecoder().decode([[String: String]].self, from: followResponse.data)
            let followingIds = followData.compactMap { $0["following_id"] }

            secureLogger.info("Found \(followingIds.count) following for user \(userId)")

            guard !followingIds.isEmpty else {
                return []
            }

            // Step 2: Fetch profiles for those IDs
            let profilesResponse = try await supabaseClient
                .from("profiles")
                .select("id, display_name, avatar_url, bio, created_at, updated_at")
                .in("id", values: followingIds)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let profiles = try decoder.decode([UserProfile].self, from: profilesResponse.data)

            secureLogger.info("Fetched \(profiles.count) following profiles")
            return profiles

        } catch {
            secureLogger.error("Failed to get following: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Notifications

    /// Get notifications for current user
    func getNotifications() async -> [AppNotification] {
        do {
            let session = try await supabaseClient.auth.session
            let currentUserId = session.user.id

            let response = try await supabaseClient
                .from("notifications")
                .select("""
                    id,
                    recipient_id,
                    actor_id,
                    type,
                    post_id,
                    is_read,
                    created_at,
                    profiles!notifications_actor_id_fkey(display_name, avatar_url)
                """)
                .eq("recipient_id", value: currentUserId.uuidString)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            struct NotificationResponse: Codable {
                let id: String
                let recipient_id: String
                let actor_id: String
                let type: String
                let post_id: String?
                let is_read: Bool
                let created_at: Date
                let profiles: ProfileData?

                struct ProfileData: Codable {
                    let display_name: String?
                    let avatar_url: String?
                }
            }

            let notificationResponses = try decoder.decode([NotificationResponse].self, from: response.data)

            let notifications = notificationResponses.map { notif in
                AppNotification(
                    id: notif.id,
                    type: NotificationType(rawValue: notif.type) ?? .follow,
                    actorName: notif.profiles?.display_name ?? "Someone",
                    actorId: notif.actor_id,
                    actorAvatarUrl: notif.profiles?.avatar_url,
                    postId: notif.post_id,
                    createdAt: notif.created_at,
                    isRead: notif.is_read
                )
            }

            secureLogger.info("Fetched \(notifications.count) notifications")
            return notifications

        } catch {
            secureLogger.error("Failed to get notifications: \(error.localizedDescription)")
            return []
        }
    }

    /// Mark notification as read
    func markNotificationAsRead(notificationId: String) async -> Bool {
        do {
            _ = try await supabaseClient
                .from("notifications")
                .update(["is_read": true])
                .eq("id", value: notificationId)
                .execute()

            secureLogger.info("Marked notification as read: \(notificationId)")
            return true

        } catch {
            secureLogger.error("Failed to mark notification as read: \(error.localizedDescription)")
            return false
        }
    }

    /// Get unread notification count
    func getUnreadNotificationCount() async -> Int {
        do {
            let session = try await supabaseClient.auth.session
            let currentUserId = session.user.id

            let response = try await supabaseClient
                .from("notifications")
                .select("id", head: true, count: .exact)
                .eq("recipient_id", value: currentUserId.uuidString)
                .eq("is_read", value: false)
                .execute()

            return response.count ?? 0

        } catch {
            secureLogger.error("Failed to get unread count: \(error.localizedDescription)")
            return 0
        }
    }

    // MARK: - User Search

    /// Search users by display name or username
    func searchUsers(query: String) async -> [UserProfile] {
        secureLogger.info("Searching users with query: \(query)")

        guard !query.isEmpty else {
            return []
        }

        do {
            // Search by display_name or username using ilike (case-insensitive)
            let response = try await supabaseClient
                .from("profiles")
                .select("id,display_name,username,avatar_url,bio,created_at")
                .or("display_name.ilike.%\(query)%,username.ilike.%\(query)%")
                .order("display_name", ascending: true)
                .limit(20)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let profiles = try decoder.decode([UserProfile].self, from: response.data)

            secureLogger.info("Found \(profiles.count) users matching query: \(query)")
            return profiles

        } catch {
            secureLogger.error("Failed to search users: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Data Models
struct DatabasePost: Codable {
    let id: UUID
    let user_id: UUID
    let content: String
    let image_url: String?
    let location_name: String?
    let latitude: Double
    let longitude: Double
    let is_public: Bool
    let is_anonymous: Bool?
    let created_at: Date
    let expires_at: Date?
    let profiles: DatabaseProfile?
}

struct DatabaseProfile: Codable {
    let id: UUID
    let display_name: String?
    let avatar_url: String?
}

struct DatabaseLike: Codable {
    let id: UUID?
    let post_id: UUID
    let user_id: UUID
    let created_at: Date?
}

struct DatabaseFollow: Codable {
    let id: UUID
    let follower_id: UUID
    let following_id: UUID
    let created_at: Date
}

struct DatabaseNotification: Codable {
    let id: String
    let recipient_id: String
    let actor_id: String
    let type: String
    let post_id: String?
    let is_read: Bool
    let created_at: Date
    let actor_display_name: String?
    let actor_avatar_url: String?
}
