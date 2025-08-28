import Foundation
import Combine

// MARK: - Unified Service Manager

@MainActor
final class ServiceManager: ObservableObject {
    static let shared = ServiceManager()
    
    // MARK: - Service Instances
    let likeService: LikeService
    let commentService: CommentService
    
    private init() {
        self.likeService = LikeService.shared
        self.commentService = CommentService.shared
    }
}

// MARK: - Service Protocols

protocol LikeServiceProtocol: ObservableObject {
    func toggleLike(for postId: UUID) async throws
    func isLiked(_ postId: UUID) async -> Bool
}

protocol CommentServiceProtocol: ObservableObject {
    var comments: [Comment] { get }
    func loadComments(for postId: UUID) async
    func addComment(_ text: String, to postId: UUID) async throws
}