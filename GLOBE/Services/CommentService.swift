//======================================================================
// MARK: - CommentService.swift
// Purpose: Service for managing comments functionality
// Path: GLOBE/Services/CommentService.swift
//======================================================================

import Foundation
import Combine

@MainActor
class CommentService: ObservableObject {
    static let shared = CommentService()
    
    @Published var comments: [UUID: [Comment]] = [:]
    @Published var commentCounts: [UUID: Int] = [:]
    
    private init() {}
    
    func getComments(for postId: UUID) -> [Comment] {
        return comments[postId] ?? []
    }
    
    func getCommentCount(for postId: UUID) -> Int {
        return commentCounts[postId] ?? 0
    }
    
    func addComment(_ comment: Comment) {
        if comments[comment.postId] == nil {
            comments[comment.postId] = []
        }
        comments[comment.postId]?.append(comment)
        commentCounts[comment.postId] = comments[comment.postId]?.count ?? 0
    }
    
    func loadComments(for postId: UUID) {
        if comments[postId] == nil {
            comments[postId] = []
            commentCounts[postId] = 0
        }
    }
}