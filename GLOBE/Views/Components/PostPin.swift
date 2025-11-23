//======================================================================
// MARK: - PostPin.swift
// Function: Map Post Pin Components
// Overview: Speech bubble design post pins with image support and tap interaction
// Processing: Render bubble shape → Display post content → Handle user interaction → Show location marker
//======================================================================

import SwiftUI
import Foundation
import CoreLocation
import UIKit

//###########################################################################
// MARK: - Post Pin View
// Function: PostPin
// Overview: Main post pin component with speech bubble design
// Processing: Calculate layout → Render bubble → Display content/image → Handle interactions → Show action buttons
//###########################################################################

struct PostPin: View {
    private let customBlack = Color.black
    private let iconExtraOffset: CGFloat = 8
    private let bottomPadding: CGFloat = 0
    private let cardCornerRadius: CGFloat = 8
    let post: Post
    let onTap: () -> Void
    @EnvironmentObject var commentService: CommentService
    @EnvironmentObject var likeService: LikeService
    @EnvironmentObject var authManager: AuthManager
    @State private var showingUserProfile = false
    @State private var showingImageViewer = false
    @State private var showingComments = false
    @State private var showingDeleteAlert = false
    private var borderWidth: CGFloat { 1.2 }

    //###########################################################################
    // MARK: - Computed Properties
    // Function: Layout calculation properties
    // Overview: Calculate dynamic dimensions based on post content
    // Processing: Check content type → Calculate height/width → Return computed value
    //###########################################################################

    private var hasImageContent: Bool {
        (post.imageData != nil) || (post.imageUrl != nil)
    }

    // Calculate dynamic height based on content (legacy)
    private var legacyCardHeight: CGFloat {
        let hasImage = hasImageContent
        let hasText = !post.text.isEmpty

        if hasImage && !hasText {
            return max(cardWidth * 0.80, 120)
        }

        let textFont = UIFont.systemFont(ofSize: 9, weight: .medium)
        let textWidth = contentWidth
        let textHeight = hasText ? measuredTextHeight(for: post.text, width: textWidth, font: textFont) : 0

        if hasImage {
            let imageHeight = cardWidth - 8
            let imageTopPadding: CGFloat = 4
            let textInset: CGFloat = post.isAnonymous ? 8 : 4
            let textTopPadding: CGFloat = hasText ? max(4, textInset) : 0
            let textBottomPadding: CGFloat = hasText ? textInset : 0
            let actionHeight: CGFloat = (!post.isAnonymous && !post.isPublic) ? (8 + 1 + 6) : 0
            let computedHeight = imageHeight + imageTopPadding + textTopPadding + textHeight + textBottomPadding + actionHeight
            return max(computedHeight, cardWidth * 0.78)
        }

        if hasText {
            let textInset: CGFloat = post.isAnonymous ? 8 : 4
            let topPadding: CGFloat = textInset
            let bottomPadding: CGFloat = textInset
            let headerHeight: CGFloat = (!post.isAnonymous && !post.isPublic && !hasImage) ? (8 + 6) : 0
            let actionHeight: CGFloat = (!post.isAnonymous && !post.isPublic) ? (8 + 1 + 6) : 0
            let computedHeight = headerHeight + topPadding + textHeight + bottomPadding + actionHeight
            return max(computedHeight, 54)
        }

        return 38
    }
    
    private var cardWidth: CGFloat {
        // 画像がある場合は写真に合わせてカードサイズを調整
        if hasImageContent {
            let inset: CGFloat = 3
            // 写真サイズ * 0.70 + 両側の余白
            let photoSize = (150 - inset * 2) * 0.70
            return photoSize + inset * 2 // 写真サイズ + 左右余白
        }
        return 150 // テキストのみの場合は通常サイズ
    }

    private var isPhotoOnly: Bool {
        return post.text.isEmpty && hasImageContent
    }

    private var cardHeight: CGFloat {
        // 動的高さ計算
        let baseHeight: CGFloat = 40 // 最小高さ

        // 画像がある場合の高さ（insetは常に3px）
        let imageInset: CGFloat = 3
        let imageHeight: CGFloat = hasImageContent ? (cardWidth - imageInset * 2) : 0

        // ヘッダー（アバター・ID）の高さ - 非匿名投稿は常に表示
        let headerHeight: CGFloat = post.isAnonymous ? 0 : 26

        // アクションバー（いいね・コメント）の高さ - 非匿名投稿のみ
        let actionBarHeight: CGFloat = post.isAnonymous ? 0 : 16

        // テキストがある場合の高さ計算
        let textHeight: CGFloat
        if !post.text.isEmpty {
            let textFont = UIFont.systemFont(ofSize: 9, weight: .medium)
            let measuredHeight = measuredTextHeight(for: post.text, width: contentWidth - 16, font: textFont)
            let topPadding: CGFloat = hasImageContent ? 2 : 4
            let bottomPadding: CGFloat = 2
            textHeight = measuredHeight + topPadding + bottomPadding
        } else {
            textHeight = 0
        }

        // 画像のみの場合
        if hasImageContent && post.text.isEmpty {
            let height = imageHeight + headerHeight + actionBarHeight + 6 // 上下の余白3pxずつ
            return height
        }

        // 画像 + テキストの場合
        if hasImageContent && !post.text.isEmpty {
            let height = imageHeight + headerHeight + textHeight + actionBarHeight + 12 // 上下のパディングを増加
            return height
        }

        // テキストのみの場合
        if !post.text.isEmpty {
            let height = headerHeight + textHeight + actionBarHeight + 1
            return height
        }

        return baseHeight
    }

    private var contentWidth: CGFloat {
        cardWidth - 24
    }

    //###########################################################################
    // MARK: - Text Measurement
    // Function: measuredTextHeight
    // Overview: Calculate required height for text with given width constraint
    // Processing: Use shared utility for text height calculation
    //###########################################################################

    private func measuredTextHeight(for text: String, width: CGFloat, font: UIFont) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        return PostPinUtilities.measuredTextHeight(for: text, width: width, font: font)
    }

    // MARK: - Helper Methods
    private func captionText(_ text: String, fontSize: CGFloat = 9) -> some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: contentWidth, alignment: .leading)
            .padding(.horizontal, 8)
    }

    private var actionBar: some View {
        HStack(spacing: 6) {
            Spacer()

            // Like button
            Button(action: {
                if let userId = authManager.currentUser?.id {
                    let _ = likeService.toggleLike(for: post, userId: userId)
                }
            }) {
                Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(likeService.isLiked(post.id) ? .red.opacity(0.7) : .white.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    var body: some View {
        let hasImage = PostPinUtilities.hasImageContent(post)
        let isPhotoOnly = PostPinUtilities.isPhotoOnly(post)

        GlassEffectContainer {
            ZStack(alignment: .topTrailing) {
                // Main content
                VStack(alignment: .leading, spacing: 2) {
                // MARK: - Content Area (Photo and/or Text)
                // Photo content
            if let imageData = post.imageData {
                let inset: CGFloat = 3
                let imageSize = cardWidth - inset * 2

                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.horizontal, inset)
                        .padding(.top, 3)
                        .padding(.bottom, isPhotoOnly ? 3 : 0)
                        .id("\(post.id)-image") // 明示的なIDで画像の再利用を防止
                } else {
                    // 画像データが壊れている場合のプレースホルダー
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: imageSize, height: imageSize)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 30))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.horizontal, inset)
                        .padding(.top, 3)
                        .padding(.bottom, isPhotoOnly ? 3 : 0)
                }

            } else if let imageUrl = post.imageUrl {
                let inset: CGFloat = 3
                let imageSize = cardWidth - inset * 2
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: imageSize, height: imageSize)
                        .overlay(ProgressView().scaleEffect(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .id("\(post.id)-async-image") // AsyncImageに明示的なIDを付与してキャッシュ混乱を防止
                .padding(.horizontal, inset)
                .padding(.top, 3)
                .padding(.bottom, isPhotoOnly ? 3 : 0)

            }

            // MARK: - Header with Avatar and ID (After photo) - Hidden for anonymous posts
            if !post.isAnonymous {
                HStack(spacing: 4) {
                    // Avatar
                    Circle()
                        .fill(Color.white.opacity(0.1)) // More transparent avatar background
                        .frame(width: 18, height: 18)
                        .overlay(
                            Group {
                                if let avatarUrl = post.authorAvatarUrl,
                                   let url = URL(string: avatarUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Text(post.authorName.prefix(1).uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    Text(post.authorName.prefix(1).uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                        .onTapGesture {
                            showingUserProfile = true
                        }

                    // User ID (タップ可能)
                    Text("@\(post.authorName)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .onTapGesture {
                            showingUserProfile = true
                        }

                    Spacer()

                    // Delete button - inline with avatar
                    let isOwner = post.authorId == authManager.currentUser?.id
                    if isOwner {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, hasImage ? 2 : 4)
                .padding(.bottom, 1)
            }

            // MARK: - Text Content (After header)
            if !post.text.isEmpty {
                let verticalPadding: CGFloat = post.isAnonymous ? 4 : 2
                captionText(post.text)
                    .padding(.top, hasImage ? 2 : verticalPadding)
                    .padding(.bottom, 2)
            }

            // MARK: - Bottom Action Bar (Likes and Comments)
            if !post.isAnonymous {
                actionBar
                    .padding(.horizontal, 6)
                    .padding(.bottom, 0)
                    .padding(.top, 1)
            }
            }  // Close VStack
            .frame(width: cardWidth, height: cardHeight + 12, alignment: .top) // Added tail height
            .padding(.bottom, bottomPadding)
            // Apply transparent Liquid Glass effect with speech bubble
            .glassEffect(.clear, in: PostCardBubbleShape(cornerRadius: cardCornerRadius, tailWidth: 25, tailHeight: 12))
        }  // Close ZStack
        }  // Close GlassEffectContainer
        .onAppear {
            commentService.loadComments(for: post.id)
            Task {
                await likeService.loadLikes(for: post.id, userId: authManager.currentUser?.id)
            }
        }
        .fullScreenCover(isPresented: $showingUserProfile) {
            let _ = SecureLogger.shared.info("PostPin: Opening profile - authorName: \(post.authorName), authorId: \(post.authorId)")
            UserProfileView(
                userName: post.authorName,
                userId: post.authorId,
                isPresented: $showingUserProfile
            )
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            if let data = post.imageData, let ui = UIImage(data: data) {
                PhotoViewerView(image: ui) { showingImageViewer = false }
            } else if let urlString = post.imageUrl, let url = URL(string: urlString) {
                PhotoViewerView(imageUrl: url) { showingImageViewer = false }
            }
        }
        .sheet(isPresented: $showingComments) {
            CommentView(post: post)
                .presentationDetents([.fraction(0.5)]) // 画面の半分の高さ
                .presentationDragIndicator(.visible)
        }
        .alert("Delete Post", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await PostManager.shared.deletePost(post.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        // Close the view modifiers chain
    } // End of body
} // End of PostPin struct
