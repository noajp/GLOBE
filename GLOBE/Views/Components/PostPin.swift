//======================================================================
// MARK: - PostPin.swift
// Purpose: Post display components for map pins with speech bubble design
// Path: GLOBE/Views/Components/PostPin.swift
//======================================================================

import SwiftUI
import Foundation
import CoreLocation
import UIKit

struct PostPin: View {
    private let customBlack = Color.black
    private let iconExtraOffset: CGFloat = 8
    private let bottomPadding: CGFloat = 0
    private let cardCornerRadius: CGFloat = 14
    let post: Post
    let onTap: () -> Void
    @StateObject private var commentService = CommentService.shared
    @StateObject private var likeService = LikeService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingUserProfile = false
    @State private var showingImageViewer = false
    private var borderWidth: CGFloat { 1.2 }

    private var hasImageContent: Bool {
        (post.imageData != nil) || (post.imageUrl != nil)
    }
    
    // Calculate dynamic height based on content (legacy)
    private var legacyCardHeight: CGFloat {
        let hasImage = hasImageContent
        let hasText = !post.text.isEmpty

        if hasImage && !hasText {
            return max(cardWidth * 0.68, 110)
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
        return 110 // 統一サイズ
    }

    private var cardHeight: CGFloat {
        // 動的高さ計算：最小3行分の高さを確保
        let minHeight = cardWidth * (3.0 / 4.0) // 最小高さ（3行分）

        // テキストがある場合は行数に応じて高さ調整
        if !post.text.isEmpty {
            let textFont = UIFont.systemFont(ofSize: 9, weight: .medium)
            let textHeight = measuredTextHeight(for: post.text, width: contentWidth - 16, font: textFont)
            let lineHeight: CGFloat = 12 // 1行あたりの概算高さ
            let estimatedLines = max(1, ceil(textHeight / lineHeight))

            // 基本要素の高さ（ヘッダー + パディング + アクションバー）
            let baseHeight: CGFloat = 34 + 16 + 24 // ヘッダー34px + パディング16px + アクションバー24px

            // 写真がある場合の追加高さ
            let imageHeight: CGFloat = hasImageContent ? 60 : 0

            // テキスト分の高さ
            let textAreaHeight = estimatedLines * lineHeight + 8 // 8pxは上下余白

            let calculatedHeight = baseHeight + imageHeight + textAreaHeight

            return max(minHeight, calculatedHeight)
        }

        return minHeight
    }

    private var contentWidth: CGFloat {
        cardWidth - 24
    }
    
    private func measuredTextHeight(for text: String, width: CGFloat, font: UIFont) -> CGFloat {
        guard !text.isEmpty else { return 0 }

        let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraint,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
    
    var body: some View {
        let hasImage = (post.imageData != nil) || (post.imageUrl != nil)
        let hasText = !post.text.isEmpty
        let isPhotoOnly = hasImage && !hasText

        GlassEffectContainer {
            VStack(alignment: .leading, spacing: 4) {
            // MARK: - Top Header with Avatar and ID (Always visible)
            HStack(spacing: 6) {
                // Avatar
                Circle()
                    .fill(Color.white.opacity(0.1)) // More transparent avatar background
                    .frame(width: 20, height: 20)
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

                // User ID
                Text("@\(post.authorName)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 2)

            // MARK: - Content Area (Photo and/or Text)
            VStack(alignment: .leading, spacing: 2) {
                // Photo content
            if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                let inset: CGFloat = isPhotoOnly ? 2 : 6
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth - inset * 2, height: cardWidth - inset * 2)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, max(2, inset - 2))
                    .onTapGesture { showingImageViewer = true }


                if !post.text.isEmpty {
                    let verticalPadding: CGFloat = post.isAnonymous ? 8 : 4
                    captionText(post.text)
                        .padding(.top, max(4, verticalPadding))
                        .padding(.bottom, verticalPadding)
                }
            } else if let imageUrl = post.imageUrl {
                let inset: CGFloat = isPhotoOnly ? 2 : 6
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth - inset * 2, height: cardWidth - inset * 2)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView().scaleEffect(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, max(2, inset - 2))
                .onTapGesture { showingImageViewer = true }


                if !post.text.isEmpty {
                    let verticalPadding: CGFloat = post.isAnonymous ? 8 : 4
                    captionText(post.text)
                        .padding(.top, max(4, verticalPadding))
                        .padding(.bottom, verticalPadding)
                }
            } else if !post.text.isEmpty {
                // Text-only content
                captionText(post.text)
                    .padding(.vertical, 4)
            }
            }
            .padding(.horizontal, 8)

            Spacer()

            // MARK: - Bottom Action Bar (Likes and Comments)
            HStack {
                Spacer()

                HStack(spacing: 20) {
                    // Like button
                    Button(action: {
                        if let userId = authManager.currentUser?.id {
                            let newLikeState = likeService.toggleLike(for: post, userId: userId)
                            if newLikeState {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }) {
                        Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                            .foregroundColor(likeService.isLiked(post.id) ? .red : .white.opacity(0.9))
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Comment button
                    Button(action: {}) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
            .padding(.top, 2)
            }
            .frame(width: cardWidth, height: cardHeight, alignment: .top)
            .padding(.bottom, bottomPadding)
            // Apply transparent Liquid Glass effect
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        }  // Close GlassEffectContainer
        .onAppear {
            commentService.loadComments(for: post.id)
            likeService.initializePost(post)
        }
        .fullScreenCover(isPresented: $showingUserProfile) {
            UserProfileView(
                userName: post.authorName,
                userId: post.authorId,
                isPresented: $showingUserProfile
            )
            .transition(.move(edge: .trailing))
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            if let data = post.imageData, let ui = UIImage(data: data) {
                PhotoViewerView(image: ui) { showingImageViewer = false }
            } else if let urlString = post.imageUrl, let url = URL(string: urlString) {
                PhotoViewerView(imageUrl: url) { showingImageViewer = false }
            }
        }
    }
}

// MARK: - Helper extension for PostPin
private extension PostPin {
    func captionText(_ text: String, fontSize: CGFloat = 9) -> some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: contentWidth, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

// Scalable PostPin that adjusts size based on map zoom level
struct ScalablePostPin: View {
    private let customBlack = Color.black // Temporary fix: use solid black instead of MinimalDesign color
    private let cardCornerRadius: CGFloat = 14
    let post: Post
    let mapSpan: Double
    @StateObject private var commentService = CommentService.shared
    @StateObject private var likeService = LikeService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingUserProfile = false
    @State private var showingImageViewer = false
    private var borderWidth: CGFloat { 1.2 }
    
    private var scaleFactor: CGFloat {
        let baseSpan: Double = 0.01
        let maxScale: CGFloat = 1.5
        // 横幅は変えないため、最小値を維持
        let minScale: CGFloat = 0.8
        let scale = CGFloat(baseSpan / max(mapSpan, 0.001))
        let popularityBonus: CGFloat = post.likeCount >= 10 ? 1.2 : 1.0
        return max(minScale, min(maxScale, scale * popularityBonus))
    }
    
    // ズームレベルに応じて非表示にする閾値
    private var shouldHide: Bool {
        // 写真付きの投稿（写真のみ、写真+文字）は拡大時（mapSpan < 0.05）のみ表示
        if hasImage && mapSpan >= 0.05 {
            return true
        }
        
        // mapSpan が 5 以上（大陸レベル）で非表示
        return mapSpan > 5.0
    }
    
    private var baseCardSize: CGFloat {
        100  // 統一サイズ
    }
    
    private var cardWidth: CGFloat {
        // Use wider width for text-only posts to create rectangular bubble
        return baseCardSize * scaleFactor
    }
    
    private var fontScale: CGFloat {
        // Keep fonts readable even when zoomed out
        max(0.8, min(1.0, scaleFactor))
    }

    // Fixed minimum insets regardless of zoom
    // Bring actions少し下辺に近づける（安全な最小余白は確保）
    private var topInset: CGFloat { max(6, 6 * fontScale) }
    private var bottomInset: CGFloat { max(8, 8 * fontScale) }

    // メタデータ（アイコンとID）を投稿カード内に表示しない
    private var showMeta: Bool { false }
    private var showHeaderMeta: Bool { false }
    private var hasImage: Bool { (post.imageData != nil) || (post.imageUrl != nil) }
    private var isCompactTextOnly: Bool { !hasImage && !post.text.isEmpty && !showMeta }

    // Estimate text lines for dynamic layout (rough but fast)
    private var estimatedTextLines: Int {
        guard !post.text.isEmpty else { return 0 }
        // Approximate characters per line for current width/font
        let charsPerLine = hasImage ? 14 : 22
        return max(1, Int(ceil(Double(post.text.count) / Double(charsPerLine))))
    }

    private var isSingleLine: Bool { estimatedTextLines == 1 }

    // Dynamic height: shrink when anonymous text-only and single line
    private var dynamicHeight: CGFloat {
        // 4:3 aspect ratio for consistency with PostPin
        return cardWidth * (4.0 / 3.0)
    }

    private var stackSpacing: CGFloat {
        if isCompactTextOnly { return 0 }
        // Remove inter-item spacing entirely when meta is hidden to avoid blank bands
        return showMeta ? (post.isAnonymous ? 4 * fontScale : 2 * fontScale) : 0
    }
    
    var body: some View {
        if shouldHide {
            EmptyView()
        } else {
            cardView
                .padding(.bottom, 32 * fontScale)
                .onAppear {
                    commentService.loadComments(for: post.id)
                    likeService.initializePost(post)
                }
                .fullScreenCover(isPresented: $showingUserProfile) {
                    UserProfileView(
                        userName: post.authorName,
                        userId: post.authorId,
                        isPresented: $showingUserProfile
                    )
                    .transition(.move(edge: .trailing))
                }
                .fullScreenCover(isPresented: $showingImageViewer) {
                    if let data = post.imageData, let ui = UIImage(data: data) {
                        PhotoViewerView(image: ui) { showingImageViewer = false }
                    } else if let urlString = post.imageUrl, let url = URL(string: urlString) {
                        PhotoViewerView(imageUrl: url) { showingImageViewer = false }
                    }
                }
        }
    }

    @ViewBuilder
    private var cardView: some View {
        let dynamicCornerRadius: CGFloat = max(12, cardCornerRadius * fontScale)

        VStack(alignment: .leading, spacing: stackSpacing) {
            if showHeaderMeta && !hasImage {
                HStack(spacing: 3 * fontScale) {
                    Button(action: {
                        print("👤 ScalablePostPin - Header icon tapped user: \(post.authorId)")
                        showingUserProfile = true
                    }) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20 * fontScale, height: 20 * fontScale)
                            .overlay(
                                Text(post.authorName.prefix(1).uppercased())
                                    .font(.system(size: 10 * fontScale, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        print("🆔 ScalablePostPin - ID tapped user: \(post.authorId)")
                        showingUserProfile = true
                    }) {
                        VStack(alignment: .leading, spacing: 1 * fontScale) {
                            Text("\(post.authorId.prefix(8))")
                                .font(.system(size: 9 * fontScale, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
                .padding(.leading, (isSingleLine ? 6 : 4) * fontScale)
                .padding(.trailing, (isSingleLine ? 12 : 10) * fontScale)
                .padding(.top, topInset)
                .contentShape(Rectangle())
            }

            if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                let isPhotoOnly = post.text.isEmpty
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: isPhotoOnly ? cardWidth - 6 : cardWidth - 12, height: cardWidth - 12)
                    .clipShape(RoundedRectangle(cornerRadius: 4 * fontScale))
                    .padding(.horizontal, isPhotoOnly ? 0 : 4 * fontScale)
                    .onTapGesture { showingImageViewer = true }
            } else if let imageUrl = post.imageUrl {
                let isPhotoOnly = post.text.isEmpty
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: isPhotoOnly ? cardWidth - 6 : cardWidth - 12, height: cardWidth - 12)
                        .clipShape(RoundedRectangle(cornerRadius: 4 * fontScale))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: isPhotoOnly ? cardWidth - 6 : cardWidth - 12, height: cardWidth - 12)
                        .clipShape(RoundedRectangle(cornerRadius: 4 * fontScale))
                        .overlay(ProgressView().scaleEffect(0.5 * fontScale))
                }
                .padding(.horizontal, isPhotoOnly ? 0 : 4 * fontScale)
                .onTapGesture { showingImageViewer = true }
            }

            if !post.text.isEmpty {
                Text(post.text)
                    .font(.system(size: 9 * fontScale, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(scaleFactor < 0.9 ? 2 : nil)
                    .truncationMode(.tail)
                    .frame(maxWidth: cardWidth - 16, alignment: .leading)
                    .padding(.horizontal, 4 * fontScale)
                    .padding(.top, hasImage ? (4 * fontScale) : 2 * fontScale)
                    .padding(.bottom, (isSingleLine ? 2 : 4) * fontScale)
            }

            if showHeaderMeta {
                HStack(spacing: 2 * fontScale) {
                    Button(action: {
                        print("❤️ ScalablePostPin - Like tapped post: \(post.id)")
                        if let userId = authManager.currentUser?.id {
                            let newLikeState = likeService.toggleLike(for: post, userId: userId)
                            if newLikeState {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        } else {
                            print("⚠️ ScalablePostPin - Like ignored (no current user)")
                        }
                    }) {
                        Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                            .font(.system(size: 10 * fontScale))
                            .foregroundColor(likeService.isLiked(post.id) ? .red : .white.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            print("💬 ScalablePostPin - Comment tapped post: \(post.id)")
                        }) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 10 * fontScale))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 4 * fontScale)
                .padding(.bottom, max(6, (6 + borderWidth) * fontScale))
                .contentShape(Rectangle())
            }
        }  // Close VStack
        .frame(width: cardWidth, height: dynamicHeight)
        // Apply transparent Liquid Glass effect
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: dynamicCornerRadius, style: .continuous))
        .overlay(alignment: .bottom) {
            if !post.isAnonymous && scaleFactor >= 0.9 {
                let minDiameter: CGFloat = 16
                let maxDiameter: CGFloat = 40
                let diameter = min(maxDiameter, minDiameter + (scaleFactor - 0.9) * 40)

                Button(action: {
                    print("🎯 ScalablePostPin - Profile icon tapped for user: \(post.authorId)")
                    showingUserProfile = true
                }) {
                    if let urlString = post.authorAvatarUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: diameter * 0.4))
                                )
                        }
                        .frame(width: diameter, height: diameter)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: diameter * 0.4))
                            )
                            .frame(width: diameter, height: diameter)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .offset(y: diameter / 2 + 12)
                .zIndex(10)
            }
        }
    }
}

//======================================================================
