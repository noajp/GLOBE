//======================================================================
// MARK: - FollowManager.swift
// Purpose: Unified follow/unfollow logic management
// Path: GLOBE/ViewModels/FollowManager.swift
//======================================================================

import Foundation
import SwiftUI
import Combine

//###########################################################################
// MARK: - Follow Manager
// Function: FollowManager
// Overview: Centralized manager for all follow/unfollow operations
// Processing: Handle follow state → Call Supabase → Update counts → Notify observers
//###########################################################################

@MainActor
class FollowManager: ObservableObject {
    static let shared = FollowManager()

    // MARK: - Published Properties
    @Published var followStatusCache: [String: Bool] = [:] // userId -> isFollowing

    // MARK: - Dependencies
    private let supabaseService = SupabaseService.shared
    private let logger = SecureLogger.shared

    private init() {}

    //###########################################################################
    // MARK: - Follow/Unfollow Operations
    // Function: toggleFollow
    // Overview: Toggle follow status for a user
    // Processing: Check current status → Call follow/unfollow → Update cache → Return success
    //###########################################################################

    func toggleFollow(userId: String) async -> Bool {
        let currentStatus = await isFollowing(userId: userId)

        if currentStatus {
            return await unfollowUser(userId: userId)
        } else {
            return await followUser(userId: userId)
        }
    }

    func followUser(userId: String) async -> Bool {
        logger.info("Following user: \(userId)")

        let success = await supabaseService.followUser(userId: userId)

        if success {
            followStatusCache[userId] = true
            logger.info("Successfully followed user: \(userId)")
        } else {
            logger.error("Failed to follow user: \(userId)")
        }

        return success
    }

    func unfollowUser(userId: String) async -> Bool {
        logger.info("Unfollowing user: \(userId)")

        let success = await supabaseService.unfollowUser(userId: userId)

        if success {
            followStatusCache[userId] = false
            logger.info("Successfully unfollowed user: \(userId)")
        } else {
            logger.error("Failed to unfollow user: \(userId)")
        }

        return success
    }

    //###########################################################################
    // MARK: - Status Checking
    // Function: isFollowing
    // Overview: Check if current user is following specified user
    // Processing: Check cache → If not cached, fetch from Supabase → Update cache → Return status
    //###########################################################################

    func isFollowing(userId: String) async -> Bool {
        // Check cache first
        if let cachedStatus = followStatusCache[userId] {
            return cachedStatus
        }

        // Fetch from Supabase
        let status = await supabaseService.isFollowing(userId: userId)
        followStatusCache[userId] = status

        return status
    }

    //###########################################################################
    // MARK: - Count Operations
    // Function: getFollowerCount, getFollowingCount
    // Overview: Get follower/following counts for a user
    // Processing: Call Supabase → Return count
    //###########################################################################

    func getFollowerCount(userId: String) async -> Int {
        return await supabaseService.getFollowerCount(userId: userId)
    }

    func getFollowingCount(userId: String) async -> Int {
        return await supabaseService.getFollowingCount(userId: userId)
    }

    //###########################################################################
    // MARK: - Cache Management
    // Function: clearCache, invalidateCache
    // Overview: Manage follow status cache
    // Processing: Clear all or specific user cache
    //###########################################################################

    func clearCache() {
        followStatusCache.removeAll()
        logger.info("Follow status cache cleared")
    }

    func invalidateCache(for userId: String) {
        followStatusCache.removeValue(forKey: userId)
        logger.info("Follow status cache invalidated for user: \(userId)")
    }

    //###########################################################################
    // MARK: - Batch Operations
    // Function: checkFollowStatus
    // Overview: Check follow status for multiple users
    // Processing: Batch check → Update cache → Return results
    //###########################################################################

    func checkFollowStatus(for userIds: [String]) async -> [String: Bool] {
        var results: [String: Bool] = [:]

        for userId in userIds {
            results[userId] = await isFollowing(userId: userId)
        }

        return results
    }
}
