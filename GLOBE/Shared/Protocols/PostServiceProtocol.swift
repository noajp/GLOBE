//======================================================================
// MARK: - PostServiceProtocol.swift
// Purpose: Post service protocol for dependency injection
// Path: GLOBE/Core/Protocols/PostServiceProtocol.swift
//======================================================================

import Foundation
import CoreLocation
import Combine

protocol PostServiceProtocol: ObservableObject {
    // MARK: - Published Properties
    var posts: [Post] { get }
    var isLoading: Bool { get }
    var error: String? { get }

    // MARK: - Post Operations
    func fetchPosts() async
    func createPost(
        content: String,
        imageData: Data?,
        location: CLLocationCoordinate2D,
        locationName: String?,
        isAnonymous: Bool
    ) async throws

    func deletePost(_ postId: UUID) async -> Bool
    func toggleLike(for postId: UUID) async -> Bool
    func updatePosts(_ newPosts: [Post])
}

// MARK: - Default Implementation
extension PostServiceProtocol {
    func updatePosts(_ newPosts: [Post]) {
        // Default empty implementation - can be overridden
    }
}