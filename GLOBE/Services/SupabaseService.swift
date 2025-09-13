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
    
    // Supabase client
    private let supabaseClient: SupabaseClient
    
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?
    
private init() {
        let urlString = secureConfig.supabaseURL
        print("🔧 SupabaseService - Using URL: \(urlString)")
        print("🔧 SupabaseService - Using Key: \(secureConfig.supabaseAnonKey.prefix(20))...")
        
        guard let url = URL(string: urlString) else {
            fatalError("Invalid Supabase URL: \(urlString)")
        }
        
        supabaseClient = SupabaseClient(
            supabaseURL: url,
            supabaseKey: secureConfig.supabaseAnonKey
        )
    }
    
    // MARK: - Posts
    
    func fetchUserPosts(userId: String) async -> [Post] {
        // TODO: 実際のSupabase SDKを使用して実装
        return []
    }
    
    func fetchPosts() async {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        secureLogger.info("Fetching posts from database")

        let maxAttempts = 3
        var lastError: NSError?

        for attempt in 1...maxAttempts {
            do {
                // Degrade payload on retries to improve reliability on poor networks
                let liteMode = attempt > 1
                let selectColumns = liteMode
                    ? "id,user_id,content,image_url,location_name,latitude,longitude,is_public,is_anonymous,created_at"
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

                await MainActor.run {
                    self.posts = dbPosts.map { dbPost in
                        let name: String
                        let avatar: String?
                        if dbPost.is_anonymous ?? false {
                            name = "匿名ユーザー"
                            avatar = nil
                        } else if let prof = dbPost.profiles, !liteMode {
                            name = prof.display_name ?? prof.username ?? "ユーザー"
                            avatar = prof.avatar_url
                        } else {
                            name = "ユーザー"
                            avatar = nil
                        }
                        return Post(
                            id: dbPost.id,
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

                secureLogger.info("Successfully fetched \(posts.count) posts (attempt #\(attempt), lite=\(attempt > 1))")
                return
            } catch {
                let nsErr = error as NSError
                lastError = nsErr
                let isTimeout = nsErr.domain == NSURLErrorDomain && nsErr.code == NSURLErrorTimedOut
                let isNetwork = nsErr.domain == NSURLErrorDomain
                secureLogger.warning("fetchPosts attempt #\(attempt) failed: \(nsErr.domain) \(nsErr.code) - \(nsErr.localizedDescription)")

                if attempt < maxAttempts && (isTimeout || isNetwork) {
                    let delay = UInt64(500_000_000) * UInt64(attempt) // 0.5s, 1.0s
                    try? await Task.sleep(nanoseconds: delay)
                    continue
                } else {
                    break
                }
            }
        }

        // Final failure: keep existing posts to avoid blank UI
        await MainActor.run {
            if let e = lastError {
                self.error = "投稿の取得に失敗しました（\(e.code == NSURLErrorTimedOut ? "タイムアウト" : e.localizedDescription)）"
            } else {
                self.error = "投稿の取得に失敗しました"
            }
            // Do not clear self.posts here; keep the last known posts for UX stability
        }
    }
    
    
    func createPostWithRPC(
        userId: String,
        content: String,
        imageData: Data?,
        latitude: Double,
        longitude: Double,
        locationName: String?,
        isAnonymous: Bool = false
    ) async -> Bool {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        secureLogger.info("Creating post using direct insert")
        
        do {
            guard let userUUID = UUID(uuidString: userId) else {
                await MainActor.run { 
                    self.error = "ユーザーIDが無効です"
                }
                return false
            }
            
            // 画像をアップロード（もしあれば）
            var imageUrl: String? = nil
            if let imageData = imageData {
                let fileName = "\(userId)/post_\(UUID().uuidString).jpg"
                
                do {
                    _ = try await supabaseClient.storage
                        .from("posts")
                        .upload(fileName, data: imageData)
                    
                    imageUrl = try supabaseClient.storage
                        .from("posts")
                        .getPublicURL(path: fileName)
                        .absoluteString
                        
                } catch {
                    await MainActor.run {
                        self.error = "画像のアップロードに失敗しました"
                    }
                    return false
                }
            }
            
            var postData: [String: AnyJSON] = [
                "user_id": .string(userUUID.uuidString),
                "content": .string(content),
                "image_url": imageUrl.map { .string($0) } ?? .null,
                "location_name": locationName.map { .string($0) } ?? .null,
                "latitude": .double(latitude),
                "longitude": .double(longitude),
                "is_public": .bool(!isAnonymous),  // 匿名でない場合は公開
                "expires_at": .string(ISO8601DateFormatter().string(from: Date().addingTimeInterval(24 * 60 * 60)))
            ]
            
            // is_anonymousフィールドを追加（データベースカラム追加済み）
            postData["is_anonymous"] = .bool(isAnonymous)
            print("📝 SupabaseService - Creating post with isAnonymous: \(isAnonymous), isPublic: \(!isAnonymous)")
            
            _ = try await supabaseClient
                .from("posts")
                .insert(postData)
                .execute()
            
            // 成功したら新しい投稿をローカル配列に追加
            let currentUser = AuthManager.shared.currentUser
            
            // プロフィール情報を取得してアバターURLを取得
            var avatarUrl: String? = nil
            if !isAnonymous {
                do {
                    let profileResponse = try await supabaseClient
                        .from("profiles")
                        .select("avatar_url")
                        .eq("id", value: userUUID.uuidString)
                        .single()
                        .execute()
                    
                    let data = profileResponse.data
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let url = json["avatar_url"] as? String {
                        avatarUrl = url
                    }
                } catch {
                    // プロフィール取得エラーは無視（アバターなしで続行）
                    print("⚠️ Failed to fetch avatar URL: \(error)")
                }
            }
            
            let newPost = Post(
                location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                locationName: locationName,
                imageData: imageData,
                imageUrl: imageUrl,
                text: content,
                authorName: isAnonymous ? "匿名ユーザー" : (currentUser?.username ?? "ユーザー"),
                authorId: isAnonymous ? "anonymous" : userId,
                isPublic: !isAnonymous,
                isAnonymous: isAnonymous,
                authorAvatarUrl: avatarUrl
            )
            
            await MainActor.run {
                posts.insert(newPost, at: 0)
            }
            
            return true
            
        } catch {
            secureLogger.error("Failed to create post: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "投稿の作成に失敗しました"
            }
            return false
        }
    }
    
    // MARK: - Delete Posts
    
    func deletePost(_ postId: UUID) async -> Bool {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        secureLogger.info("Deleting post: \(postId)")
        
        do {
            _ = try await supabaseClient
                .from("posts")
                .delete()
                .eq("id", value: postId.uuidString)
                .execute()
            
            // ローカル配列からも削除
            await MainActor.run {
                posts.removeAll { $0.id == postId }
            }
            
            secureLogger.info("Post deleted successfully: \(postId)")
            return true
            
        } catch {
            secureLogger.error("Failed to delete post: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "投稿の削除に失敗しました"
            }
            return false
        }
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
    let username: String?
    let display_name: String?
    let avatar_url: String?
}

struct DatabaseLike: Codable {
    let id: UUID?
    let post_id: UUID
    let user_id: UUID
    let created_at: Date?
}
