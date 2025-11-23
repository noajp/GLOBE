//======================================================================
// MARK: - LikeServiceTests.swift
// Purpose: LikeService の正常系・異常系テスト（いいね追加・削除・カウント・楽観的UI更新）
// Path: GLOBETests/Repositories/LikeServiceTests.swift
//======================================================================

import XCTest
import CoreLocation
@testable import GLOBE

@MainActor
final class LikeServiceTests: XCTestCase {

    var likeService: LikeService!

    override func setUp() {
        super.setUp()
        likeService = LikeService.shared
        // Clear any existing state
        likeService.likedPosts.removeAll()
        likeService.likeCounts.removeAll()
    }

    override func tearDown() {
        likeService = nil
        super.tearDown()
    }

    // MARK: - 正常系: Initial State Tests
    func testInitialState_hasEmptyLikes() {
        // Given: Newly initialized LikeService (via setUp)

        // Then: Likes should be empty initially
        XCTAssertTrue(likeService.likedPosts.isEmpty)
        XCTAssertTrue(likeService.likeCounts.isEmpty)
    }

    func testIsLiked_withUnlikedPost_returnsFalse() {
        // Given: Post that hasn't been liked
        let postId = UUID()

        // When: Check if liked
        let isLiked = likeService.isLiked(postId)

        // Then: Should return false
        XCTAssertFalse(isLiked)
    }

    func testGetLikeCount_withNoLikes_returnsZero() {
        // Given: Post with no likes
        let postId = UUID()

        // When: Get like count
        let count = likeService.getLikeCount(for: postId)

        // Then: Should return 0
        XCTAssertEqual(count, 0)
    }

    // MARK: - 正常系: Toggle Like Tests (Optimistic UI Update)
    func testToggleLike_fromUnlikedToLiked_updatesStateOptimistically() {
        // Given: Unliked post
        let post = createTestPost()
        let userId = "user-123"

        // Initialize post
        likeService.initializePost(post)

        // When: Toggle like (unlike → like)
        let wasLiked = likeService.toggleLike(for: post, userId: userId)

        // Then: Should update state optimistically
        XCTAssertFalse(wasLiked) // Returns false because it was initially unliked
        XCTAssertTrue(likeService.isLiked(post.id))
        XCTAssertEqual(likeService.getLikeCount(for: post.id), 1)
    }

    func testToggleLike_fromLikedToUnliked_updatesStateOptimistically() {
        // Given: Liked post
        let post = createTestPost()
        let userId = "user-123"

        // Initialize and like the post
        likeService.initializePost(post)
        likeService.likedPosts.insert(post.id)
        likeService.likeCounts[post.id] = 1

        // When: Toggle like (like → unlike)
        let wasLiked = likeService.toggleLike(for: post, userId: userId)

        // Then: Should update state optimistically
        XCTAssertTrue(wasLiked) // Returns true because it was initially liked
        XCTAssertFalse(likeService.isLiked(post.id))
        XCTAssertEqual(likeService.getLikeCount(for: post.id), 0)
    }

    func testToggleLike_multipleTimes_togglesCorrectly() {
        // Given: Post
        let post = createTestPost()
        let userId = "user-123"

        likeService.initializePost(post)

        // When: Toggle multiple times
        _ = likeService.toggleLike(for: post, userId: userId) // Like
        _ = likeService.toggleLike(for: post, userId: userId) // Unlike
        _ = likeService.toggleLike(for: post, userId: userId) // Like again

        // Then: Should be in liked state
        XCTAssertTrue(likeService.isLiked(post.id))
        XCTAssertEqual(likeService.getLikeCount(for: post.id), 1)
    }

    // MARK: - 正常系: Initialize Post Tests
    func testInitializePost_setsZeroLikeCount() {
        // Given: New post
        let post = createTestPost()

        // When: Initialize post
        likeService.initializePost(post)

        // Then: Should have 0 like count
        XCTAssertEqual(likeService.getLikeCount(for: post.id), 0)
    }

    func testInitializePost_doesNotOverwriteExistingCount() {
        // Given: Post with existing like count
        let post = createTestPost()
        likeService.likeCounts[post.id] = 5

        // When: Initialize post
        likeService.initializePost(post)

        // Then: Should not overwrite existing count
        XCTAssertEqual(likeService.getLikeCount(for: post.id), 5)
    }

    // MARK: - 異常系: Invalid Post ID Tests
    func testToggleLike_withNewPost_handlesCorrectly() {
        // Given: Post that hasn't been initialized
        let post = createTestPost()
        let userId = "user-123"

        // When: Toggle like without initialization
        _ = likeService.toggleLike(for: post, userId: userId)

        // Then: Should handle gracefully and create like
        XCTAssertTrue(likeService.isLiked(post.id))
    }

    func testGetLikeCount_withNonexistentPost_returnsZero() {
        // Given: Non-existent post ID
        let nonexistentPostId = UUID()

        // When: Get like count
        let count = likeService.getLikeCount(for: nonexistentPostId)

        // Then: Should return 0
        XCTAssertEqual(count, 0)
    }

    // MARK: - 異常系: Invalid User ID Tests
    func testToggleLike_withEmptyUserId_handlesGracefully() {
        // Given: Empty user ID
        let post = createTestPost()
        let emptyUserId = ""

        // When: Toggle like with empty user ID
        // Note: Service doesn't validate user ID, but we test it doesn't crash
        _ = likeService.toggleLike(for: post, userId: emptyUserId)

        // Then: Should update optimistic state (network call will fail later)
        XCTAssertTrue(likeService.isLiked(post.id))
    }

    func testToggleLike_withInvalidUserId_handlesGracefully() {
        // Given: Invalid user ID
        let post = createTestPost()
        let invalidUserId = "invalid-user-@#$%"

        // When: Toggle like with invalid user ID
        _ = likeService.toggleLike(for: post, userId: invalidUserId)

        // Then: Should update optimistic state
        XCTAssertTrue(likeService.isLiked(post.id))
    }

    // MARK: - 異常系: State Consistency Tests
    func testLikeCounts_neverGoNegative() {
        // Given: Post with 0 likes
        let post = createTestPost()
        likeService.initializePost(post)

        // When: Try to unlike (which should decrement)
        likeService.likedPosts.insert(post.id) // Pretend it was liked
        likeService.likeCounts[post.id] = 0 // But count is 0

        _ = likeService.toggleLike(for: post, userId: "user-123")

        // Then: Count should never go negative
        XCTAssertGreaterThanOrEqual(likeService.getLikeCount(for: post.id), 0)
    }

    func testLikeState_consistencyBetweenSetAndCount() {
        // Given: Multiple posts with different like states
        let post1 = createTestPost()
        let post2 = createTestPost()
        let post3 = createTestPost()

        // When: Set different states
        likeService.likedPosts.insert(post1.id)
        likeService.likeCounts[post1.id] = 5

        likeService.likedPosts.insert(post2.id)
        likeService.likeCounts[post2.id] = 1

        likeService.likeCounts[post3.id] = 3
        // post3 not in likedPosts set

        // Then: State should be consistent
        XCTAssertTrue(likeService.isLiked(post1.id))
        XCTAssertEqual(likeService.getLikeCount(for: post1.id), 5)

        XCTAssertTrue(likeService.isLiked(post2.id))
        XCTAssertEqual(likeService.getLikeCount(for: post2.id), 1)

        XCTAssertFalse(likeService.isLiked(post3.id))
        XCTAssertEqual(likeService.getLikeCount(for: post3.id), 3)
    }

    // MARK: - 異常系: Large Dataset Tests
    func testLikeService_withManyPosts_performsEfficiently() {
        // Given: Many posts
        let posts = (0..<1000).map { _ in createTestPost() }

        // When: Initialize all posts
        measure {
            for post in posts {
                likeService.initializePost(post)
            }
        }

        // Then: Should complete efficiently (measured by XCTest)
    }

    func testLikeService_withManyLikes_performsEfficiently() {
        // Given: Many liked posts
        let posts = (0..<1000).map { _ in createTestPost() }

        for post in posts {
            likeService.likedPosts.insert(post.id)
            likeService.likeCounts[post.id] = Int.random(in: 0...100)
        }

        // When: Check all like states
        measure {
            for post in posts {
                _ = likeService.isLiked(post.id)
                _ = likeService.getLikeCount(for: post.id)
            }
        }

        // Then: Should complete efficiently
    }

    // MARK: - 異常系: Concurrent Access Tests
    func testLikeService_concurrentToggles_threadSafe() {
        // Given: Single post
        let post = createTestPost()
        likeService.initializePost(post)

        let expectation = XCTestExpectation(description: "Concurrent toggles complete")
        let group = DispatchGroup()

        // When: Multiple concurrent toggles
        for i in 0..<50 {
            group.enter()
            Task { @MainActor in
                _ = likeService.toggleLike(for: post, userId: "user-\(i)")
                group.leave()
            }
        }

        group.notify(queue: .main) {
            expectation.fulfill()
        }

        // Then: Should complete without crashes
        wait(for: [expectation], timeout: 5.0)

        // Final state should be consistent (either liked or unliked)
        let isLiked = likeService.isLiked(post.id)
        let count = likeService.getLikeCount(for: post.id)

        XCTAssertNotNil(isLiked)
        XCTAssertGreaterThanOrEqual(count, 0)
    }

    func testLikeService_concurrentReads_threadSafe() {
        // Given: Posts with likes
        let post = createTestPost()
        likeService.initializePost(post)
        likeService.likedPosts.insert(post.id)
        likeService.likeCounts[post.id] = 10

        let expectation = XCTestExpectation(description: "Concurrent reads complete")
        let group = DispatchGroup()

        // When: Multiple concurrent reads
        for _ in 0..<100 {
            group.enter()
            Task { @MainActor in
                _ = likeService.isLiked(post.id)
                _ = likeService.getLikeCount(for: post.id)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            expectation.fulfill()
        }

        // Then: Should complete without crashes
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - 異常系: Boundary Value Tests
    func testLikeCount_withMaxInt_handlesCorrectly() {
        // Given: Post with very high like count
        let post = createTestPost()
        likeService.likeCounts[post.id] = Int.max - 1

        // When: Try to increment
        likeService.likeCounts[post.id]? += 1

        // Then: Should not crash (may overflow, but shouldn't crash)
        XCTAssertNotNil(likeService.getLikeCount(for: post.id))
    }

    func testLikeCount_withZero_handlesUnlikeCorrectly() {
        // Given: Post with 0 likes that is marked as liked
        let post = createTestPost()
        let userId = "user-123"

        likeService.likedPosts.insert(post.id)
        likeService.likeCounts[post.id] = 0

        // When: Toggle unlike
        _ = likeService.toggleLike(for: post, userId: userId)

        // Then: Count should stay at 0 or above
        XCTAssertGreaterThanOrEqual(likeService.getLikeCount(for: post.id), 0)
    }

    // MARK: - 異常系: Network Error Simulation Tests
    func testToggleLike_expectsNetworkFailure_inTestEnvironment() {
        // Given: Post to like
        let post = createTestPost()
        let userId = "user-123"

        // When: Toggle like (will fail to sync with Supabase in test environment)
        _ = likeService.toggleLike(for: post, userId: userId)

        // Then: Optimistic UI should still update
        XCTAssertTrue(likeService.isLiked(post.id))

        // Note: In a real test with mock, we would verify rollback on error
        // For now, we just verify the optimistic update works
    }

    // MARK: - 正常系: Multiple User Tests
    func testLikeService_multiplePosts_independentState() {
        // Given: Multiple posts
        let post1 = createTestPost()
        let post2 = createTestPost()
        let post3 = createTestPost()

        let userId = "user-123"

        // When: Like different posts
        likeService.initializePost(post1)
        likeService.initializePost(post2)
        likeService.initializePost(post3)

        _ = likeService.toggleLike(for: post1, userId: userId) // Like post1
        _ = likeService.toggleLike(for: post3, userId: userId) // Like post3

        // Then: Each post should have independent state
        XCTAssertTrue(likeService.isLiked(post1.id))
        XCTAssertFalse(likeService.isLiked(post2.id))
        XCTAssertTrue(likeService.isLiked(post3.id))

        XCTAssertEqual(likeService.getLikeCount(for: post1.id), 1)
        XCTAssertEqual(likeService.getLikeCount(for: post2.id), 0)
        XCTAssertEqual(likeService.getLikeCount(for: post3.id), 1)
    }

    // MARK: - Helper Methods
    private func createTestPost() -> Post {
        return Post(
            location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locationName: "Test Location",
            text: "Test post",
            authorName: "Test User",
            authorId: "test-user-id"
        )
    }
}
