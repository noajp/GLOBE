//======================================================================
// MARK: - PostRepositoryTests.swift
// Purpose: Unit tests for PostRepository implementations
// Path: GLOBETests/Repositories/PostRepositoryTests.swift
//======================================================================

import XCTest
import CoreLocation
@testable import GLOBE

@MainActor
final class PostRepositoryTests: XCTestCase {

    // MARK: - Test Properties

    var postRepository: MockPostRepository!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()
        postRepository = MockPostRepository()
    }

    override func tearDown() async throws {
        postRepository = nil
        try await super.tearDown()
    }

    // MARK: - Get All Posts Tests

    func testGetAllPostsSuccess() async {
        // Act
        let posts = try! await postRepository.getAllPosts()

        // Assert
        XCTAssertEqual(postRepository.getAllPostsCallCount, 1)
        XCTAssertEqual(posts.count, MockPostRepository.samplePosts.count)
        XCTAssertEqual(posts.first?.userId, "user123")
        XCTAssertEqual(posts.first?.content, "Test post 1")
    }

    func testGetAllPostsFailure() async {
        // Arrange
        postRepository.simulateFailure(with: .networkError("Connection failed"))

        // Act & Assert
        do {
            _ = try await postRepository.getAllPosts()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(postRepository.getAllPostsCallCount, 1)
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - Get Post by ID Tests

    func testGetPostByIdSuccess() async {
        // Arrange
        let targetPost = MockPostRepository.samplePosts.first!

        // Act
        let post = try! await postRepository.getPost(by: targetPost.id)

        // Assert
        XCTAssertNotNil(post)
        XCTAssertEqual(post?.id, targetPost.id)
        XCTAssertEqual(post?.content, targetPost.content)
    }

    func testGetPostByIdNotFound() async {
        // Arrange
        let nonExistentId = UUID()

        // Act
        let post = try! await postRepository.getPost(by: nonExistentId)

        // Assert
        XCTAssertNil(post)
    }

    func testGetPostByIdFailure() async {
        // Arrange
        postRepository.simulateFailure()
        let testId = UUID()

        // Act & Assert
        do {
            _ = try await postRepository.getPost(by: testId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - Get Posts by User Tests

    func testGetPostsByUserSuccess() async {
        // Arrange
        let userId = "user123"

        // Act
        let posts = try! await postRepository.getPostsByUser(userId)

        // Assert
        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts.first?.userId, userId)
    }

    func testGetPostsByUserEmpty() async {
        // Arrange
        let userId = "nonexistent_user"

        // Act
        let posts = try! await postRepository.getPostsByUser(userId)

        // Assert
        XCTAssertTrue(posts.isEmpty)
    }

    func testGetPostsByUserFailure() async {
        // Arrange
        postRepository.simulateFailure()

        // Act & Assert
        do {
            _ = try await postRepository.getPostsByUser("test_user")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - Get Posts by Location Tests

    func testGetPostsByLocationSuccess() async {
        // Arrange
        let latitude = 35.6762
        let longitude = 139.6503
        let radius = 1000.0

        // Act
        let posts = try! await postRepository.getPostsByLocation(
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )

        // Assert
        XCTAssertGreaterThanOrEqual(posts.count, 0)
        // Check if posts are within reasonable distance (mock uses simple calculation)
        posts.forEach { post in
            let distance = sqrt(pow(post.latitude - latitude, 2) + pow(post.longitude - longitude, 2))
            XCTAssertLessThanOrEqual(distance, radius / 100000) // Mock conversion factor
        }
    }

    func testGetPostsByLocationEmpty() async {
        // Arrange - Use coordinates far from sample posts
        let latitude = 0.0
        let longitude = 0.0
        let radius = 100.0

        // Act
        let posts = try! await postRepository.getPostsByLocation(
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )

        // Assert
        XCTAssertTrue(posts.isEmpty)
    }

    func testGetPostsByLocationFailure() async {
        // Arrange
        postRepository.simulateFailure()

        // Act & Assert
        do {
            _ = try await postRepository.getPostsByLocation(
                latitude: 35.6762,
                longitude: 139.6503,
                radius: 1000.0
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - Create Post Tests

    func testCreatePostSuccess() async {
        // Arrange
        let initialCount = postRepository.mockPosts.count
        let newPost = Post(
            id: UUID(),
            userId: "test_user",
            content: "New test post",
            imageURL: nil,
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: "Tokyo",
            isAnonymous: false,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            isLikedByCurrentUser: false,
            authorProfile: nil
        )

        // Act
        let createdPost = try! await postRepository.createPost(newPost)

        // Assert
        XCTAssertEqual(postRepository.createPostCallCount, 1)
        XCTAssertEqual(postRepository.mockPosts.count, initialCount + 1)
        XCTAssertEqual(createdPost.content, newPost.content)
        XCTAssertEqual(createdPost.userId, newPost.userId)
        XCTAssertEqual(createdPost.likeCount, 0)
        XCTAssertEqual(createdPost.commentCount, 0)
        XCTAssertFalse(createdPost.isLikedByCurrentUser)

        // Check that the post was added to the beginning of the array
        XCTAssertEqual(postRepository.mockPosts.first?.content, newPost.content)
    }

    func testCreatePostFailure() async {
        // Arrange
        postRepository.simulateFailure(with: .validationError("Content too long"))
        let newPost = Post(
            id: UUID(),
            userId: "test_user",
            content: "Test post",
            imageURL: nil,
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: "Tokyo",
            isAnonymous: false,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            isLikedByCurrentUser: false,
            authorProfile: nil
        )

        // Act & Assert
        do {
            _ = try await postRepository.createPost(newPost)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(postRepository.createPostCallCount, 1)
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - Update Post Tests

    func testUpdatePostSuccess() async {
        // Arrange
        let existingPost = postRepository.mockPosts.first!
        let updatedPost = Post(
            id: existingPost.id,
            userId: existingPost.userId,
            content: "Updated content",
            imageURL: existingPost.imageURL,
            latitude: existingPost.latitude,
            longitude: existingPost.longitude,
            locationName: existingPost.locationName,
            isAnonymous: existingPost.isAnonymous,
            createdAt: existingPost.createdAt,
            likeCount: existingPost.likeCount,
            commentCount: existingPost.commentCount,
            isLikedByCurrentUser: existingPost.isLikedByCurrentUser,
            authorProfile: existingPost.authorProfile
        )

        // Act
        let success = try! await postRepository.updatePost(updatedPost)

        // Assert
        XCTAssertTrue(success)
        let postInRepo = postRepository.mockPosts.first { $0.id == existingPost.id }
        XCTAssertEqual(postInRepo?.content, "Updated content")
    }

    func testUpdatePostNotFound() async {
        // Arrange
        let nonExistentPost = Post(
            id: UUID(),
            userId: "test_user",
            content: "Non-existent post",
            imageURL: nil,
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: "Tokyo",
            isAnonymous: false,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            isLikedByCurrentUser: false,
            authorProfile: nil
        )

        // Act
        let success = try! await postRepository.updatePost(nonExistentPost)

        // Assert
        XCTAssertFalse(success)
    }

    func testUpdatePostFailure() async {
        // Arrange
        postRepository.simulateFailure()
        let testPost = MockPostRepository.samplePosts.first!

        // Act & Assert
        do {
            _ = try await postRepository.updatePost(testPost)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - Delete Post Tests

    func testDeletePostSuccess() async {
        // Arrange
        let postToDelete = postRepository.mockPosts.first!
        let initialCount = postRepository.mockPosts.count

        // Act
        let success = try! await postRepository.deletePost(postToDelete.id)

        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(postRepository.deletePostCallCount, 1)
        XCTAssertEqual(postRepository.mockPosts.count, initialCount - 1)
        XCTAssertFalse(postRepository.mockPosts.contains { $0.id == postToDelete.id })
    }

    func testDeletePostNotFound() async {
        // Arrange
        let nonExistentId = UUID()
        let initialCount = postRepository.mockPosts.count

        // Act
        let success = try! await postRepository.deletePost(nonExistentId)

        // Assert
        XCTAssertTrue(success) // Mock implementation returns true even if not found
        XCTAssertEqual(postRepository.mockPosts.count, initialCount) // No change
    }

    func testDeletePostFailure() async {
        // Arrange
        postRepository.simulateFailure()
        let testId = UUID()

        // Act & Assert
        do {
            _ = try await postRepository.deletePost(testId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(postRepository.deletePostCallCount, 1)
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - Like Post Tests

    func testLikePostSuccess() async {
        // Arrange
        let post = postRepository.mockPosts.first!
        let userId = "test_user"
        let initialLikeCount = post.likeCount

        // Act
        let success = try! await postRepository.likePost(postId: post.id, userId: userId)

        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(postRepository.toggleLikeCallCount, 1)

        let updatedPost = postRepository.mockPosts.first { $0.id == post.id }
        XCTAssertEqual(updatedPost?.likeCount, initialLikeCount + 1)
        XCTAssertTrue(updatedPost?.isLikedByCurrentUser ?? false)
    }

    func testLikePostNotFound() async {
        // Arrange
        let nonExistentId = UUID()
        let userId = "test_user"

        // Act
        let success = try! await postRepository.likePost(postId: nonExistentId, userId: userId)

        // Assert
        XCTAssertTrue(success) // Mock returns true even if post not found
        XCTAssertEqual(postRepository.toggleLikeCallCount, 1)
    }

    func testLikePostFailure() async {
        // Arrange
        postRepository.simulateFailure()
        let postId = UUID()
        let userId = "test_user"

        // Act & Assert
        do {
            _ = try await postRepository.likePost(postId: postId, userId: userId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(postRepository.toggleLikeCallCount, 1)
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - Unlike Post Tests

    func testUnlikePostSuccess() async {
        // Arrange
        let post = postRepository.mockPosts.first!
        let userId = "test_user"

        // First like the post to set up the test
        _ = try! await postRepository.likePost(postId: post.id, userId: userId)
        postRepository.toggleLikeCallCount = 0 // Reset counter

        let likeCount = postRepository.mockPosts.first { $0.id == post.id }?.likeCount ?? 0

        // Act
        let success = try! await postRepository.unlikePost(postId: post.id, userId: userId)

        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(postRepository.toggleLikeCallCount, 1)

        let updatedPost = postRepository.mockPosts.first { $0.id == post.id }
        XCTAssertEqual(updatedPost?.likeCount, max(0, likeCount - 1))
        XCTAssertFalse(updatedPost?.isLikedByCurrentUser ?? true)
    }

    func testUnlikePostFailure() async {
        // Arrange
        postRepository.simulateFailure()
        let postId = UUID()
        let userId = "test_user"

        // Act & Assert
        do {
            _ = try await postRepository.unlikePost(postId: postId, userId: userId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(postRepository.toggleLikeCallCount, 1)
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - Performance Tests

    func testPerformanceOfGetAllPosts() {
        // Create a large number of mock posts
        postRepository.mockPosts = Array(0..<1000).map { index in
            Post(
                id: UUID(),
                userId: "user_\(index)",
                content: "Test post \(index)",
                imageURL: nil,
                latitude: 35.6762 + Double(index) * 0.001,
                longitude: 139.6503 + Double(index) * 0.001,
                locationName: "Location \(index)",
                isAnonymous: false,
                createdAt: Date(),
                likeCount: index % 10,
                commentCount: index % 5,
                isLikedByCurrentUser: index % 3 == 0,
                authorProfile: nil
            )
        }

        measure {
            let expectation = XCTestExpectation(description: "Get all posts")
            Task {
                _ = try! await postRepository.getAllPosts()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testPerformanceOfLocationFiltering() {
        // Create posts in different locations
        postRepository.mockPosts = Array(0..<500).map { index in
            Post(
                id: UUID(),
                userId: "user_\(index)",
                content: "Test post \(index)",
                imageURL: nil,
                latitude: 35.0 + Double(index) * 0.01, // Spread across wider area
                longitude: 139.0 + Double(index) * 0.01,
                locationName: "Location \(index)",
                isAnonymous: false,
                createdAt: Date(),
                likeCount: 0,
                commentCount: 0,
                isLikedByCurrentUser: false,
                authorProfile: nil
            )
        }

        measure {
            let expectation = XCTestExpectation(description: "Filter by location")
            Task {
                _ = try! await postRepository.getPostsByLocation(
                    latitude: 35.6762,
                    longitude: 139.6503,
                    radius: 1000.0
                )
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
}