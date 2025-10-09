//======================================================================
// MARK: - Comment.swift
// Purpose: Comment data model for post comments functionality
// Path: GLOBE/Models/Comment.swift
//======================================================================

import Foundation

struct Comment: Identifiable, Equatable {
    let id: UUID
    let postId: UUID
    let createdAt: Date
    let text: String
    let authorName: String
    let authorId: String

    init(id: UUID = UUID(), postId: UUID, text: String, authorName: String, authorId: String, createdAt: Date = Date()) {
        self.id = id
        self.postId = postId
        self.createdAt = createdAt
        self.text = text
        self.authorName = authorName
        self.authorId = authorId
    }
    
    // Equatable conformance
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id &&
               lhs.postId == rhs.postId &&
               lhs.createdAt == rhs.createdAt &&
               lhs.text == rhs.text &&
               lhs.authorName == rhs.authorName &&
               lhs.authorId == rhs.authorId
    }
}

extension Comment {
    static var mockComments: [Comment] {
        [
            Comment(postId: UUID(), text: "素晴らしい写真ですね！", authorName: "山田花子", authorId: "user1"),
            Comment(postId: UUID(), text: "Amazing view! 📸", authorName: "John Smith", authorId: "user2"),
            Comment(postId: UUID(), text: "いいね👍", authorName: "佐藤太郎", authorId: "user3")
        ]
    }
}