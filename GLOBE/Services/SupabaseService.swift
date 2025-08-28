//======================================================================
// MARK: - SupabaseService.swift
// Purpose: Supabase database operations for posts, likes, comments, and profiles
// Path: GLOBE/Services/SupabaseService.swift
//======================================================================

import Foundation
import Supabase
import CoreLocation

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let secureConfig = SecureConfiguration()
    private let secureLogger = SecureLogger.shared
    
    // Supabase client
    private let supabaseClient: SupabaseClient
    
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {
        supabaseClient = SupabaseClient(
            supabaseURL: secureConfig.supabaseUrl,
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
        
        do {
            // Supabaseクエリを実行
            let response = try await supabaseClient
                .from("posts")
                .select("*, profiles(*)")
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
            
            // レスポンスをパース
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let dbPosts = try decoder.decode([DatabasePost].self, from: response.data)
            
            // DatabasePostをPostモデルに変換
            await MainActor.run {
                self.posts = dbPosts.map { dbPost in
                    Post(
                        id: dbPost.id,
                        location: CLLocationCoordinate2D(
                            latitude: dbPost.latitude,
                            longitude: dbPost.longitude
                        ),
                        locationName: dbPost.location_name,
                        imageData: nil,
                        imageUrl: dbPost.image_url,
                        text: dbPost.content,
                        authorName: dbPost.profiles?.display_name ?? dbPost.profiles?.username ?? "匿名ユーザー",
                        authorId: dbPost.user_id.uuidString
                    )
                }
            }
            
            secureLogger.info("Successfully fetched \(posts.count) posts from database")
            
        } catch {
            secureLogger.error("Failed to fetch posts: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "投稿の取得に失敗しました"
                self.posts = []
            }
        }
    }
    
    
    func createPostWithRPC(
        userId: String,
        content: String,
        imageData: Data?,
        latitude: Double,
        longitude: Double,
        locationName: String?
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
            
            let postData: [String: AnyJSON] = [
                "user_id": .string(userUUID.uuidString),
                "content": .string(content),
                "image_url": imageUrl.map { .string($0) } ?? .null,
                "location_name": locationName.map { .string($0) } ?? .null,
                "latitude": .double(latitude),
                "longitude": .double(longitude),
                "is_public": .bool(true),
                "expires_at": .string(ISO8601DateFormatter().string(from: Date().addingTimeInterval(24 * 60 * 60)))
            ]
            
            _ = try await supabaseClient
                .from("posts")
                .insert(postData)
                .execute()
            
            // 成功したら新しい投稿をローカル配列に追加
            let newPost = Post(
                location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                locationName: locationName,
                imageData: imageData,
                imageUrl: imageUrl,
                text: content,
                authorName: AuthManager.shared.currentUser?.username ?? "匿名ユーザー",
                authorId: userId
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

struct PostInsert: Codable {
    let user_id: UUID
    let content: String
    let image_url: String?
    let location_name: String?
    let latitude: Double
    let longitude: Double
    let is_public: Bool
    let expires_at: Date
}