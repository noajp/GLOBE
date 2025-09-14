//======================================================================
// MARK: - PostRepository.swift
// Purpose: Post data repository implementation
// Path: GLOBE/Core/Repositories/PostRepository.swift
//======================================================================

import Foundation
import CoreLocation
import Supabase

@MainActor
class PostRepository: PostRepositoryProtocol {
    private let supabaseClient: SupabaseClient
    private let cacheRepository: CacheRepositoryProtocol

    init(supabaseClient: SupabaseClient, cacheRepository: CacheRepositoryProtocol) {
        self.supabaseClient = supabaseClient
        self.cacheRepository = cacheRepository
    }

    // MARK: - Post Retrieval

    func getAllPosts() async throws -> [Post] {
        do {
            let response = try await supabaseClient
                .from("posts")
                .select("""
                    id,
                    user_id,
                    content,
                    image_url,
                    latitude,
                    longitude,
                    location_name,
                    is_anonymous,
                    created_at,
                    like_count,
                    comment_count,
                    profiles!inner(id, username, display_name, avatar_url)
                """)
                .order("created_at", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let posts = try decoder.decode([Post].self, from: response.data)
            SecureLogger.shared.info("Retrieved \(posts.count) posts from database")
            return posts
        } catch {
            SecureLogger.shared.error("Failed to fetch all posts", error: error)
            throw AppError.from(error)
        }
    }

    func getPost(by id: UUID) async throws -> Post? {
        do {
            let response = try await supabaseClient
                .from("posts")
                .select("""
                    id,
                    user_id,
                    content,
                    image_url,
                    latitude,
                    longitude,
                    location_name,
                    is_anonymous,
                    created_at,
                    like_count,
                    comment_count,
                    profiles!inner(id, username, display_name, avatar_url)
                """)
                .eq("id", value: id.uuidString)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let post = try decoder.decode(Post.self, from: response.data)
            return post
        } catch {
            SecureLogger.shared.error("Failed to get post by id: \(id)", error: error)
            throw AppError.from(error)
        }
    }

    func getPostsByUser(_ userId: String) async throws -> [Post] {
        do {
            let response = try await supabaseClient
                .from("posts")
                .select("""
                    id,
                    user_id,
                    content,
                    image_url,
                    latitude,
                    longitude,
                    location_name,
                    is_anonymous,
                    created_at,
                    like_count,
                    comment_count,
                    profiles!inner(id, username, display_name, avatar_url)
                """)
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let posts = try decoder.decode([Post].self, from: response.data)
            return posts
        } catch {
            SecureLogger.shared.error("Failed to get posts by user: \(userId)", error: error)
            throw AppError.from(error)
        }
    }

    func getPostsByLocation(latitude: Double, longitude: Double, radius: Double) async throws -> [Post] {
        do {
            // Using PostgreSQL's earth_distance function for geospatial queries
            let response = try await supabaseClient
                .rpc("get_nearby_posts", params: [
                    "lat": latitude,
                    "lng": longitude,
                    "radius_meters": radius
                ])
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let posts = try decoder.decode([Post].self, from: response.data)
            return posts
        } catch {
            SecureLogger.shared.error("Failed to get posts by location", error: error)
            throw AppError.from(error)
        }
    }

    // MARK: - Post Creation and Updates

    func createPost(_ post: Post) async throws -> Post {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            let postData = try encoder.encode(post)
            let postDict = try JSONSerialization.jsonObject(with: postData) as? [String: Any]

            let response = try await supabaseClient
                .from("posts")
                .insert(postDict ?? [:])
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let createdPost = try decoder.decode(Post.self, from: response.data)
            SecureLogger.shared.info("Post created successfully", details: ["postId": createdPost.id.uuidString])
            return createdPost
        } catch {
            SecureLogger.shared.error("Failed to create post", error: error)
            throw AppError.from(error)
        }
    }

    func updatePost(_ post: Post) async throws -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            let postData = try encoder.encode(post)
            let postDict = try JSONSerialization.jsonObject(with: postData) as? [String: Any]

            _ = try await supabaseClient
                .from("posts")
                .update(postDict ?? [:])
                .eq("id", value: post.id.uuidString)
                .execute()

            SecureLogger.shared.info("Post updated successfully", details: ["postId": post.id.uuidString])
            return true
        } catch {
            SecureLogger.shared.error("Failed to update post", error: error)
            throw AppError.from(error)
        }
    }

    func deletePost(_ postId: UUID) async throws -> Bool {
        do {
            _ = try await supabaseClient
                .from("posts")
                .delete()
                .eq("id", value: postId.uuidString)
                .execute()

            SecureLogger.shared.info("Post deleted successfully", details: ["postId": postId.uuidString])
            return true
        } catch {
            SecureLogger.shared.error("Failed to delete post", error: error)
            throw AppError.from(error)
        }
    }

    // MARK: - Like Management

    func likePost(postId: UUID, userId: String) async throws -> Bool {
        do {
            // Use RPC function for atomic like operation
            _ = try await supabaseClient
                .rpc("toggle_like", params: [
                    "post_id": postId.uuidString,
                    "user_id": userId
                ])
                .execute()

            SecureLogger.shared.info("Post like toggled", details: [
                "postId": postId.uuidString,
                "userId": userId
            ])
            return true
        } catch {
            SecureLogger.shared.error("Failed to like post", error: error)
            throw AppError.from(error)
        }
    }

    func unlikePost(postId: UUID, userId: String) async throws -> Bool {
        // Same as likePost - toggle function handles both like and unlike
        return try await likePost(postId: postId, userId: userId)
    }
}

// MARK: - Repository Extension for Service Container

extension PostRepository {
    static func create() -> PostRepository {
        let cacheRepository = ServiceContainer.shared.resolve(CacheRepositoryProtocol.self) ?? CacheRepository()
        return PostRepository(supabaseClient: supabase, cacheRepository: cacheRepository)
    }
}