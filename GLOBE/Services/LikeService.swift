//======================================================================
// MARK: - LikeService.swift
// Purpose: Like functionality service for managing post likes and unlike operations
// Path: GLOBE/Services/LikeService.swift
//======================================================================

import Foundation
import Combine

@MainActor
class LikeService: ObservableObject {
    static let shared = LikeService()
    
    @Published var likedPosts: Set<UUID> = []
    @Published var likeCounts: [UUID: Int] = [:]
    
    private init() {
        // Initialize service - no mock data
    }
    
    func toggleLike(for post: Post, userId: String) -> Bool {
        let postId = post.id
        let wasLiked = likedPosts.contains(postId)
        
        if wasLiked {
            // Unlike the post
            likedPosts.remove(postId)
            likeCounts[postId] = max(0, (likeCounts[postId] ?? 0) - 1)
        } else {
            // Like the post
            likedPosts.insert(postId)
            likeCounts[postId] = (likeCounts[postId] ?? 0) + 1
        }
        
        return !wasLiked // Return new like state
    }
    
    func isLiked(_ postId: UUID) -> Bool {
        return likedPosts.contains(postId)
    }
    
    func getLikeCount(for postId: UUID) -> Int {
        return likeCounts[postId] ?? 0
    }
    
    // MARK: - Database Integration Methods
    // TODO: Implement actual database loading
    
    func initializePost(_ post: Post) {
        // Initialize with zero likes - actual data should come from database
        if likeCounts[post.id] == nil {
            likeCounts[post.id] = 0
        }
    }
}