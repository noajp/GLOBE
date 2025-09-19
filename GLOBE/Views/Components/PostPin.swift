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
    private let iconExtraOffset: CGFloat = 8
    private let bottomPadding: CGFloat = 0
    private let cardCornerRadius: CGFloat = 18
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
    
    // Calculate dynamic height based on content
    private var cardHeight: CGFloat {
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
        return hasImageContent ? 140 : 180
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

        VStack(alignment: .leading, spacing: isPhotoOnly ? 0 : (post.isAnonymous ? 4 : 0)) {
            if !post.isAnonymous && !post.isPublic && post.imageData == nil && post.imageUrl == nil {
                HStack(spacing: 3) {
                    Button(action: {
                        print("👤 PostPin - Header icon tapped for user: \(post.authorId)")
                        showingUserProfile = true
                    }) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Text(post.authorName.prefix(1).uppercased())
                                    .font(.system(size: 4, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        print("🆔 PostPin - ID tapped for user: \(post.authorId)")
                        showingUserProfile = true
                    }) {
                        Text("\(post.authorId.prefix(6))")
                            .font(.system(size: 6, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .frame(height: 8)
                // Move icon + ID a bit more to the left (smaller leading, larger trailing)
                .padding(.leading, 4)
                .padding(.trailing, 10)
                // Top spacing fixed to 6pt
                .padding(.top, 6)
                .contentShape(Rectangle())
                .zIndex(1)
            } else if hasImage {
                // 写真のみの場合は上部パディングを削除
                // 匿名投稿時は上部パディングを追加（より余裕を持たせる）
                Spacer()
                    .frame(height: 18)
            }
            
            // コンテンツエリア - 写真があれば写真＋（あれば）テキスト、なければテキストのみ
            if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                let inset: CGFloat = isPhotoOnly ? 2 : 6
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth - inset * 2, height: cardWidth - inset * 2)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, max(2, inset - 2))
                    .onTapGesture { showingImageViewer = true }

                if !post.isAnonymous && !post.isPublic {
                    HStack(spacing: 3) {
                        Button(action: {
                            print("👤 PostPin - Header icon tapped for user: \(post.authorId)")
                            showingUserProfile = true
                        }) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Text(post.authorName.prefix(1).uppercased())
                                        .font(.system(size: 4, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            print("🆔 PostPin - ID tapped for user: \(post.authorId)")
                            showingUserProfile = true
                        }) {
                            Text("\(post.authorId.prefix(6))")
                                .font(.system(size: 6, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    .frame(height: 8)
                    .padding(.leading, 4)
                    .padding(.trailing, 10)
                    .padding(.top, 4)
                    .contentShape(Rectangle())
                    .zIndex(1)
                }

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

                if !post.isAnonymous && !post.isPublic {
                    HStack(spacing: 3) {
                        Button(action: {
                            print("👤 PostPin - Header icon tapped for user: \(post.authorId)")
                            showingUserProfile = true
                        }) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Text(post.authorName.prefix(1).uppercased())
                                        .font(.system(size: 4, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            print("🆔 PostPin - ID tapped for user: \(post.authorId)")
                            showingUserProfile = true
                        }) {
                            Text("\(post.authorId.prefix(6))")
                                .font(.system(size: 6, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    .frame(height: 8)
                    .padding(.leading, 4)
                    .padding(.trailing, 10)
                    .padding(.top, 4)
                    .contentShape(Rectangle())
                    .zIndex(1)
                }

                if !post.text.isEmpty {
                    let verticalPadding: CGFloat = post.isAnonymous ? 8 : 4
                    captionText(post.text)
                        .padding(.top, max(4, verticalPadding))
                        .padding(.bottom, verticalPadding)
                }
            } else if !post.text.isEmpty {
                // 文字領域を最大化
                let verticalPadding: CGFloat = post.isAnonymous ? 8 : 4
                captionText(post.text)
                    .padding(.top, verticalPadding)
                    .padding(.bottom, verticalPadding)
            }
            
            // フッター - 匿名投稿では非表示だがスペースは確保
            if !post.isAnonymous && !post.isPublic {
                HStack(spacing: 2) {
                    Spacer()
                    Button(action: {
                        print("❤️ PostPin - Like tapped for post: \(post.id)")
                        if let userId = authManager.currentUser?.id {
                            let newLikeState = likeService.toggleLike(for: post, userId: userId)
                            if newLikeState {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        } else {
                            print("⚠️ PostPin - Like ignored (no current user)")
                        }
                    }) {
                        HStack(spacing: 1) {
                            Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                                .font(.system(size: 6))
                                .foregroundColor(likeService.isLiked(post.id) ? .red : .white.opacity(0.8))
                            
                            let likeCount = likeService.getLikeCount(for: post.id)
                            // Reserve number slot so the heart doesn't shift when count appears
                            Text("\(max(likeCount, 0))")
                                .font(.system(size: 5))
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(likeCount > 0 ? 1 : 0)
                                .frame(width: 12, alignment: .leading)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        print("💬 PostPin - Comment tapped for post: \(post.id)")
                    }) {
                        HStack(spacing: 1) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 6))
                                .foregroundColor(.white.opacity(0.8))
                            
                            let count = commentService.getCommentCount(for: post.id)
                            // Reserve number slot so layout doesn't jump
                            Text("\(max(count, 0))")
                                .font(.system(size: 5))
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(count > 0 ? 1 : 0)
                                .frame(width: 12, alignment: .leading)
                }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(height: 8)
                .padding(.leading, 4)
                .padding(.trailing, 4)
                // Bring actions closer to bottom while avoiding border overlap
                .padding(.top, 1)
                .padding(.bottom, 6)
                .contentShape(Rectangle())
                .zIndex(1)
            }
        }
        .frame(width: cardWidth, height: cardHeight, alignment: .top)
        .padding(.bottom, bottomPadding)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: borderWidth)
                .blendMode(.screen)
                .allowsHitTesting(false)
        )
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .onTapGesture(perform: onTap)
        // Profile icon at V-tip for non-anonymous posts (small-pin variant)
        .overlay(alignment: .bottom) {
            if !post.isAnonymous {
                let diameter: CGFloat = 32
                Group {
                    if let urlString = post.authorAvatarUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.blue.opacity(0.7))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: diameter * 0.4))
                                )
                        }
                        .frame(width: diameter, height: diameter)
                        .clipShape(Circle())
                    } else {
                        Circle().fill(Color.blue.opacity(0.7))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: diameter * 0.4))
                            )
                            .frame(width: diameter, height: diameter)
                    }
                }
                // カード下にアバターを浮かせて位置を示す
                .offset(y: diameter / 2 + iconExtraOffset)
                .zIndex(10)
                .allowsHitTesting(false)
            }
        }
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
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

// MARK: - Bubble Helpers
private extension PostPin {
    func captionText(_ text: String, fontSize: CGFloat = 9) -> some View {
        Text(text)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: contentWidth, alignment: .leading)
            .padding(.horizontal, 8)
            .shadow(color: Color.black.opacity(0.45), radius: 2, x: 0, y: 1)
    }
}

// Scalable PostPin that adjusts size based on map zoom level
struct ScalablePostPin: View {
    private let customBlack = Color.black // Temporary fix: use solid black instead of MinimalDesign color
    private let cardCornerRadius: CGFloat = 18
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
        hasImage ? 130 : 190
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
        let base: CGFloat = 78 * scaleFactor
        if hasImage {
            let isPhotoOnly = hasImage && post.text.isEmpty
            // Square photo height equals inner card width (minus horizontal padding)
            let imageH: CGFloat = (cardWidth - 8)
            var h: CGFloat
            if isPhotoOnly {
                // 写真のみの場合は最小限の余白のみ
                h = imageH + 4 * fontScale  // 画像 + 最小余白
            } else {
                h = showMeta
                    ? max(imageH + 44 * fontScale, 80)
                    : max(imageH + 6 * fontScale, 50)
                // 枠自体に上6pt＋下8ptぶんの最小ゆとりを反映
                h += topInset + bottomInset
            }
            return h
        }
        
        // 公開投稿（匿名）で文字だけの場合
        if isCompactTextOnly {
            let fontSize: CGFloat = 9 * fontScale  // 実際のフォントサイズに基づく
            let lineHeight: CGFloat = fontSize * 1.3  // 行間を考慮した行の高さ
            let textHeight = lineHeight * CGFloat(estimatedTextLines)
            
            // 最小限の上下余白（行数によって調整）
            let verticalPadding: CGFloat
            if estimatedTextLines == 1 {
                verticalPadding = 8 * fontScale  // 1行の場合は最小限
            } else if estimatedTextLines == 2 {
                verticalPadding = 6 * fontScale  // 2行の場合は少し少なく
            } else {
                verticalPadding = 4 * fontScale  // 3行以上は最小限
            }
            
            return textHeight + verticalPadding
        }

        // Lower absolute minimums more when meta is hidden (zoomed out)
        let absMin = showMeta ? 60.0 : 48.0

        var h: CGFloat
        if isSingleLine {
            // Make the card clearly slim for one-line text
            h = max(absMin, base)
        } else if estimatedTextLines == 2 {
            h = max(absMin + 4, base + 10)
        } else {
            h = max(absMin + 6, base + 16)
        }
        // メタ情報がある場合のみ余白を追加
        return showMeta ? h + topInset + bottomInset : h
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
                .shadow(color: customBlack.opacity(0.3), radius: 4 * fontScale, x: 0, y: 2 * fontScale)
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

    private var cardView: some View {
        let dynamicCornerRadius: CGFloat = max(12, cardCornerRadius * fontScale)

        return VStack(alignment: .leading, spacing: stackSpacing) {
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
                    .font(.system(size: 9 * fontScale, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(scaleFactor < 0.9 ? 2 : nil)
                    .truncationMode(.tail)
                    .frame(maxWidth: cardWidth - 24, alignment: .leading)
                    .padding(.leading, 16 * fontScale)
                    .padding(.trailing, 4 * fontScale)
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
                        HStack(spacing: 1 * fontScale) {
                            Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                                .font(.system(size: 10 * fontScale))
                                .foregroundColor(likeService.isLiked(post.id) ? .red : .white.opacity(0.8))

                            let likeCount = likeService.getLikeCount(for: post.id)
                            Text("\(max(likeCount, 0))")
                                .font(.system(size: 8 * fontScale))
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(likeCount > 0 ? 1 : 0)
                                .frame(width: 12 * fontScale, alignment: .leading)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            print("💬 ScalablePostPin - Comment tapped post: \(post.id)")
                        }) {
                        HStack(spacing: 1 * fontScale) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 10 * fontScale))
                                .foregroundColor(.white.opacity(0.8))

                            let count = commentService.getCommentCount(for: post.id)
                            Text("\(max(count, 0))")
                                .font(.system(size: 8 * fontScale))
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(count > 0 ? 1 : 0)
                                .frame(width: 12 * fontScale, alignment: .leading)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 4 * fontScale)
                .padding(.bottom, max(6, (6 + borderWidth) * fontScale))
                .contentShape(Rectangle())
            }
        }
        .frame(width: cardWidth, height: dynamicHeight)
        .background(
            RoundedRectangle(cornerRadius: dynamicCornerRadius, style: .continuous)
                .fill(Color.black.opacity(hasImage ? 0.65 : 0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: dynamicCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: borderWidth)
                .blendMode(.screen)
                .allowsHitTesting(false)
        )
        .clipShape(RoundedRectangle(cornerRadius: dynamicCornerRadius, style: .continuous))
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
