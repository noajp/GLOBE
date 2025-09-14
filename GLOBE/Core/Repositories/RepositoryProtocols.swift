//======================================================================
// MARK: - RepositoryProtocols.swift
// Purpose: Repository pattern protocols for data layer abstraction
// Path: GLOBE/Core/Repositories/RepositoryProtocols.swift
//======================================================================

import Foundation

// MARK: - User Repository Protocol

protocol UserRepositoryProtocol {
    func getUser(by id: String) async throws -> AppUser?
    func getCurrentUser() async throws -> AppUser?
    func updateUserProfile(_ user: AppUser) async throws -> Bool
    func deleteUser(_ userId: String) async throws -> Bool
    func getUserProfile(by id: String) async throws -> UserProfile?
    func updateUserProfile(_ profile: UserProfile) async throws -> Bool
}

// MARK: - Post Repository Protocol

protocol PostRepositoryProtocol {
    func getAllPosts() async throws -> [Post]
    func getPost(by id: UUID) async throws -> Post?
    func getPostsByUser(_ userId: String) async throws -> [Post]
    func getPostsByLocation(latitude: Double, longitude: Double, radius: Double) async throws -> [Post]
    func createPost(_ post: Post) async throws -> Post
    func updatePost(_ post: Post) async throws -> Bool
    func deletePost(_ postId: UUID) async throws -> Bool
    func likePost(postId: UUID, userId: String) async throws -> Bool
    func unlikePost(postId: UUID, userId: String) async throws -> Bool
}

// MARK: - Cache Repository Protocol

protocol CacheRepositoryProtocol {
    func cacheImage(data: Data, for key: String) async throws
    func getCachedImage(for key: String) async throws -> Data?
    func removeCachedImage(for key: String) async throws
    func clearAllCache() async throws
    func getCacheSize() async throws -> Int64
    func cacheUserProfile(_ profile: UserProfile, for userId: String) async throws
    func getCachedUserProfile(for userId: String) async throws -> UserProfile?
    func removeCachedUserProfile(for userId: String) async throws
}

// MARK: - Story Repository Protocol

protocol StoryRepositoryProtocol {
    func getAllStories() async throws -> [Story]
    func getActiveStories() async throws -> [Story]
    func getStory(by id: UUID) async throws -> Story?
    func createStory(_ story: Story) async throws -> Story
    func deleteStory(_ storyId: UUID) async throws -> Bool
}

// MARK: - Comment Repository Protocol

protocol CommentRepositoryProtocol {
    func getComments(for postId: UUID) async throws -> [Comment]
    func createComment(_ comment: Comment) async throws -> Comment
    func updateComment(_ comment: Comment) async throws -> Bool
    func deleteComment(_ commentId: UUID) async throws -> Bool
}