//======================================================================
// MARK: - SearchViewModel.swift
// Function: Search ViewModel
// Overview: Manages user search state and operations
// Processing: Query users → Filter current user → Update results
//======================================================================

import Foundation
import Combine

//###############################################################################
// MARK: - SearchViewModel Class
//###############################################################################

@MainActor
final class SearchViewModel: ObservableObject {

    //###########################################################################
    // MARK: - Published Properties
    // Function: Reactive state for search
    // Overview: Track search query, results, and loading state
    // Processing: @Published triggers UI updates automatically
    //###########################################################################

    @Published var searchQuery: String = ""
    @Published var searchResults: [UserProfile] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?

    //###########################################################################
    // MARK: - Private Properties
    //###########################################################################

    private let logger = SecureLogger.shared
    private let authManager = AuthManager.shared
    private var searchTask: Task<Void, Never>?

    //###########################################################################
    // MARK: - Search Operations
    // Function: performSearch
    // Overview: Search users and filter out current user
    // Processing: Validate query → Call service → Filter results → Update state
    //###########################################################################

    func performSearch(query: String) {
        // Cancel previous search if still running
        searchTask?.cancel()

        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        logger.info("Starting search for query: \(query)")

        searchTask = Task {
            let results = await SupabaseService.shared.searchUsers(query: query)

            // Check if task was cancelled
            guard !Task.isCancelled else {
                logger.info("Search cancelled for query: \(query)")
                return
            }

            logger.info("Received \(results.count) search results")

            // Filter out current user
            if let currentUserId = authManager.currentUser?.id {
                searchResults = results.filter { $0.id.lowercased() != currentUserId.lowercased() }
                logger.info("Filtered to \(searchResults.count) results (excluded current user)")
            } else {
                searchResults = results
                logger.info("Showing all \(searchResults.count) results")
            }

            isSearching = false
        }
    }

    //###########################################################################
    // MARK: - Follow Management
    // Function: Follow/unfollow user
    // Overview: Toggle follow status for a user
    // Processing: Call service → Return success status
    //###########################################################################

    func toggleFollow(userId: String, isCurrentlyFollowing: Bool) async -> Bool {
        logger.info("Toggling follow for user: \(userId), current status: \(isCurrentlyFollowing)")

        if isCurrentlyFollowing {
            let success = await SupabaseService.shared.unfollowUser(userId: userId)
            logger.info("Unfollow \(success ? "succeeded" : "failed")")
            return !success  // Return new follow state
        } else {
            let success = await SupabaseService.shared.followUser(userId: userId)
            logger.info("Follow \(success ? "succeeded" : "failed")")
            return success
        }
    }

    func checkFollowStatus(userId: String) async -> Bool {
        return await SupabaseService.shared.isFollowing(userId: userId)
    }

    //###########################################################################
    // MARK: - Cleanup
    //###########################################################################

    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
    }
}
