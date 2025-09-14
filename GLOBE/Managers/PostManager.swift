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
            SecureLogger.shared.info("Synced \(self.posts.count) posts from SupabaseService to PostManager")
        }
    }

    func createPost(
        content: String,
        imageData: Data?,
        location: CLLocationCoordinate2D,
        locationName: String?,
        isAnonymous: Bool = false
    ) async throws {
        print("📝 PostManager - createPost called with content: '\(content)', hasImage: \(imageData != nil)")
        // 認証状態を確認
        print("🔐 PostManager - Auth check: isAuthenticated=\(AuthManager.shared.isAuthenticated)")
        print("🔐 PostManager - Current user: \(AuthManager.shared.currentUser?.id ?? "nil")")
        print("🔐 PostManager - User email: \(AuthManager.shared.currentUser?.email ?? "nil")")
        
        guard AuthManager.shared.isAuthenticated,
              let userIdString = AuthManager.shared.currentUser?.id else {
            print("❌ PostManager - Authentication failed - isAuth: \(AuthManager.shared.isAuthenticated), user: \(AuthManager.shared.currentUser?.id ?? "nil")")
            throw AuthError.userNotAuthenticated
        }
        print("✅ PostManager - Authentication passed for user: \(userIdString)")

        // 文字数制限チェックとトリミング
        let maxLength = imageData != nil ? 30 : 60
        let trimmedContent = content.count > maxLength ? String(content.prefix(maxLength)) : content
        if content.count > maxLength {
            print("⚠️ PostManager - Content trimmed from \(content.count) to \(maxLength) characters")
        }
        
        // コンテンツの検証とサニタイズ
        // 写真がある場合は空のコンテンツを許可
        let sanitizedContent: String
        print("🔍 PostManager - Content validation: isEmpty=\(trimmedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty), hasImage=\(imageData != nil)")
        if trimmedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && imageData != nil {
            // 写真のみの投稿の場合
            sanitizedContent = ""
            print("📸 PostManager - Photo-only post detected")
            SecureLogger.shared.info("Creating photo-only post")
        } else {
            // テキストがある場合は通常の検証
            let contentValidation = InputValidator.validatePostContent(trimmedContent)
            guard contentValidation.isValid, let validatedContent = contentValidation.value else {
                SecureLogger.shared.securityEvent("Invalid post content", details: ["content": trimmedContent])
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
        
        SecureLogger.shared.info("Creating post with sanitized content")
        print("🚀 PostManager - Calling SupabaseService.createPostWithRPC")
        
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
        
        print("📤 PostManager - SupabaseService returned success: \(success)")
        if !success {
            let errorMessage = supabaseService.error ?? "不明なエラー"
            print("❌ PostManager - Post creation failed with error: \(errorMessage)")
            throw AuthError.invalidInput("投稿の作成に失敗しました: \(errorMessage)")
        }
        
        print("✅ PostManager - Post created successfully")
        SecureLogger.shared.info("Post created successfully", file: #file, function: #function, line: #line)
        
        // 投稿成功後、ローカルの投稿リストを直接更新（fetchPostsで上書きされないように）
        print("🔄 PostManager - Updating local posts list...")
        
        // SupabaseServiceの最新のpostsを取得（新規投稿が含まれている）
        await MainActor.run {
            self.posts = supabaseService.posts
            print("📍 PostManager - Updated posts count: \(self.posts.count)")
        }
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
