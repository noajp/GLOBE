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
            SecureLogger.shared.error("Failed to fetch all posts: \(error.localizedDescription)")
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
            SecureLogger.shared.error("Failed to get post by id: \(id) - \(error.localizedDescription)")
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
            SecureLogger.shared.error("Failed to get posts by user: \(userId) - \(error.localizedDescription)")
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
            SecureLogger.shared.error("Failed to get posts by location: \(error.localizedDescription)")
            throw AppError.from(error)
        }
    }

    // MARK: - Post Creation and Updates

    func createPost(_ post: Post) async throws -> Post {
        do {
            let iso = ISO8601DateFormatter()
            let payload: [String: AnyJSON] = [
                "user_id": .string(post.authorId),
                "content": .string(post.text),
                "image_url": post.imageUrl.map { .string($0) } ?? .null,
                "latitude": .double(post.latitude),
                "longitude": .double(post.longitude),
                "location_name": post.locationName.map { .string($0) } ?? .null,
                "is_anonymous": .bool(post.isAnonymous),
                "is_public": .bool(post.isPublic),
                "created_at": .string(iso.string(from: post.createdAt))
            ]

            let response = try await supabaseClient
                .from("posts")
                .insert(payload)
                .select()
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let createdPost = try decoder.decode(Post.self, from: response.data)
            SecureLogger.shared.info("Post created successfully - postId: \(createdPost.id.uuidString)")
            return createdPost
        } catch {
            SecureLogger.shared.error("Failed to create post: \(error.localizedDescription)")
            throw AppError.from(error)
        }
    }

    func updatePost(_ post: Post) async throws -> Bool {
        do {
            let iso = ISO8601DateFormatter()
            let updates: [String: AnyJSON] = [
                "content": .string(post.text),
                "image_url": post.imageUrl.map { .string($0) } ?? .null,
                "location_name": post.locationName.map { .string($0) } ?? .null,
                "latitude": .double(post.latitude),
                "longitude": .double(post.longitude),
                "is_anonymous": .bool(post.isAnonymous),
                "is_public": .bool(post.isPublic),
                "updated_at": .string(iso.string(from: Date()))
            ]

            _ = try await supabaseClient
                .from("posts")
                .update(updates)
                .eq("id", value: post.id.uuidString)
                .execute()

            SecureLogger.shared.info("Post updated successfully - postId: \(post.id.uuidString)")
            return true
        } catch {
            SecureLogger.shared.error("Failed to update post: \(error.localizedDescription)")
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

            SecureLogger.shared.info("Post deleted successfully - postId: \(postId.uuidString)")
            return true
        } catch {
            SecureLogger.shared.error("Failed to delete post: \(error.localizedDescription)")
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

            SecureLogger.shared.info("Post like toggled - postId: \(postId.uuidString), userId: \(userId)")
            return true
        } catch {
            SecureLogger.shared.error("Failed to like post: \(error.localizedDescription)")
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
        return PostRepository(supabaseClient: SupabaseManager.shared.syncClient, cacheRepository: cacheRepository)
    }
}
