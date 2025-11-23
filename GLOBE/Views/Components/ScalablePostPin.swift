//======================================================================
// MARK: - ScalablePostPin.swift
// Function: Zoom-Aware Post Pin Component
// Overview: Post pin that scales based on map zoom level with dynamic visibility
// Processing: Calculate scale from mapSpan → Apply scale to dimensions → Render with zoom-aware sizing
//======================================================================

import SwiftUI
import UIKit

//###########################################################################
// MARK: - Scalable Post Pin
// Function: ScalablePostPin
// Overview: Zoom-aware post pin that scales based on map zoom level
// Processing: Calculate scale from mapSpan → Apply scale to dimensions → Render pin with adjusted size
//###########################################################################

struct ScalablePostPin: View {
    private let customBlack = Color.black // Temporary fix: use solid black instead of MinimalDesign color
    private let cardCornerRadius: CGFloat = 8
    let post: Post
    let mapSpan: Double
    @StateObject private var commentService = CommentService.shared
    @StateObject private var likeService = LikeService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingUserProfile = false
    @State private var showingImageViewer = false
    @State private var showingComments = false
    @State private var showingDeleteAlert = false
    private var borderWidth: CGFloat { 1.2 }
    private let logger = SecureLogger.shared

    //###########################################################################
    // MARK: - Scale Calculations
    // Function: scaleFactor, fontScale
    // Overview: Calculate scaling factors based on map zoom level
    // Processing: Compare mapSpan to baseSpan → Apply min/max constraints → Add popularity bonus
    //###########################################################################

    private var scaleFactor: CGFloat {
        let baseSpan: Double = 0.01
        let maxScale: CGFloat = 1.5
        // 横幅は変えないため、最小値を維持
        let minScale: CGFloat = 0.8
        let scale = CGFloat(baseSpan / max(mapSpan, 0.001))
        let popularityBonus: CGFloat = post.likeCount >= 10 ? 1.2 : 1.0
        return max(minScale, min(maxScale, scale * popularityBonus))
    }

    private var fontScale: CGFloat {
        // Keep fonts readable even when zoomed out
        max(0.8, min(1.0, scaleFactor))
    }

    //###########################################################################
    // MARK: - Visibility Control
    // Function: shouldHide
    // Overview: Determine if post should be hidden based on zoom level and content type
    // Processing: Check if has image → Apply zoom thresholds → Return visibility decision
    //###########################################################################

    // ズームレベルに応じて非表示にする閾値
    private var shouldHide: Bool {
        // 写真付きの投稿（写真のみ、写真+文字）は拡大時（mapSpan < 0.01 ≈ 1km）のみ表示
        if hasImage && mapSpan >= 0.01 {
            return true
        }

        // 文字のみ投稿は mapSpan < 1.0（約100km）で表示
        return mapSpan > 1.0
    }

    //###########################################################################
    // MARK: - Layout Calculations
    // Function: baseCardSize, cardWidth, dynamicHeight
    // Overview: Calculate card dimensions based on content and zoom
    // Processing: Determine base size → Apply scale factor → Calculate dynamic height
    //###########################################################################

    private var baseCardSize: CGFloat {
        // 画像がある場合は写真に合わせてカードサイズを調整
        if hasImage {
            let inset: CGFloat = 3
            // 写真サイズ * 0.70 + 両側の余白
            let photoSize = (150 - inset * 2) * 0.70
            return photoSize + inset * 2 // 写真サイズ + 左右余白
        }
        return 150  // テキストのみの場合は通常サイズ
    }

    private var cardWidth: CGFloat {
        // Use wider width for text-only posts to create rectangular bubble
        return baseCardSize * scaleFactor
    }

    // Fixed minimum insets regardless of zoom
    // Bring actions少し下辺に近づける（安全な最小余白は確保）
    private var topInset: CGFloat { max(6, 6 * fontScale) }
    private var bottomInset: CGFloat { max(8, 8 * fontScale) }

    // Dynamic height: shrink when anonymous text-only and single line
    private var dynamicHeight: CGFloat {
        let baseHeight: CGFloat = 30

        if !post.text.isEmpty {
            // テキストの行数に基づく高さ計算
            let lineHeight: CGFloat = 12 * fontScale
            let textHeight = max(lineHeight, CGFloat(estimatedTextLines) * lineHeight)

            // パディングとマージン
            let padding: CGFloat = 16 * fontScale

            return max(baseHeight, textHeight + padding)
        }

        if hasImage {
            // 画像サイズに合わせて高さを調整
            let isPhotoOnly = post.text.isEmpty
            let inset: CGFloat = 3 * fontScale
            let imageSize = cardWidth - inset * 2
            let verticalPadding = isPhotoOnly ? 6 * fontScale : 30 * fontScale
            return imageSize + verticalPadding // 画像サイズ + 上下のパディング
        }

        return baseHeight
    }

    private var stackSpacing: CGFloat {
        if isCompactTextOnly { return 0 }
        // Remove inter-item spacing entirely when meta is hidden to avoid blank bands
        return showMeta ? (post.isAnonymous ? 4 * fontScale : 2 * fontScale) : 0
    }

    //###########################################################################
    // MARK: - Content Properties
    // Function: hasImage, showMeta, estimatedTextLines
    // Overview: Content-related computed properties
    // Processing: Check content type → Calculate display options
    //###########################################################################

    // メタデータ（アイコンとID）を投稿カード内に表示しない
    private var showMeta: Bool { false }
    private var showHeaderMeta: Bool { false }
    private var hasImage: Bool { PostPinUtilities.hasImageContent(post) }
    private var isCompactTextOnly: Bool { !hasImage && !post.text.isEmpty && !showMeta }

    // Estimate text lines for dynamic layout (rough but fast)
    private var estimatedTextLines: Int {
        guard !post.text.isEmpty else { return 0 }
        // Approximate characters per line for current width/font
        let charsPerLine = hasImage ? 14 : 22
        return max(1, Int(ceil(Double(post.text.count) / Double(charsPerLine))))
    }

    private var isSingleLine: Bool { estimatedTextLines == 1 }

    //###########################################################################
    // MARK: - Main Body
    // Function: body
    // Overview: Main view rendering with conditional visibility
    // Processing: Check shouldHide → Render card or EmptyView → Apply modals
    //###########################################################################

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
                .postPinModals(
                    showingUserProfile: $showingUserProfile,
                    showingImageViewer: $showingImageViewer,
                    showingDeleteAlert: $showingDeleteAlert,
                    post: post,
                    onDelete: {
                        await PostManager.shared.deletePost(post.id)
                    }
                )
        }
    }

    //###########################################################################
    // MARK: - Card View
    // Function: cardView
    // Overview: Main card rendering with image, text, and interactions
    // Processing: Render VStack with content → Apply glass effect → Add overlays
    //###########################################################################

    @ViewBuilder
    private var cardView: some View {
        let dynamicCornerRadius: CGFloat = cardCornerRadius

        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: stackSpacing) {
            if showHeaderMeta && !hasImage {
                HStack(spacing: 3 * fontScale) {
                    Button(action: {
                        logger.info("Profile icon tapped in post header")
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
                        logger.info("User ID tapped in post header")
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
                let inset: CGFloat = 3 * fontScale
                let imageSize = cardWidth - inset * 2
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8 * fontScale))
                    .padding(.horizontal, inset)
                    .padding(.top, 3 * fontScale)
                    .padding(.bottom, isPhotoOnly ? 3 * fontScale : 0)
                    .id("\(post.id)-scalable-image") // ScalablePostPinの画像にもIDを付与
            } else if let imageUrl = post.imageUrl {
                let isPhotoOnly = post.text.isEmpty
                let inset: CGFloat = 3 * fontScale
                let imageSize = cardWidth - inset * 2
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 8 * fontScale))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 8 * fontScale))
                        .overlay(ProgressView().scaleEffect(0.5 * fontScale))
                }
                .id("\(post.id)-scalable-async-image") // ScalablePostPinのAsyncImageにもIDを付与
                .padding(.horizontal, inset)
                .padding(.top, 3 * fontScale)
                .padding(.bottom, isPhotoOnly ? 3 * fontScale : 0)
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

            // Spacer to push action bar to bottom
            Spacer(minLength: 2 * fontScale)

            if showHeaderMeta {
                HStack(spacing: 12 * fontScale) {
                    Button(action: {
                        logger.info("Like button tapped")
                        if let userId = authManager.currentUser?.id {
                            let newLikeState = likeService.toggleLike(for: post, userId: userId)
                            if newLikeState {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        } else {
                            logger.warning("Like action ignored - user not authenticated")
                        }
                    }) {
                        Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                            .font(.system(size: 10 * fontScale))
                            .foregroundColor(likeService.isLiked(post.id) ? Color(red: 1.0, green: 0.3, blue: 0.3) : .white.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            logger.info("Comment button tapped")
                        }) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 10 * fontScale))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8 * fontScale)
                .padding(.bottom, 16 * fontScale)
                .contentShape(Rectangle())
            }
        }  // Close VStack
        .frame(width: cardWidth, height: dynamicHeight + 10 * fontScale) // Added tail height

        // Delete button overlay - always show for own posts
        if post.authorId == authManager.currentUser?.id {
            Menu {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Post", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12 * fontScale, weight: .bold))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(8 * fontScale)
        }
        }  // Close ZStack (alignment: .topTrailing)
        // Apply transparent Liquid Glass effect with speech bubble
        .glassEffect(.clear, in: PostCardBubbleShape(cornerRadius: dynamicCornerRadius, tailWidth: 20 * fontScale, tailHeight: 10 * fontScale))
        .overlay(alignment: .bottom) {
            // Hide profile icon for anonymous posts
            if !post.isAnonymous && scaleFactor >= 0.9 {
                let minDiameter: CGFloat = 16
                let maxDiameter: CGFloat = 40
                let diameter = min(maxDiameter, minDiameter + (scaleFactor - 0.9) * 40)

                Button(action: {
                    logger.info("Profile avatar tapped")
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
        }  // Close overlay
    }  // Close cardView
}  // End of ScalablePostPin struct
