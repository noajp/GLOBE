//======================================================================
// MARK: - LikeService.swift
// Function: Like Management Service
// Overview: Handle post like/unlike operations with optimistic UI updates
// Processing: Toggle likes → Sync to database → Revert on error
//======================================================================

import Foundation
import Combine
import Supabase

//###############################################################################
// MARK: - LikeService Class
//###############################################################################

@MainActor
class LikeService: ObservableObject {
    static let shared = LikeService()

    //###########################################################################
    // MARK: - Published Properties
    // Function: Reactive state for likes
    // Overview: Track liked posts and like counts per post
    // Processing: @Published triggers UI updates when modified
    //###########################################################################

    @Published var likedPosts: Set<UUID> = []
    @Published var likeCounts: [UUID: Int] = [:]

    //###########################################################################
    // MARK: - Private Properties
    //###########################################################################

    private var supabase: SupabaseClient { supabaseSync }
    private let logger = SecureLogger.shared

    private init() {}

    //###########################################################################
    // MARK: - Toggle Like
    // Function: toggleLike
    // Overview: Like or unlike a post with optimistic UI update
    // Processing: Update UI immediately → Sync to DB → Revert if failed
    //###########################################################################

    func toggleLike(for post: Post, userId: String) -> Bool {
        let postId = post.id
        let wasLiked = likedPosts.contains(postId)

        // Optimistic UI update
        if wasLiked {
            likedPosts.remove(postId)
            likeCounts[postId] = max(0, (likeCounts[postId] ?? 0) - 1)
        } else {
            likedPosts.insert(postId)
            likeCounts[postId] = (likeCounts[postId] ?? 0) + 1
        }

        // Sync with database
        Task {
            do {
                if wasLiked {
                    try await unlikePost(postId: postId, userId: userId)
                } else {
                    try await likePost(postId: postId, userId: userId)
                }
            } catch {
                // Revert on error
                if wasLiked {
                    likedPosts.insert(postId)
                    likeCounts[postId] = (likeCounts[postId] ?? 0) + 1
                } else {
                    likedPosts.remove(postId)
                    likeCounts[postId] = max(0, (likeCounts[postId] ?? 0) - 1)
                }
                logger.error("Failed to toggle like: \(error.localizedDescription)")
            }
        }

        return !wasLiked
    }

    //###########################################################################
    // MARK: - Database Operations
    // Function: Database sync operations
    // Overview: Insert/delete like records in Supabase
    // Processing: Execute SQL operations and log results
    //###########################################################################

    // Function: likePost
    // Overview: Insert a new like record
    // Processing: Insert user_id and post_id into likes table
    private func likePost(postId: UUID, userId: String) async throws {
        let likeData: [String: AnyJSON] = [
            "user_id": .string(userId),
            "post_id": .string(postId.uuidString)
        ]

        try await supabase
            .from("likes")
            .insert(likeData)
            .execute()

        logger.info("Post liked successfully: post_id=\(postId)")
    }

    // Function: unlikePost
    // Overview: Delete an existing like record
    // Processing: Delete where user_id and post_id match
    private func unlikePost(postId: UUID, userId: String) async throws {
        try await supabase
            .from("likes")
            .delete()
            .eq("user_id", value: userId)
            .eq("post_id", value: postId.uuidString)
            .execute()

        logger.info("Post unliked successfully: post_id=\(postId)")
    }

    //###########################################################################
    // MARK: - Load Likes
    // Function: loadLikes
    // Overview: Fetch like count and user's like status for a post
    // Processing: Query total count → Check if user liked → Update local state
    //###########################################################################

    func loadLikes(for postId: UUID, userId: String?) async {
        do {
            // Get like count
            let countResult = try await supabase
                .from("likes")
                .select("id", head: false, count: .exact)
                .eq("post_id", value: postId.uuidString)
                .execute()

            let count = countResult.count ?? 0
            await MainActor.run {
                likeCounts[postId] = count
            }

            // Check if current user liked this post
            if let userId = userId {
                let userLikeResult = try await supabase
                    .from("likes")
                    .select("id")
                    .eq("post_id", value: postId.uuidString)
                    .eq("user_id", value: userId)
                    .execute()

                let decoder = JSONDecoder()
                let likes = try? decoder.decode([LikeResponse].self, from: userLikeResult.data)
                let isLiked = !(likes?.isEmpty ?? true)

                await MainActor.run {
                    if isLiked {
                        likedPosts.insert(postId)
                    } else {
                        likedPosts.remove(postId)
                    }
                }
            }

        } catch {
            logger.error("Failed to load likes: \(error.localizedDescription)")
        }
    }

    //###########################################################################
    // MARK: - Query Methods
    // Function: Check like status and counts
    // Overview: Get cached like information
    // Processing: Dictionary/Set lookups with default values
    //###########################################################################

    // Function: isLiked
    // Overview: Check if user liked a post
    // Processing: Check if postId exists in likedPosts set
    func isLiked(_ postId: UUID) -> Bool {
        return likedPosts.contains(postId)
    }

    // Function: getLikeCount
    // Overview: Get total like count for a post
    // Processing: Return cached count or zero if not loaded
    func getLikeCount(for postId: UUID) -> Int {
        return likeCounts[postId] ?? 0
    }

    // Function: initializePost
    // Overview: Initialize like count for new post
    // Processing: Set count to zero if not already initialized
    func initializePost(_ post: Post) {
        if likeCounts[post.id] == nil {
            likeCounts[post.id] = 0
        }
    }
}

//###############################################################################
// MARK: - Response Models
// Function: Database response models
// Overview: Decodable structs for Supabase JSON responses
// Processing: Map database fields to Swift properties
//###############################################################################

private struct LikeResponse: Decodable {
    let id: String
}
