//======================================================================
// MARK: - PostServiceTests.swift
// Purpose: Unit tests for PostService implementations
// Path: GLOBETests/Services/PostServiceTests.swift
//======================================================================

import XCTest
import Combine
import CoreLocation
@testable import GLOBE

@MainActor
final class PostServiceTests: XCTestCase {

    // MARK: - Test Properties

    var postService: MockPostService!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()
        postService = MockPostService()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        postService = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Fetch Posts Tests

    func testFetchPostsSuccess() async {
        // Act
        await postService.fetchPosts()

        // Assert
        XCTAssertEqual(postService.fetchPostsCallCount, 1)
        XCTAssertEqual(postService.posts.count, MockPostRepository.samplePosts.count)
        XCTAssertFalse(postService.isLoading)
        XCTAssertNil(postService.error)
    }

    func testFetchPostsWithDelay() async {
        // Arrange
        postService.mockDelay = 0.3
        let startTime = Date()

        // Act
        await postService.fetchPosts()

        // Assert
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(duration, 0.3)
        XCTAssertEqual(postService.fetchPostsCallCount, 1)
        XCTAssertFalse(postService.isLoading)
    }

    func testFetchPostsFailure() async {
        // Arrange
        postService.simulateFailure(with: .unknown("Network error"))

        // Act
        await postService.fetchPosts()

        // Assert
        XCTAssertEqual(postService.fetchPostsCallCount, 1)
        XCTAssertFalse(postService.isLoading)
        XCTAssertNotNil(postService.error)
        XCTAssertEqual(postService.error, "Network error")
    }

    func testFetchPostsIsLoadingState() {
        // Arrange
        postService.mockDelay = 0.2
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []

        postService.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 3 { // Initial false, true during loading, false after
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        Task {
            await postService.fetchPosts()
        }

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates[0], false) // Initial state
        XCTAssertEqual(loadingStates[1], true)  // During loading
        XCTAssertEqual(loadingStates[2], false) // After completion
    }

    // MARK: - Create Post Tests

    func testCreatePostSuccess() async {
        // Arrange
        let content = "Test post content"
        let imageData = Data("fake image".utf8)
        let location = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        let locationName = "Tokyo"
        let isAnonymous = false
        let initialCount = postService.posts.count

        // Act
        try! await postService.createPost(
            content: content,
            imageData: imageData,
            location: location,
            locationName: locationName,
            isAnonymous: isAnonymous
        )

        // Assert
        XCTAssertEqual(postService.createPostCallCount, 1)
        XCTAssertEqual(postService.posts.count, initialCount + 1)
        XCTAssertFalse(postService.isLoading)
        XCTAssertNil(postService.error)

        // Check the created post properties
        let createdPost = postService.posts.first!
        XCTAssertEqual(createdPost.content, content)
        XCTAssertEqual(createdPost.userId, "test_user_123")
        XCTAssertEqual(createdPost.latitude, location.latitude)
        XCTAssertEqual(createdPost.longitude, location.longitude)
        XCTAssertEqual(createdPost.locationName, locationName)
        XCTAssertEqual(createdPost.isAnonymous, isAnonymous)
        XCTAssertEqual(createdPost.likeCount, 0)
        XCTAssertEqual(createdPost.commentCount, 0)
        XCTAssertFalse(createdPost.isLikedByMe)
        XCTAssertEqual(createdPost.imageURL, "mock://image.jpg")
    }

    func testCreatePostWithoutImage() async {
        // Arrange
        let content = "Post without image"
        let location = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

        // Act
        try! await postService.createPost(
            content: content,
            imageData: nil,
            location: location,
            locationName: "Tokyo",
            isAnonymous: false
        )

        // Assert
        XCTAssertEqual(postService.createPostCallCount, 1)
        let createdPost = postService.posts.first!
        XCTAssertNil(createdPost.imageURL)
        XCTAssertEqual(createdPost.content, content)
    }

    func testCreatePostAnonymous() async {
        // Arrange
        let content = "Anonymous post"
        let location = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

        // Act
        try! await postService.createPost(
            content: content,
            imageData: nil,
            location: location,
            locationName: "Tokyo",
            isAnonymous: true
        )

        // Assert
        let createdPost = postService.posts.first!
        XCTAssertTrue(createdPost.isAnonymous)
        XCTAssertEqual(createdPost.userId, "test_user_123") // Mock still uses same user ID
    }

    func testCreatePostFailure() async {
        // Arrange
        postService.simulateFailure(with: .unknown("Content validation failed"))
        let initialCount = postService.posts.count

        // Act & Assert
        do {
            try await postService.createPost(
                content: "Invalid content",
                imageData: nil,
                location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                locationName: nil,
                isAnonymous: false
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(postService.createPostCallCount, 1)
            XCTAssertEqual(postService.posts.count, initialCount) // No new post added
            XCTAssertFalse(postService.isLoading)
            XCTAssertTrue(error is AuthError)
        }
    }

    // MARK: - Delete Post Tests

    func testDeletePostSuccess() async {
        // Arrange
        let postToDelete = postService.posts.first!
        let initialCount = postService.posts.count

        // Act
        let success = await postService.deletePost(postToDelete.id)

        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(postService.deletePostCallCount, 1)
        XCTAssertEqual(postService.posts.count, initialCount - 1)
        XCTAssertFalse(postService.posts.contains { $0.id == postToDelete.id })
        XCTAssertNil(postService.error)
    }

    func testDeleteNonExistentPost() async {
        // Arrange
        let nonExistentId = UUID()
        let initialCount = postService.posts.count

        // Act
        let success = await postService.deletePost(nonExistentId)

        // Assert
        XCTAssertTrue(success) // Mock returns true even if post doesn't exist
        XCTAssertEqual(postService.deletePostCallCount, 1)
        XCTAssertEqual(postService.posts.count, initialCount) // No change in count
    }

    func testDeletePostFailure() async {
        // Arrange
        postService.simulateFailure(with: .unknown("Delete failed"))
        let postId = UUID()

        // Act
        let success = await postService.deletePost(postId)

        // Assert
        XCTAssertFalse(success)
        XCTAssertEqual(postService.deletePostCallCount, 1)
        XCTAssertEqual(postService.error, "Failed to delete post")
    }

    // MARK: - Toggle Like Tests

    func testToggleLikeSuccess() async {
        // Arrange
        let post = postService.posts.first!
        let initialLikeCount = post.likeCount
        let initialLikedState = post.isLikedByMe

        // Act
        let success = await postService.toggleLike(for: post.id)

        // Assert
        XCTAssertTrue(success)
        let updatedPost = postService.posts.first { $0.id == post.id }!
        XCTAssertEqual(updatedPost.isLikedByMe, !initialLikedState)

        if initialLikedState {
            XCTAssertEqual(updatedPost.likeCount, initialLikeCount - 1)
        } else {
            XCTAssertEqual(updatedPost.likeCount, initialLikeCount + 1)
        }
    }

    func testToggleLikeMultipleTimes() async {
        // Arrange
        let post = postService.posts.first!
        let initialLikeCount = post.likeCount

        // Act & Assert - First toggle (like)
        var success = await postService.toggleLike(for: post.id)
        XCTAssertTrue(success)
        var updatedPost = postService.posts.first { $0.id == post.id }!
        XCTAssertTrue(updatedPost.isLikedByMe)
        XCTAssertEqual(updatedPost.likeCount, initialLikeCount + 1)

        // Act & Assert - Second toggle (unlike)
        success = await postService.toggleLike(for: post.id)
        XCTAssertTrue(success)
        updatedPost = postService.posts.first { $0.id == post.id }!
        XCTAssertFalse(updatedPost.isLikedByMe)
        XCTAssertEqual(updatedPost.likeCount, initialLikeCount)
    }

    func testToggleLikeNonExistentPost() async {
        // Arrange
        let nonExistentId = UUID()

        // Act
        let success = await postService.toggleLike(for: nonExistentId)

        // Assert
        XCTAssertFalse(success) // Mock returns false if post not found
    }

    func testToggleLikeFailure() async {
        // Arrange
        postService.simulateFailure()
        let postId = UUID()

        // Act
        let success = await postService.toggleLike(for: postId)

        // Assert
        XCTAssertFalse(success)
    }

    // MARK: - Update Posts Tests

    func testUpdatePosts() {
        // Arrange
        let newPosts = [TestHelpers.createMockPost(content: "New post 1"),
                       TestHelpers.createMockPost(content: "New post 2")]

        // Act
        postService.updatePosts(newPosts)

        // Assert
        XCTAssertEqual(postService.posts.count, 2)
        XCTAssertEqual(postService.posts[0].content, "New post 1")
        XCTAssertEqual(postService.posts[1].content, "New post 2")
    }

    func testUpdatePostsWithEmptyArray() {
        // Arrange
        XCTAssertFalse(postService.posts.isEmpty) // Initially has sample posts

        // Act
        postService.updatePosts([])

        // Assert
        XCTAssertTrue(postService.posts.isEmpty)
    }

    // MARK: - Published Properties Tests

    func testPostsPublishedProperty() {
        // Arrange
        let expectation = XCTestExpectation(description: "Posts published")
        var postUpdates: [[Post]] = []
        let newPost = TestHelpers.createMockPost(content: "Published test post")

        postService.$posts
            .sink { posts in
                postUpdates.append(posts)
                if postUpdates.count >= 2 { // Initial posts + new post
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        Task {
            try! await postService.createPost(
                content: newPost.content,
                imageData: nil,
                location: CLLocationCoordinate2D(latitude: newPost.latitude, longitude: newPost.longitude),
                locationName: newPost.locationName,
                isAnonymous: newPost.isAnonymous
            )
        }

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(postUpdates.count, 2)
        XCTAssertGreaterThan(postUpdates[1].count, postUpdates[0].count)
        XCTAssertEqual(postUpdates[1].first?.content, newPost.content)
    }

    func testErrorPublishedProperty() {
        // Arrange
        let expectation = XCTestExpectation(description: "Error published")
        var errorUpdates: [String?] = []

        postService.$error
            .sink { error in
                errorUpdates.append(error)
                if errorUpdates.count >= 2 { // Initial nil + error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        postService.simulateFailure(with: .unknown("Test error"))
        Task {
            await postService.fetchPosts()
        }

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(errorUpdates.count, 2)
        XCTAssertNil(errorUpdates[0])
        XCTAssertEqual(errorUpdates[1], "Test error")
    }

    // MARK: - Mock Helper Tests

    func testResetHelper() {
        // Arrange - Modify state
        postService.simulateFailure()
        postService.createPostCallCount = 5
        postService.fetchPostsCallCount = 3
        postService.deletePostCallCount = 2
        postService.posts = []
        postService.error = "Test error"

        // Act
        postService.reset()

        // Assert
        XCTAssertTrue(postService.shouldSucceed)
        XCTAssertEqual(postService.posts.count, MockPostRepository.samplePosts.count)
        XCTAssertFalse(postService.isLoading)
        XCTAssertNil(postService.error)
        XCTAssertEqual(postService.createPostCallCount, 0)
        XCTAssertEqual(postService.fetchPostsCallCount, 0)
        XCTAssertEqual(postService.deletePostCallCount, 0)
    }

    func testSimulateFailureHelper() {
        // Arrange
        let customError = AuthError.unknown("Custom error message")

        // Act
        postService.simulateFailure(with: customError)

        // Assert
        XCTAssertFalse(postService.shouldSucceed)
        if case .unknown(let message) = postService.mockError {
            XCTAssertEqual(message, "Custom error message")
        } else {
            XCTFail("Expected unknown error with custom message")
        }
    }

    func testSimulateNetworkErrorHelper() {
        // Act
        postService.simulateNetworkError()

        // Assert
        XCTAssertFalse(postService.shouldSucceed)
        if case .unknown(let message) = postService.mockError {
            XCTAssertEqual(message, "Network connection failed")
        } else {
            XCTFail("Expected network connection error")
        }
    }

    func testSimulateEmptyPostsHelper() {
        // Arrange
        XCTAssertFalse(postService.posts.isEmpty) // Initially has sample posts

        // Act
        postService.simulateEmptyPosts()

        // Assert
        XCTAssertTrue(postService.posts.isEmpty)
    }

    func testAddMockPostHelper() {
        // Arrange
        let initialCount = postService.posts.count

        // Act
        let addedPost = postService.addMockPost()

        // Assert
        XCTAssertEqual(postService.posts.count, initialCount + 1)
        XCTAssertEqual(postService.posts.last?.id, addedPost.id)
        XCTAssertEqual(addedPost.content, "Mock post content")
        XCTAssertEqual(addedPost.userId, "test_user_123")
        XCTAssertEqual(addedPost.locationName, "Tokyo")
        XCTAssertFalse(addedPost.isAnonymous)
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentCreatePost() async {
        // Arrange
        let contents = Array(0..<10).map { "Concurrent post \($0)" }

        // Act
        await withTaskGroup(of: Bool.self) { group in
            for content in contents {
                group.addTask { [weak self] in
                    do {
                        try await self?.postService.createPost(
                            content: content,
                            imageData: nil,
                            location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                            locationName: "Tokyo",
                            isAnonymous: false
                        )
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var successCount = 0
            for await success in group {
                if success { successCount += 1 }
            }

            // Assert
            XCTAssertEqual(successCount, contents.count)
            XCTAssertEqual(postService.createPostCallCount, contents.count)
        }
    }

    func testConcurrentToggleLike() async {
        // Arrange
        let post = postService.posts.first!
        let toggleCount = 20

        // Act
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<toggleCount {
                group.addTask { [weak self] in
                    return await self?.postService.toggleLike(for: post.id) ?? false
                }
            }

            var successCount = 0
            for await success in group {
                if success { successCount += 1 }
            }

            // Assert
            XCTAssertEqual(successCount, toggleCount)
        }
    }

    // MARK: - Performance Tests

    func testPerformanceOfFetchPosts() {
        postService.mockDelay = 0.01 // Reduce delay for performance test

        measure {
            let expectation = XCTestExpectation(description: "Fetch posts performance")
            Task {
                await postService.fetchPosts()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }

    func testPerformanceOfCreatePost() {
        postService.mockDelay = 0.01

        measure {
            let expectation = XCTestExpectation(description: "Create post performance")
            Task {
                try! await postService.createPost(
                    content: "Performance test post",
                    imageData: nil,
                    location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                    locationName: "Tokyo",
                    isAnonymous: false
                )
                postService.reset() // Reset for next iteration
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }

    // MARK: - Edge Case Tests

    func testCreatePostWithExtremeLongContent() async {
        // Arrange
        let longContent = String(repeating: "A", count: 10000)

        // Act
        try! await postService.createPost(
            content: longContent,
            imageData: nil,
            location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locationName: "Tokyo",
            isAnonymous: false
        )

        // Assert - Mock doesn't validate content length
        XCTAssertEqual(postService.posts.first?.content, longContent)
    }

    func testCreatePostWithExtremeCoordinates() async {
        // Arrange
        let extremeLocation = CLLocationCoordinate2D(latitude: 90.0, longitude: 180.0)

        // Act
        try! await postService.createPost(
            content: "Extreme location post",
            imageData: nil,
            location: extremeLocation,
            locationName: "North Pole",
            isAnonymous: false
        )

        // Assert
        let createdPost = postService.posts.first!
        XCTAssertEqual(createdPost.latitude, 90.0)
        XCTAssertEqual(createdPost.longitude, 180.0)
    }

    func testMultipleFetchPostsCalls() async {
        // Act
        await postService.fetchPosts()
        await postService.fetchPosts()
        await postService.fetchPosts()

        // Assert
        XCTAssertEqual(postService.fetchPostsCallCount, 3)
        XCTAssertEqual(postService.posts.count, MockPostRepository.samplePosts.count)
    }
}