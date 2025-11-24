//======================================================================
// MARK: - PostService.swift
// Purpose: Post-related database operations
// Path: GLOBE/Services/PostService.swift
//======================================================================

import Foundation
import Supabase
import CoreLocation
import Combine

//###########################################################################
// MARK: - Post Service
// Function: PostService
// Overview: Handles all post-related database operations (CRUD)
// Processing: Fetch → Create → Update → Delete posts from Supabase
//###########################################################################

@MainActor
class PostService: ObservableObject {
    static let shared = PostService()

    // MARK: - Dependencies
    private let supabaseClient: SupabaseClient
    private let secureLogger = SecureLogger.shared

    // MARK: - Published Properties
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?

    private init() {
        supabaseClient = SupabaseManager.shared.syncClient
    }

    //###########################################################################
    // MARK: - Fetch Operations
    // Function: fetchUserPosts
    // Overview: Fetch all posts for a specific user
    // Processing: Validate UUID → Query Supabase → Decode → Map to Post model
    //###########################################################################

    func fetchUserPosts(userId: String) async -> [Post] {
        secureLogger.info("Fetching posts for user: \(userId)")

        do {
            guard let userUUID = UUID(uuidString: userId) else {
                secureLogger.warning("Invalid user ID format: \(userId)")
                return []
            }

            let selectColumns = "id,user_id,content,image_url,location_name,latitude,longitude,is_public,is_anonymous,created_at,expires_at,like_count"

            let response = try await supabaseClient
                .from("posts")
                .select(selectColumns)
                .eq("user_id", value: userUUID.uuidString)
                .order("created_at", ascending: false)
                .limit(100)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let dbPosts = try decoder.decode([DatabasePost].self, from: response.data)

            let posts = dbPosts.map { dbPost in
                mapDatabasePostToPost(dbPost)
            }

            secureLogger.info("Successfully fetched \(posts.count) posts for user \(userId)")
            return posts

        } catch {
            let nsError = error as NSError
            secureLogger.error("Failed to fetch user posts: \(nsError.localizedDescription)")
            return []
        }
    }

    //###########################################################################
    // MARK: - Fetch Posts in Geographic Bounds
    // Function: fetchPostsInBounds
    // Overview: Fetch posts within a geographic bounding box with zoom-based filtering
    // Processing: Determine limit by zoom → Query by coordinates → Decode with profiles → Update published posts
    //###########################################################################

    func fetchPostsInBounds(
        minLat: Double,
        maxLat: Double,
        minLng: Double,
        maxLng: Double,
        zoomLevel: Double
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Determine limit based on zoom level
            let limit: Int
            if zoomLevel < 0.01 {
                limit = 100
            } else if zoomLevel < 0.1 {
                limit = 500
            } else if zoomLevel < 1.0 {
                limit = 2000
            } else {
                limit = 5000
            }

            let selectColumns = "id,user_id,content,image_url,location_name,latitude,longitude,is_public,is_anonymous,created_at,expires_at,like_count,profiles!inner(display_name,avatar_url)"

            let response = try await supabaseClient
                .from("posts")
                .select(selectColumns)
                .gte("latitude", value: minLat)
                .lte("latitude", value: maxLat)
                .gte("longitude", value: minLng)
                .lte("longitude", value: maxLng)
                .order("like_count", ascending: false)
                .limit(limit)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            struct PostWithProfile: Decodable {
                let id: UUID
                let user_id: UUID
                let content: String
                let image_url: String?
                let location_name: String?
                let latitude: Double
                let longitude: Double
                let is_public: Bool?
                let is_anonymous: Bool?
                let created_at: Date
                let expires_at: Date?
                let like_count: Int?
                let profiles: ProfileInfo?

                struct ProfileInfo: Decodable {
                    let display_name: String?
                    let avatar_url: String?
                }
            }

            let postsWithProfiles = try decoder.decode([PostWithProfile].self, from: response.data)

            self.posts = postsWithProfiles.map { dbPost in
                let name: String
                let avatar: String?
                if dbPost.is_anonymous ?? false {
                    name = "匿名ユーザー"
                    avatar = nil
                } else {
                    name = dbPost.profiles?.display_name ?? "Unknown User"
                    avatar = dbPost.profiles?.avatar_url
                }
                return Post(
                    id: dbPost.id,
                    createdAt: dbPost.created_at,
                    expiresAt: dbPost.expires_at,
                    location: CLLocationCoordinate2D(
                        latitude: dbPost.latitude,
                        longitude: dbPost.longitude
                    ),
                    locationName: dbPost.location_name,
                    imageData: nil,
                    imageUrl: dbPost.image_url,
                    text: dbPost.content,
                    authorName: name,
                    authorId: (dbPost.is_anonymous ?? false) ? "anonymous" : dbPost.user_id.uuidString,
                    isAnonymous: dbPost.is_anonymous ?? false,
                    authorAvatarUrl: avatar
                )
            }
        } catch {
            if Task.isCancelled {
                secureLogger.info("fetchPostsInBounds cancelled")
                return
            }

            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                return
            }

            secureLogger.error("Failed to fetch posts in bounds: \(nsError.localizedDescription)")
            self.error = nsError.localizedDescription
        }
    }

    //###########################################################################
    // MARK: - Fetch All Posts
    // Function: fetchPosts
    // Overview: Fetch recent posts with retry logic
    // Processing: Retry up to 3 times → Degrade payload on retries → Decode → Update posts
    //###########################################################################

    func fetchPosts() async {
        isLoading = true
        defer { isLoading = false }

        secureLogger.info("Fetching posts from database")

        let maxAttempts = 3
        var lastError: NSError?

        for attempt in 1...maxAttempts {
            do {
                let liteMode = attempt > 1
                let selectColumns = liteMode
                    ? "id,user_id,content,image_url,location_name,latitude,longitude,is_public,is_anonymous,created_at,expires_at"
                    : "*, profiles(*)"
                let limit = liteMode ? 20 : 50

                let response = try await supabaseClient
                    .from("posts")
                    .select(selectColumns)
                    .order("created_at", ascending: false)
                    .limit(limit)
                    .execute()

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let dbPosts = try decoder.decode([DatabasePost].self, from: response.data)

                self.posts = dbPosts.map { dbPost in
                    let name: String
                    let avatar: String?
                    if dbPost.is_anonymous ?? false {
                        name = "匿名ユーザー"
                        avatar = nil
                    } else if let prof = dbPost.profiles, !liteMode {
                        name = prof.display_name ?? "ユーザー"
                        avatar = prof.avatar_url
                    } else {
                        name = "ユーザー"
                        avatar = nil
                    }
                    return Post(
                        id: dbPost.id,
                        createdAt: dbPost.created_at,
                        expiresAt: dbPost.expires_at,
                        location: CLLocationCoordinate2D(
                            latitude: dbPost.latitude,
                            longitude: dbPost.longitude
                        ),
                        locationName: dbPost.location_name,
                        imageData: nil,
                        imageUrl: dbPost.image_url,
                        text: dbPost.content,
                        authorName: name,
                        authorId: (dbPost.is_anonymous ?? false) ? "anonymous" : dbPost.user_id.uuidString,
                        isAnonymous: dbPost.is_anonymous ?? false,
                        authorAvatarUrl: avatar
                    )
                }

                secureLogger.info("Successfully fetched \(posts.count) posts (attempt #\(attempt))")
                return
            } catch {
                let nsErr = error as NSError
                lastError = nsErr
                let isTimeout = nsErr.domain == NSURLErrorDomain && nsErr.code == NSURLErrorTimedOut
                let isNetwork = nsErr.domain == NSURLErrorDomain

                if attempt < maxAttempts && (isTimeout || isNetwork) {
                    let delay = UInt64(500_000_000) * UInt64(attempt)
                    try? await Task.sleep(nanoseconds: delay)
                    continue
                } else {
                    break
                }
            }
        }

        if let e = lastError {
            self.error = "投稿の取得に失敗しました"
            secureLogger.error("fetchPosts failed after \(maxAttempts) attempts")
        }
    }

    //###########################################################################
    // MARK: - Create Post Operation
    // Function: createPost
    // Overview: Create a new post with optional image upload
    // Processing: Validate session → Upload image → Insert to DB → Update local array
    //###########################################################################

    func createPost(
        content: String,
        imageData: Data?,
        latitude: Double,
        longitude: Double,
        locationName: String?,
        isAnonymous: Bool = false
    ) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        secureLogger.info("Creating post using direct insert")

        do {
            // Get userId from current session
            let session = try await supabaseClient.auth.session
            let currentUserId = session.user.id

            var imageUrl: String? = nil
            if let imageData = imageData {
                let fileName = "\(currentUserId.uuidString)/post_\(UUID().uuidString).jpg"

                do {
                    _ = try await supabaseClient.storage
                        .from("posts")
                        .upload(fileName, data: imageData)

                    imageUrl = try supabaseClient.storage
                        .from("posts")
                        .getPublicURL(path: fileName)
                        .absoluteString

                } catch {
                    self.error = "画像のアップロードに失敗しました"
                    return false
                }
            }

            // 投稿の有効期限を無効化（永続化）
            var postData: [String: AnyJSON] = [
                "user_id": .string(currentUserId.uuidString),
                "content": .string(content),
                "image_url": imageUrl.map { .string($0) } ?? .null,
                "location_name": locationName.map { .string($0) } ?? .null,
                "latitude": .double(latitude),
                "longitude": .double(longitude),
                "is_public": .bool(true),  // 常に公開（匿名でも投稿内容は公開）
                "expires_at": .null  // 有効期限なし
            ]

            postData["is_anonymous"] = .bool(isAnonymous)

            _ = try await supabaseClient
                .from("posts")
                .insert(postData)
                .execute()

            // 成功したら新しい投稿をローカル配列に追加

            // プロフィール情報を取得してアバターURLと表示名を取得
            var avatarUrl: String? = nil
            var displayName: String = "ユーザー"
            if !isAnonymous {
                do {
                    let profileResponse = try await supabaseClient
                        .from("profiles")
                        .select("avatar_url,display_name")
                        .eq("id", value: currentUserId.uuidString)
                        .single()
                        .execute()

                    let data = profileResponse.data
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let url = json["avatar_url"] as? String {
                            avatarUrl = url
                        }
                        if let name = json["display_name"] as? String {
                            displayName = name
                        }
                    }
                } catch {
                    // Failed to fetch profile data, continue with defaults
                }
            }

            let newPost = Post(
                createdAt: Date(),
                expiresAt: nil,  // 有効期限なし
                location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                locationName: locationName,
                imageData: imageData,
                imageUrl: imageUrl,
                text: content,
                authorName: isAnonymous ? "匿名ユーザー" : displayName,
                authorId: isAnonymous ? "anonymous" : currentUserId.uuidString,
                isPublic: true,  // 常に公開（匿名でも投稿内容は表示）
                isAnonymous: isAnonymous,
                authorAvatarUrl: isAnonymous ? nil : avatarUrl  // 匿名の場合はアバターURLもnilに
            )

            posts.insert(newPost, at: 0)

            return true

        } catch {
            let errorMessage = error.localizedDescription
            secureLogger.error("Failed to create post: \(errorMessage)")

            // Provide more specific error messages
            if errorMessage.contains("session") || errorMessage.contains("auth") {
                self.error = "認証エラー：再度ログインしてください"
            } else {
                self.error = "投稿の作成に失敗しました: \(errorMessage)"
            }
            return false
        }
    }

    //###########################################################################
    // MARK: - Delete Post Operation
    // Function: deletePost
    // Overview: Delete a post by ID
    // Processing: Execute delete query → Remove from local array
    //###########################################################################

    func deletePost(_ postId: UUID) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        secureLogger.info("Deleting post: \(postId)")

        do {
            _ = try await supabaseClient
                .from("posts")
                .delete()
                .eq("id", value: postId.uuidString)
                .execute()

            // ローカル配列からも削除
            posts.removeAll { $0.id == postId }

            secureLogger.info("Post deleted successfully: \(postId)")
            return true

        } catch {
            secureLogger.error("Failed to delete post: \(error.localizedDescription)")
            self.error = "投稿の削除に失敗しました"
            return false
        }
    }

    //###########################################################################
    // MARK: - Helper Methods
    // Function: mapDatabasePostToPost
    // Overview: Map DatabasePost to Post model
    // Processing: Extract fields → Handle anonymous flag → Return Post
    //###########################################################################

    private func mapDatabasePostToPost(_ dbPost: DatabasePost) -> Post {
        let name: String
        let avatar: String?
        if dbPost.is_anonymous ?? false {
            name = "匿名ユーザー"
            avatar = nil
        } else {
            name = "ユーザー"
            avatar = nil
        }
        return Post(
            id: dbPost.id,
            createdAt: dbPost.created_at,
            expiresAt: dbPost.expires_at,
            location: CLLocationCoordinate2D(
                latitude: dbPost.latitude,
                longitude: dbPost.longitude
            ),
            locationName: dbPost.location_name,
            imageData: nil,
            imageUrl: dbPost.image_url,
            text: dbPost.content,
            authorName: name,
            authorId: (dbPost.is_anonymous ?? false) ? "anonymous" : dbPost.user_id.uuidString,
            isAnonymous: dbPost.is_anonymous ?? false,
            authorAvatarUrl: avatar
        )
    }
}
