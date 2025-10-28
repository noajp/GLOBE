//======================================================================
// MARK: - CommentService.swift
// Purpose: Service for managing comments functionality
// Path: GLOBE/Services/CommentService.swift
//======================================================================

import Foundation
import Combine
import Supabase

@MainActor
class CommentService: ObservableObject {
    static let shared = CommentService()

    @Published var comments: [UUID: [Comment]] = [:]
    @Published var commentCounts: [UUID: Int] = [:]

    private var supabase: SupabaseClient { supabaseSync }
    private let logger = SecureLogger.shared

    private init() {}

    // MARK: - Get Comments
    func getComments(for postId: UUID) -> [Comment] {
        return comments[postId] ?? []
    }

    func getCommentCount(for postId: UUID) -> Int {
        return commentCounts[postId] ?? 0
    }

    // MARK: - Add Comment
    func addComment(to postId: UUID, content: String, authorId: String, authorName: String) async throws {
        // Insert to database
        let commentData: [String: AnyJSON] = [
            "user_id": .string(authorId),
            "post_id": .string(postId.uuidString),
            "content": .string(content)
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
            throw NSError(domain: "CommentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to insert comment"])
        }

        // Create Comment object
        let comment = Comment(
            id: UUID(uuidString: insertedComment.id) ?? UUID(),
            postId: postId,
            text: content,
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

        logger.info("Comment added successfully")
    }

    // MARK: - Load Comments
    func loadComments(for postId: UUID) {
        Task {
            do {
                let result = try await supabase
                    .from("comments")
                    .select("*, profiles!comments_user_id_fkey(username)")
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
                        authorName: response.profiles?.username ?? "Unknown",
                        authorId: response.userId,
                        createdAt: response.createdAt
                    )
                }

                await MainActor.run {
                    comments[postId] = loadedComments
                    commentCounts[postId] = loadedComments.count
                }

                logger.info("Loaded \(loadedComments.count) comments")
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

// MARK: - Response Models
private struct CommentResponse: Decodable {
    let id: String
    let userId: String
    let postId: String
    let content: String
    let createdAt: Date
    let profiles: ProfileResponse?

    struct ProfileResponse: Decodable {
        let username: String
    }
}