//======================================================================
// MARK: - CommentService.swift
// Function: Comment Management Service
// Overview: Handles comment CRUD operations with security validation
// Processing: Validate input → Database operations → Update local state
//======================================================================

import Foundation
import Combine
import Supabase

//###############################################################################
// MARK: - CommentService Class
//###############################################################################

@MainActor
class CommentService: ObservableObject {
    static let shared = CommentService()

    //###########################################################################
    // MARK: - Published Properties
    // Function: Reactive state for comments
    // Overview: Store comments and counts per post
    // Processing: @Published triggers UI updates when modified
    //###########################################################################

    @Published var comments: [UUID: [Comment]] = [:]
    @Published var commentCounts: [UUID: Int] = [:]

    //###########################################################################
    // MARK: - Private Properties
    //###########################################################################

    private var supabase: SupabaseClient { supabaseSync }
    private let logger = SecureLogger.shared

    private init() {}

    //###########################################################################
    // MARK: - Read Operations
    // Function: Retrieve comments and counts
    // Overview: Get comments for a specific post from local cache
    // Processing: Dictionary lookup with default empty array/zero
    //###########################################################################

    // Function: getComments
    // Overview: Get all comments for a post
    // Processing: Return cached comments array or empty if none exist
    func getComments(for postId: UUID) -> [Comment] {
        return comments[postId] ?? []
    }

    // Function: getCommentCount
    // Overview: Get total comment count for a post
    // Processing: Return cached count or zero if no comments
    func getCommentCount(for postId: UUID) -> Int {
        return commentCounts[postId] ?? 0
    }

    //###########################################################################
    // MARK: - Add Comment
    // Function: addComment
    // Overview: Create new comment with security validation
    // Processing: Validate content → Insert to DB → Update local cache
    //###########################################################################

    func addComment(to postId: UUID, content: String, authorId: String, authorName: String) async throws {
        // SECURITY: Validate comment content before insertion
        let validation = InputValidator.validatePostContent(content)
        guard validation.isValid, let sanitizedContent = validation.value else {
            logger.warning("Invalid comment content blocked")
            throw AppError.invalidInput(validation.errorMessage ?? "Invalid comment content")
        }

        // Insert to database with sanitized content
        let commentData: [String: AnyJSON] = [
            "user_id": .string(authorId),
            "post_id": .string(postId.uuidString),
            "content": .string(sanitizedContent)
        ]

        let result = try await supabase
            .from("comments")
            .insert(commentData)
            .select()
            .execute()

        // Decode response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let insertedComments = try decoder.decode([CommentResponse].self, from: result.data)

        guard let insertedComment = insertedComments.first else {
            throw AppError.unknown("Failed to insert comment")
        }

        // Create Comment object
        let comment = Comment(
            id: UUID(uuidString: insertedComment.id) ?? UUID(),
            postId: postId,
            text: sanitizedContent,
            authorName: authorName,
            authorId: authorId,
            createdAt: insertedComment.createdAt
        )

        // Update local state
        await MainActor.run {
            if comments[postId] == nil {
                comments[postId] = []
            }
            comments[postId]?.append(comment)
            commentCounts[postId] = comments[postId]?.count ?? 0
        }

        logger.info("Comment added successfully for post \(postId)")
    }

    //###########################################################################
    // MARK: - Load Comments
    // Function: loadComments
    // Overview: Fetch all comments for a post from database
    // Processing: Query DB with join → Decode response → Update local cache
    //###########################################################################

    func loadComments(for postId: UUID) {
        Task {
            do {
                let result = try await supabase
                    .from("comments")
                    .select("*, profiles!comments_user_id_fkey(display_name)")
                    .eq("post_id", value: postId.uuidString)
                    .order("created_at", ascending: true)
                    .execute()

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let commentResponses = try decoder.decode([CommentResponse].self, from: result.data)

                let loadedComments = commentResponses.compactMap { response -> Comment? in
                    guard let commentId = UUID(uuidString: response.id) else { return nil }
                    return Comment(
                        id: commentId,
                        postId: postId,
                        text: response.content,
                        authorName: response.profiles?.displayName ?? "Unknown",
                        authorId: response.userId,
                        createdAt: response.createdAt
                    )
                }

                await MainActor.run {
                    comments[postId] = loadedComments
                    commentCounts[postId] = loadedComments.count
                }

                logger.info("Loaded \(loadedComments.count) comments for post \(postId)")
            } catch {
                logger.error("Failed to load comments: \(error.localizedDescription)")
                await MainActor.run {
                    if comments[postId] == nil {
                        comments[postId] = []
                        commentCounts[postId] = 0
                    }
                }
            }
        }
    }
}

//###############################################################################
// MARK: - Response Models
// Function: Database response models
// Overview: Decodable structs for Supabase JSON responses
// Processing: Map snake_case DB fields to camelCase Swift properties
//###############################################################################

private struct CommentResponse: Decodable {
    let id: String
    let userId: String
    let postId: String
    let content: String
    let createdAt: Date
    let profiles: ProfileResponse?

    struct ProfileResponse: Decodable {
        let displayName: String
    }
}
