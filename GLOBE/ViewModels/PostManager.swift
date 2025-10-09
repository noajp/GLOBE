import Foundation
import CoreLocation
import UIKit
import Combine

// クラス全体をMainActorで実行するように指定します。
@MainActor
class PostManager: PostServiceProtocol {
    static let shared = PostManager()

    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabaseService = SupabaseService.shared

    private init() {
        // SupabaseService の posts を監視
        supabaseService.$posts.assign(to: &$posts)
        supabaseService.$isLoading.assign(to: &$isLoading)
        supabaseService.$error.assign(to: &$error)
    }

    func fetchPosts() async {
        await supabaseService.fetchPosts()
        // SupabaseServiceの投稿をPostManagerに同期
        await MainActor.run {
            self.posts = supabaseService.posts
        }
    }

    /// Fetch posts within a geographic bounding box
    func fetchPostsInBounds(
        minLat: Double,
        maxLat: Double,
        minLng: Double,
        maxLng: Double,
        zoomLevel: Double
    ) async {
        await supabaseService.fetchPostsInBounds(
            minLat: minLat,
            maxLat: maxLat,
            minLng: minLng,
            maxLng: maxLng,
            zoomLevel: zoomLevel
        )
        // Sync posts from SupabaseService
        await MainActor.run {
            self.posts = supabaseService.posts
        }
    }

    func createPost(
        content: String,
        imageData: Data?,
        location: CLLocationCoordinate2D,
        locationName: String?,
        isAnonymous: Bool = false
    ) async throws {
        // 認証状態を確認
        guard AuthManager.shared.isAuthenticated,
              let userIdString = AuthManager.shared.currentUser?.id else {
            throw AuthError.userNotAuthenticated
        }

        // 文字数制限チェックとトリミング
        let maxLength = 30  // 画像の有無に関わらず30文字まで
        let trimmedContent = content.count > maxLength ? String(content.prefix(maxLength)) : content

        // コンテンツの検証とサニタイズ
        let sanitizedContent: String
        if trimmedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && imageData != nil {
            // 写真のみの投稿の場合
            sanitizedContent = ""
        } else {
            // テキストがある場合は通常の検証
            let contentValidation = InputValidator.validatePostContent(trimmedContent)
            guard contentValidation.isValid, let validatedContent = contentValidation.value else {
                throw AuthError.invalidInput(contentValidation.errorMessage ?? "投稿内容が無効です")
            }
            sanitizedContent = validatedContent
        }

        // 投稿内容が空でないか確認（テキストまたは写真が必要）
        if sanitizedContent.isEmpty && imageData == nil {
            throw AuthError.invalidInput("投稿にはテキストまたは写真が必要です")
        }

        // 位置情報名のサニタイズ
        let sanitizedLocationName = locationName.map { InputValidator.sanitizeText($0, maxLength: 100) }

        // Use SupabaseService to create post with proper validation
        let success = await supabaseService.createPostWithRPC(
            userId: userIdString,
            content: sanitizedContent,
            imageData: imageData,
            latitude: location.latitude,
            longitude: location.longitude,
            locationName: sanitizedLocationName,
            isAnonymous: isAnonymous
        )

        if !success {
            let errorMessage = supabaseService.error ?? "不明なエラー"
            throw AuthError.invalidInput("投稿の作成に失敗しました: \(errorMessage)")
        }

        // 投稿成功後、最新の投稿リストを取得
        await fetchPosts()
    }

    func deletePost(_ postId: UUID) async -> Bool {
        return await supabaseService.deletePost(postId)
    }
    
    func toggleLike(for postId: UUID) async -> Bool {
        guard let userIdString = AuthManager.shared.currentUser?.id else {
            return false
        }
        return await supabaseService.toggleLike(postId: postId, userId: userIdString)
    }

    func updatePosts(_ newPosts: [Post]) {
        self.posts = newPosts
    }
}
