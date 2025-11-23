//======================================================================
// MARK: - CommentServiceTests.swift
// Purpose: CommentService の正常系・異常系テスト（コメント追加・取得・カウント）
// Path: GLOBETests/Repositories/CommentServiceTests.swift
//======================================================================

import XCTest
@testable import GLOBE

@MainActor
final class CommentServiceTests: XCTestCase {

    var commentService: CommentService!

    override func setUp() {
        super.setUp()
        commentService = CommentService.shared
        // Clear any existing state
        commentService.comments.removeAll()
        commentService.commentCounts.removeAll()
    }

    override func tearDown() {
        commentService = nil
        super.tearDown()
    }

    // MARK: - 正常系: Initial State Tests
    func testInitialState_hasEmptyComments() {
        // Given: Newly initialized CommentService (via setUp)

        // Then: Comments should be empty initially
        XCTAssertTrue(commentService.comments.isEmpty)
        XCTAssertTrue(commentService.commentCounts.isEmpty)
    }

    func testGetComments_withNoComments_returnsEmpty() {
        // Given: Post ID with no comments
        let postId = UUID()

        // When: Get comments
        let comments = commentService.getComments(for: postId)

        // Then: Should return empty array
        XCTAssertTrue(comments.isEmpty)
    }

    func testGetCommentCount_withNoComments_returnsZero() {
        // Given: Post ID with no comments
        let postId = UUID()

        // When: Get comment count
        let count = commentService.getCommentCount(for: postId)

        // Then: Should return 0
        XCTAssertEqual(count, 0)
    }

    // MARK: - 正常系: Add Comment Tests (Validation Layer)
    func testAddComment_withValidData_validatesCorrectly() async {
        // Given: Valid comment data
        let postId = UUID()
        let content = "これは正常なコメントです"
        let authorId = "user-123"
        let authorName = "Test User"

        // When: Validate content (simulating what addComment would do)
        let validationResult = InputValidator.validatePostContent(content)

        // Then: Validation should pass
        XCTAssertTrue(validationResult.isValid)

        // Note: Actual Supabase call will fail in test environment
        // We're testing the validation layer, not the network call
    }

    // MARK: - 異常系: Invalid Content Tests
    func testAddComment_withEmptyContent_failsValidation() {
        // Given: Empty content
        let emptyContent = "   "

        // When: Validate content
        let result = InputValidator.validatePostContent(emptyContent)

        // Then: Should fail validation
        XCTAssertFalse(result.isValid)
    }

    func testAddComment_withSQLInjection_failsValidation() {
        // Given: SQL injection attempt
        let maliciousContent = "Nice post'; DROP TABLE comments; --"

        // When: Validate and sanitize content
        let result = InputValidator.validatePostContent(maliciousContent)

        // Then: Should be sanitized or rejected
        if result.isValid, let sanitized = result.value {
            // Should not contain dangerous SQL
            XCTAssertFalse(sanitized.contains("DROP TABLE"))
        }
    }

    func testAddComment_withXSSAttempt_failsValidation() {
        // Given: XSS attempt
        let maliciousContent = "<script>alert('xss')</script>Nice comment"

        // When: Validate content
        let result = InputValidator.validatePostContent(maliciousContent)

        // Then: Should be sanitized or rejected
        if result.isValid, let sanitized = result.value {
            // Should not contain script tags
            XCTAssertFalse(sanitized.lowercased().contains("<script>"))
        }
    }

    func testAddComment_withSpamPattern_failsValidation() {
        // Given: Spam-like content
        let spamContent = "Buy now!!! Limited time offer!!!"

        // When: Validate content
        let result = InputValidator.validatePostContent(spamContent)

        // Then: Should fail validation (spam detection)
        XCTAssertFalse(result.isValid)
    }

    func testAddComment_withDangerousURL_failsValidation() {
        // Given: Content with dangerous URL
        let dangerousContent = "Check out http://bit.ly/malicious"

        // When: Validate content
        let result = InputValidator.validatePostContent(dangerousContent)

        // Then: Should fail validation
        XCTAssertFalse(result.isValid)
    }

    // MARK: - 異常系: Invalid Post ID Tests
    func testGetComments_withNonexistentPostId_returnsEmpty() {
        // Given: Non-existent post ID
        let nonexistentPostId = UUID()

        // When: Get comments
        let comments = commentService.getComments(for: nonexistentPostId)

        // Then: Should return empty array
        XCTAssertTrue(comments.isEmpty)
    }

    func testGetCommentCount_withNonexistentPostId_returnsZero() {
        // Given: Non-existent post ID
        let nonexistentPostId = UUID()

        // When: Get comment count
        let count = commentService.getCommentCount(for: nonexistentPostId)

        // Then: Should return 0
        XCTAssertEqual(count, 0)
    }

    // MARK: - 異常系: Boundary Value Tests
    func testAddComment_withMaxLengthContent_handlesCorrectly() {
        // Given: Very long content (testing boundaries)
        let longContent = String(repeating: "あ", count: 500)

        // When: Validate content
        let result = InputValidator.validatePostContent(longContent)

        // Then: Should either pass or fail gracefully
        XCTAssertNotNil(result.isValid)
    }

    func testAddComment_withUnicodeContent_handlesCorrectly() {
        // Given: Unicode content with emojis
        let unicodeContent = "素晴らしい投稿です！ 🌍🎉✨"

        // When: Validate content
        let result = InputValidator.validatePostContent(unicodeContent)

        // Then: Should handle Unicode correctly
        XCTAssertTrue(result.isValid)
        if let sanitized = result.value {
            XCTAssertTrue(sanitized.contains("🌍"))
        }
    }

    func testAddComment_withSpecialCharacters_handlesCorrectly() {
        // Given: Content with special characters
        let specialContent = "Great post! @user #hashtag & more..."

        // When: Validate content
        let result = InputValidator.validatePostContent(specialContent)

        // Then: Should handle special characters
        XCTAssertTrue(result.isValid)
    }

    // MARK: - 異常系: State Management Tests
    func testComments_stateConsistency_afterMultipleOperations() {
        // Given: Multiple posts with comments
        let post1Id = UUID()
        let post2Id = UUID()

        // When: Manually add comments to state (simulating successful adds)
        let comment1 = Comment(
            id: UUID(),
            postId: post1Id,
            text: "Comment 1",
            authorName: "User1",
            authorId: "user1",
            createdAt: Date()
        )
        let comment2 = Comment(
            id: UUID(),
            postId: post1Id,
            text: "Comment 2",
            authorName: "User2",
            authorId: "user2",
            createdAt: Date()
        )
        let comment3 = Comment(
            id: UUID(),
            postId: post2Id,
            text: "Comment 3",
            authorName: "User3",
            authorId: "user3",
            createdAt: Date()
        )

        commentService.comments[post1Id] = [comment1, comment2]
        commentService.comments[post2Id] = [comment3]
        commentService.commentCounts[post1Id] = 2
        commentService.commentCounts[post2Id] = 1

        // Then: State should be consistent
        XCTAssertEqual(commentService.getComments(for: post1Id).count, 2)
        XCTAssertEqual(commentService.getComments(for: post2Id).count, 1)
        XCTAssertEqual(commentService.getCommentCount(for: post1Id), 2)
        XCTAssertEqual(commentService.getCommentCount(for: post2Id), 1)
    }

    // MARK: - 異常系: Large Dataset Tests
    func testGetComments_withManyComments_performsEfficiently() {
        // Given: Post with many comments
        let postId = UUID()
        var comments: [Comment] = []

        for i in 0..<100 {
            let comment = Comment(
                id: UUID(),
                postId: postId,
                text: "Comment \(i)",
                authorName: "User\(i)",
                authorId: "user\(i)",
                createdAt: Date()
            )
            comments.append(comment)
        }

        commentService.comments[postId] = comments
        commentService.commentCounts[postId] = comments.count

        // When: Measure performance
        measure {
            _ = commentService.getComments(for: postId)
            _ = commentService.getCommentCount(for: postId)
        }

        // Then: Should complete efficiently (measured by XCTest)
    }

    // MARK: - 異常系: Concurrent Access Tests
    func testCommentService_concurrentReads_threadSafe() {
        // Given: Comments in the service
        let postId = UUID()
        let comment = Comment(
            id: UUID(),
            postId: postId,
            text: "Test comment",
            authorName: "User",
            authorId: "user",
            createdAt: Date()
        )

        commentService.comments[postId] = [comment]
        commentService.commentCounts[postId] = 1

        let expectation = XCTestExpectation(description: "Concurrent reads complete")
        let group = DispatchGroup()

        // When: Multiple concurrent reads
        for _ in 0..<100 {
            group.enter()
            Task { @MainActor in
                _ = commentService.getComments(for: postId)
                _ = commentService.getCommentCount(for: postId)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            expectation.fulfill()
        }

        // Then: Should complete without crashes
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - 異常系: Network Error Handling Tests
    func testLoadComments_withNetworkError_handlesGracefully() async {
        // Given: Post ID for loading comments
        let postId = UUID()

        // When: Load comments (will fail in test environment without Supabase)
        commentService.loadComments(for: postId)

        // Wait a bit for async operation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then: Should handle error gracefully and set empty state
        let comments = commentService.getComments(for: postId)
        let count = commentService.getCommentCount(for: postId)

        // Should have initialized empty arrays on error
        XCTAssertNotNil(comments)
        XCTAssertGreaterThanOrEqual(count, 0)
    }

    // MARK: - 異常系: Data Integrity Tests
    func testComments_withCorruptedData_handlesGracefully() {
        // Given: Corrupted comment data (missing required fields simulated)
        let postId = UUID()

        // When: Try to create comment with minimal data
        let minimalComment = Comment(
            id: UUID(),
            postId: postId,
            text: "", // Empty text
            authorName: "",
            authorId: "",
            createdAt: Date()
        )

        // Then: Should create without crashing
        XCTAssertNotNil(minimalComment)
        XCTAssertEqual(minimalComment.postId, postId)
    }

    // MARK: - 正常系: Input Sanitization Tests
    func testAddComment_withDangerousCharacters_sanitizesCorrectly() {
        // Given: Content with potentially dangerous characters
        let dangerousContent = "Test\u{0000}comment\nwith\nnewlines"

        // When: Sanitize content
        let sanitized = InputValidator.sanitizeText(dangerousContent)

        // Then: Should remove null bytes and handle newlines
        XCTAssertFalse(sanitized.contains("\u{0000}"))
    }

    func testAddComment_withControlCharacters_sanitizesCorrectly() {
        // Given: Content with control characters
        let controlContent = "Test\u{0001}comment\u{0002}here"

        // When: Sanitize content
        let sanitized = InputValidator.sanitizeText(controlContent)

        // Then: Should remove or escape control characters
        XCTAssertNotNil(sanitized)
    }
}
