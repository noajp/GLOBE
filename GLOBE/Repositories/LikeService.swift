//======================================================================
// MARK: - LikeService.swift
// Purpose: Like functionality service for managing post likes and unlike operations
// Path: GLOBE/Services/LikeService.swift
//======================================================================

import Foundation
import Combine
import Supabase

@MainActor
class LikeService: ObservableObject {
    static let shared = LikeService()

    @Published var likedPosts: Set<UUID> = []
    @Published var likeCounts: [UUID: Int] = [:]

    private var supabase: SupabaseClient { supabaseSync }

    private init() {
    }

    // MARK: - Toggle Like
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
                print("❌ LikeService: Failed to toggle like: \(error)")
            }
        }

        return !wasLiked
    }

    // MARK: - Database Operations
    private func likePost(postId: UUID, userId: String) async throws {
        let likeData: [String: AnyJSON] = [
            "user_id": .string(userId),
            "post_id": .string(postId.uuidString)
        ]

        try await supabase
            .from("likes")
            .insert(likeData)
            .execute()

        print("✅ LikeService: Liked post \(postId)")
    }

    private func unlikePost(postId: UUID, userId: String) async throws {
        try await supabase
            .from("likes")
            .delete()
            .eq("user_id", value: userId)
            .eq("post_id", value: postId.uuidString)
            .execute()

        print("✅ LikeService: Unliked post \(postId)")
    }

    // MARK: - Load Likes
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

            print("✅ LikeService: Loaded likes for post \(postId): count=\(count)")
        } catch {
            print("❌ LikeService: Failed to load likes: \(error)")
        }
    }

    func isLiked(_ postId: UUID) -> Bool {
        return likedPosts.contains(postId)
    }

    func getLikeCount(for postId: UUID) -> Int {
        return likeCounts[postId] ?? 0
    }

    func initializePost(_ post: Post) {
        if likeCounts[post.id] == nil {
            likeCounts[post.id] = 0
        }
    }
}

// MARK: - Response Models
private struct LikeResponse: Decodable {
    let id: String
}