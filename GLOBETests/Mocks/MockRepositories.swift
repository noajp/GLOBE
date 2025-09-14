//======================================================================
// MARK: - MockRepositories.swift
// Purpose: Mock implementations for repository testing
// Path: GLOBETests/Mocks/MockRepositories.swift
//======================================================================

import Foundation
import CoreLocation
@testable import GLOBE

// MARK: - Mock User Repository

@MainActor
class MockUserRepository: UserRepositoryProtocol {

    // MARK: - Mock State
    var shouldSucceed = true
    var mockError: AppError = .unknown("Mock error")
    var mockUser: AppUser?
    var mockProfile: UserProfile?
    var getUserCallCount = 0
    var updateProfileCallCount = 0

    // MARK: - Mock Data
    static let sampleUser = AppUser(
        id: "user123",
        email: "test@example.com",
        username: "testuser",
        createdAt: "2024-01-01T00:00:00Z"
    )

    static let sampleProfile = UserProfile(
        id: "user123",
        username: "testuser",
        displayName: "Test User",
        bio: "Test bio",
        avatarUrl: "https://example.com/avatar.jpg",
        postCount: 5,
        followerCount: 10,
        followingCount: 15
    )

    // MARK: - UserRepositoryProtocol Implementation

    func getUser(by id: String) async throws -> AppUser? {
        getUserCallCount += 1

        if shouldSucceed {
            return mockUser ?? MockUserRepository.sampleUser
        } else {
            throw mockError
        }
    }

    func getCurrentUser() async throws -> AppUser? {
        if shouldSucceed {
            return mockUser ?? MockUserRepository.sampleUser
        } else {
            throw mockError
        }
    }

    func updateUserProfile(_ user: AppUser) async throws -> Bool {
        if shouldSucceed {
            mockUser = user
            return true
        } else {
            throw mockError
        }
    }

    func deleteUser(_ userId: String) async throws -> Bool {
        if shouldSucceed {
            mockUser = nil
            return true
        } else {
            throw mockError
        }
    }

    func getUserProfile(by id: String) async throws -> UserProfile? {
        if shouldSucceed {
            return mockProfile ?? MockUserRepository.sampleProfile
        } else {
            throw mockError
        }
    }

    func updateUserProfile(_ profile: UserProfile) async throws -> Bool {
        updateProfileCallCount += 1

        if shouldSucceed {
            mockProfile = profile
            return true
        } else {
            throw mockError
        }
    }
}

// MARK: - Mock Post Repository

@MainActor
class MockPostRepository: PostRepositoryProtocol {

    // MARK: - Mock State
    var shouldSucceed = true
    var mockError: AppError = .unknown("Mock error")
    var mockPosts: [Post] = []
    var getAllPostsCallCount = 0
    var createPostCallCount = 0
    var deletePostCallCount = 0
    var toggleLikeCallCount = 0

    // MARK: - Mock Data
    static let samplePosts: [Post] = [
        Post(
            id: UUID(),
            userId: "user123",
            content: "Test post 1",
            imageURL: nil,
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: "Tokyo",
            isAnonymous: false,
            createdAt: Date(),
            likeCount: 5,
            commentCount: 2,
            isLikedByCurrentUser: false,
            authorProfile: MockUserRepository.sampleProfile
        ),
        Post(
            id: UUID(),
            userId: "user456",
            content: "Test post 2",
            imageURL: "https://example.com/image.jpg",
            latitude: 35.6895,
            longitude: 139.6917,
            locationName: "Shinjuku",
            isAnonymous: true,
            createdAt: Date().addingTimeInterval(-3600),
            likeCount: 12,
            commentCount: 7,
            isLikedByCurrentUser: true,
            authorProfile: nil
        )
    ]

    init() {
        self.mockPosts = MockPostRepository.samplePosts
    }

    // MARK: - PostRepositoryProtocol Implementation

    func getAllPosts() async throws -> [Post] {
        getAllPostsCallCount += 1

        if shouldSucceed {
            return mockPosts
        } else {
            throw mockError
        }
    }

    func getPost(by id: UUID) async throws -> Post? {
        if shouldSucceed {
            return mockPosts.first { $0.id == id }
        } else {
            throw mockError
        }
    }

    func getPostsByUser(_ userId: String) async throws -> [Post] {
        if shouldSucceed {
            return mockPosts.filter { $0.userId == userId }
        } else {
            throw mockError
        }
    }

    func getPostsByLocation(latitude: Double, longitude: Double, radius: Double) async throws -> [Post] {
        if shouldSucceed {
            // Simple distance calculation for mock
            return mockPosts.filter { post in
                let distance = sqrt(pow(post.latitude - latitude, 2) + pow(post.longitude - longitude, 2))
                return distance <= radius / 100000 // Rough conversion
            }
        } else {
            throw mockError
        }
    }

    func createPost(_ post: Post) async throws -> Post {
        createPostCallCount += 1

        if shouldSucceed {
            let newPost = Post(
                id: post.id,
                userId: post.userId,
                content: post.content,
                imageURL: post.imageURL,
                latitude: post.latitude,
                longitude: post.longitude,
                locationName: post.locationName,
                isAnonymous: post.isAnonymous,
                createdAt: Date(),
                likeCount: 0,
                commentCount: 0,
                isLikedByCurrentUser: false,
                authorProfile: post.authorProfile
            )
            mockPosts.insert(newPost, at: 0)
            return newPost
        } else {
            throw mockError
        }
    }

    func updatePost(_ post: Post) async throws -> Bool {
        if shouldSucceed {
            if let index = mockPosts.firstIndex(where: { $0.id == post.id }) {
                mockPosts[index] = post
                return true
            }
            return false
        } else {
            throw mockError
        }
    }

    func deletePost(_ postId: UUID) async throws -> Bool {
        deletePostCallCount += 1

        if shouldSucceed {
            mockPosts.removeAll { $0.id == postId }
            return true
        } else {
            throw mockError
        }
    }

    func likePost(postId: UUID, userId: String) async throws -> Bool {
        toggleLikeCallCount += 1

        if shouldSucceed {
            if let index = mockPosts.firstIndex(where: { $0.id == postId }) {
                mockPosts[index].isLikedByCurrentUser = true
                mockPosts[index].likeCount += 1
            }
            return true
        } else {
            throw mockError
        }
    }

    func unlikePost(postId: UUID, userId: String) async throws -> Bool {
        toggleLikeCallCount += 1

        if shouldSucceed {
            if let index = mockPosts.firstIndex(where: { $0.id == postId }) {
                mockPosts[index].isLikedByCurrentUser = false
                mockPosts[index].likeCount = max(0, mockPosts[index].likeCount - 1)
            }
            return true
        } else {
            throw mockError
        }
    }
}

// MARK: - Mock Cache Repository

@MainActor
class MockCacheRepository: CacheRepositoryProtocol {

    // MARK: - Mock State
    var shouldSucceed = true
    var mockError: AppError = .storageError("Mock cache error")
    var cachedImages: [String: Data] = [:]
    var cachedProfiles: [String: UserProfile] = [:]
    var cacheImageCallCount = 0
    var getCacheImageCallCount = 0

    // MARK: - CacheRepositoryProtocol Implementation

    func cacheImage(data: Data, for key: String) async throws {
        cacheImageCallCount += 1

        if shouldSucceed {
            cachedImages[key] = data
        } else {
            throw mockError
        }
    }

    func getCachedImage(for key: String) async throws -> Data? {
        getCacheImageCallCount += 1

        if shouldSucceed {
            return cachedImages[key]
        } else {
            throw mockError
        }
    }

    func removeCachedImage(for key: String) async throws {
        if shouldSucceed {
            cachedImages.removeValue(forKey: key)
        } else {
            throw mockError
        }
    }

    func clearAllCache() async throws {
        if shouldSucceed {
            cachedImages.removeAll()
            cachedProfiles.removeAll()
        } else {
            throw mockError
        }
    }

    func getCacheSize() async throws -> Int64 {
        if shouldSucceed {
            let imageSize = cachedImages.values.reduce(0) { $0 + $1.count }
            return Int64(imageSize)
        } else {
            throw mockError
        }
    }

    func cacheUserProfile(_ profile: UserProfile, for userId: String) async throws {
        if shouldSucceed {
            cachedProfiles[userId] = profile
        } else {
            throw mockError
        }
    }

    func getCachedUserProfile(for userId: String) async throws -> UserProfile? {
        if shouldSucceed {
            return cachedProfiles[userId]
        } else {
            throw mockError
        }
    }

    func removeCachedUserProfile(for userId: String) async throws {
        if shouldSucceed {
            cachedProfiles.removeValue(forKey: userId)
        } else {
            throw mockError
        }
    }
}

// MARK: - Test Utilities

extension MockUserRepository {
    func reset() {
        shouldSucceed = true
        mockUser = nil
        mockProfile = nil
        getUserCallCount = 0
        updateProfileCallCount = 0
    }

    func simulateFailure(with error: AppError = .unknown("Mock error")) {
        shouldSucceed = false
        mockError = error
    }
}

extension MockPostRepository {
    func reset() {
        shouldSucceed = true
        mockPosts = MockPostRepository.samplePosts
        getAllPostsCallCount = 0
        createPostCallCount = 0
        deletePostCallCount = 0
        toggleLikeCallCount = 0
    }

    func simulateFailure(with error: AppError = .unknown("Mock error")) {
        shouldSucceed = false
        mockError = error
    }
}

extension MockCacheRepository {
    func reset() {
        shouldSucceed = true
        cachedImages.removeAll()
        cachedProfiles.removeAll()
        cacheImageCallCount = 0
        getCacheImageCallCount = 0
    }

    func simulateFailure(with error: AppError = .storageError("Mock error")) {
        shouldSucceed = false
        mockError = error
    }
}