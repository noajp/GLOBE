//======================================================================
// MARK: - PostPin.swift
// Purpose: Post display components for map pins with speech bubble design
// Path: GLOBE/Views/Components/PostPin.swift
//======================================================================

import SwiftUI
import Foundation

struct PostPin: View {
    private let customBlack = MinimalDesign.Colors.background
    let post: Post
    let onTap: () -> Void
    @StateObject private var commentService = CommentService.shared
    @StateObject private var likeService = LikeService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingUserProfile = false
    @State private var showingDetailedPost = false
    @State private var showingImageViewer = false
    // Slightly thicker border for better visibility
    private var borderWidth: CGFloat { 1.2 }
    
    // Calculate dynamic height based on content
    private var cardHeight: CGFloat {
        // 上下の余白を抑えて写真に合わせる
        let headerHeight: CGFloat = post.isAnonymous ? 18 : 10
        let footerHeight: CGFloat = 6
        let lineHeight: CGFloat = 9
        let padding: CGFloat = 6 // 上下パディング

        let hasImage = (post.imageData != nil) || (post.imageUrl != nil)
        let imageHeight: CGFloat = hasImage ? (cardWidth - 8) : 0 // square image: width == height
        let textHeight: CGFloat = post.text.isEmpty ? 0 : CGFloat(actualTextLines) * lineHeight
        let contentHeight = imageHeight + textHeight

        // 追加の上下ゆとりは最小限に（上6pt+下2pt相当）
        let extraMetaPadding: CGFloat = post.isAnonymous ? 0 : (6 + 2)
        return headerHeight + contentHeight + footerHeight + padding + extraMetaPadding
    }
    
    private var cardWidth: CGFloat {
        // Widen the fixed card width slightly
        return 112
    }
    
    private var actualTextLines: Int {
        if post.text.isEmpty { return 0 }
        let charactersPerLine = 13
        let lineCount = Int(ceil(Double(post.text.count) / Double(charactersPerLine)))
        return max(1, lineCount)
    }
    
    var body: some View {
        VStack(spacing: post.isAnonymous ? 4 : 0) {
            // ヘッダー（非公開投稿のみ表示）- 画像がない時のみ上に表示（画像がある時は下に表示）
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
            } else {
                // 匿名投稿時は上部パディングを追加（より余裕を持たせる）
                Spacer()
                    .frame(height: 18)
            }
            
            // コンテンツエリア - 写真があれば写真＋（あれば）テキスト、なければテキストのみ
            if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth - 8, height: cardWidth - 8)
                    .clipped()
                    .padding(.horizontal, 4)
                    .onTapGesture { showingImageViewer = true }

                // ヘッダー（写真の下に表示）
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
                    Text(post.text)
                        .font(.system(size: 7))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: cardWidth - 8, alignment: .leading)
                        // Start text one character to the right
                        .padding(.leading, 11)
                        .padding(.trailing, 4)
                        .padding(.top, 4) // 画像と文章の間に間隔
                }
            } else if let imageUrl = post.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth - 8, height: cardWidth - 8)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: cardWidth - 8, height: cardWidth - 8)
                        .overlay(ProgressView().scaleEffect(0.5))
                }
                .padding(.horizontal, 4)
                .onTapGesture { showingImageViewer = true }

                // ヘッダー（写真の下に表示）
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
                    Text(post.text)
                        .font(.system(size: 7))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: cardWidth - 8, alignment: .leading)
                        .padding(.leading, 4)
                        .padding(.trailing, 4)
                        .padding(.top, 4)
                }
            } else if !post.text.isEmpty {
                // 文字領域を最大化
                Text(post.text)
                    .font(.system(size: 7))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: cardWidth - 8, alignment: .leading)
                    // Start text one character to the right
                    .padding(.leading, 11)
                    .padding(.trailing, 4)
                    .padding(.top, post.isAnonymous ? 8 : 0) // 匿名投稿時は上部パディング追加
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
                        showingDetailedPost = true
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
            } else {
                // 匿名投稿時は下部パディングを追加
                Spacer()
                    .frame(height: 6)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .padding(.bottom, 14)
        // Unified bubble fill (rounded rect + V-tail)
        .background(
            SpeechBubbleShape(cornerRadius: 8, tailWidth: 16, tailHeight: 12)
                .fill(customBlack)
        )
        // Clip inner content to bubble shape to avoid overflow beyond border
        .clipShape(SpeechBubbleShape(cornerRadius: 8, tailWidth: 16, tailHeight: 12))
        // Unified bubble border with consistent width
        .overlay(
            SpeechBubbleShape(cornerRadius: 8, tailWidth: 16, tailHeight: 12)
                .strokeBorder(Color.white.opacity(0.9), lineWidth: borderWidth)
                .allowsHitTesting(false)
        )
        // Profile icon at V-tip for non-anonymous posts (small-pin variant)
        .overlay(alignment: .bottom) {
            if !post.isAnonymous {
                let diameter: CGFloat = 20
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
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    } else {
                        Circle().fill(Color.blue.opacity(0.7))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: diameter * 0.4))
                            )
                            .frame(width: diameter, height: diameter)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }
                // Position at the V-tip: move down by triangle height + half avatar
                .offset(y: 12 + diameter/2) // Fixed triangle height for standard PostPin
                .zIndex(10)
                .allowsHitTesting(false)
            }
        }
        .shadow(color: customBlack.opacity(0.3), radius: 4, x: 0, y: 2)
        .onAppear {
            commentService.loadComments(for: post.id)
            likeService.initializePost(post)
        }
        .sheet(isPresented: $showingUserProfile) {
            UserProfileView(
                userName: post.authorName,
                userId: post.authorId,
                isPresented: $showingUserProfile
            )
        }
        .sheet(isPresented: $showingDetailedPost) {
            DetailedPostView(
                post: post,
                isPresented: $showingDetailedPost
            )
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            if let data = post.imageData, let ui = UIImage(data: data) {
                PhotoViewerView(image: ui) { showingImageViewer = false }
            } else if let urlString = post.imageUrl, let url = URL(string: urlString) {
                PhotoViewerView(imageURL: url) { showingImageViewer = false }
            }
        }
    }
}

// Scalable PostPin that adjusts size based on map zoom level
struct ScalablePostPin: View {
    private let customBlack = MinimalDesign.Colors.background
    let post: Post
    let mapSpan: Double
    @StateObject private var commentService = CommentService.shared
    @StateObject private var likeService = LikeService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingUserProfile = false
    @State private var showingDetailedPost = false
    @State private var showingImageViewer = false
    // Slightly thicker border for better visibility
    private var borderWidth: CGFloat { 1.2 }
    
    private var scaleFactor: CGFloat {
        let baseSpan: Double = 0.01
        let maxScale: CGFloat = 1.5
        // Prevent over-shrinking causing clipped/illegible content
        let minScale: CGFloat = 0.8
        let scale = CGFloat(baseSpan / max(mapSpan, 0.001))
        let popularityBonus: CGFloat = post.likeCount >= 10 ? 1.2 : 1.0
        return max(minScale, min(maxScale, scale * popularityBonus))
    }
    
    private let baseCardSize: CGFloat = 112
    private let baseTriangleWidth: CGFloat = 16
    private let baseTriangleHeight: CGFloat = 12
    
    private var cardWidth: CGFloat {
        // Use standard width regardless of photo presence
        return baseCardSize * scaleFactor
    }
    
    private var triangleSize: CGSize {
        CGSize(
            width: baseTriangleWidth * scaleFactor,
            height: baseTriangleHeight * scaleFactor
        )
    }
    
    private var fontScale: CGFloat {
        // Keep fonts readable even when zoomed out
        max(0.8, min(1.0, scaleFactor))
    }

    // Fixed minimum insets regardless of zoom
    // Bring actions少し下辺に近づける（安全な最小余白は確保）
    private var topInset: CGFloat { max(6, 6 * fontScale) }
    private var bottomInset: CGFloat { max(8, 8 * fontScale) }

    // Show header (author icon + id) only for non-public posts; public posts use a base map icon instead
    private var showMeta: Bool { !post.isAnonymous && scaleFactor >= 0.9 }
    private var showHeaderMeta: Bool { !post.isAnonymous && !post.isPublic && scaleFactor >= 0.9 }
    private var hasImage: Bool { (post.imageData != nil) || (post.imageUrl != nil) }
    private var isCompactTextOnly: Bool { !showMeta && !hasImage && !post.text.isEmpty }

    // Estimate text lines for dynamic layout (rough but fast)
    private var estimatedTextLines: Int {
        guard !post.text.isEmpty else { return 0 }
        // Approximate characters per line for current width/font
        let charsPerLine = 12
        return max(1, Int(ceil(Double(post.text.count) / Double(charsPerLine))))
    }

    private var isSingleLine: Bool { estimatedTextLines == 1 }

    // Dynamic height: shrink when anonymous text-only and single line
    private var dynamicHeight: CGFloat {
        let base = cardWidth * 0.75
        if hasImage {
            // Square photo height equals inner card width (minus horizontal padding)
            let imageH: CGFloat = (cardWidth - 8)
            var h = showMeta
                ? max(imageH + 44 * fontScale, 80)
                : max(imageH + 6 * fontScale, 50)
            // 枠自体に上6pt＋下8ptぶんの最小ゆとりを反映
            h += topInset + bottomInset
            return h
        }

        // Tighten height aggressively when zoomed out and text-only
        if isCompactTextOnly {
            let perLine: CGFloat = 12 * fontScale
            let minHeight: CGFloat = 18 * fontScale
            return max(minHeight, perLine * CGFloat(max(1, estimatedTextLines)))
        }

        // Lower absolute minimums more when meta is hidden (zoomed out)
        let absMin = showMeta ? 52.0 : 32.0

        var h: CGFloat
        if isSingleLine {
            // Make the card clearly slim for one-line text
            h = max(absMin, base * (showMeta ? 0.45 : 0.40))
        } else if estimatedTextLines == 2 {
            h = max(absMin + 1, base * (showMeta ? 0.58 : 0.52))
        } else {
            h = max(absMin + 4, base * (showMeta ? 0.70 : 0.65))
        }
        // 枠自体に上6pt＋下8ptぶんの最小ゆとりを反映
        return h + topInset + bottomInset
    }

    private var stackSpacing: CGFloat {
        if isCompactTextOnly { return 0 }
        // Remove inter-item spacing entirely when meta is hidden to avoid blank bands
        return showMeta ? (post.isAnonymous ? 4 * fontScale : 2 * fontScale) : 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: stackSpacing) {
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
                    // Shift a bit more to the left (smaller leading, larger trailing)
                    .padding(.leading, (isSingleLine ? 6 : 4) * fontScale)
                    .padding(.trailing, (isSingleLine ? 12 : 10) * fontScale)
                    // Top spacing: at least 6pt regardless of zoom
                    .padding(.top, topInset)
                    .contentShape(Rectangle())
                }
                
                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth - 8, height: cardWidth - 8)
                        .clipShape(RoundedRectangle(cornerRadius: 4 * fontScale))
                        .padding(.horizontal, 4 * fontScale)
                        .onTapGesture { showingImageViewer = true }
                } else if let imageUrl = post.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: cardWidth - 8, height: cardWidth - 8)
                            .clipShape(RoundedRectangle(cornerRadius: 4 * fontScale))
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: cardWidth - 8, height: cardWidth - 8)
                            .clipShape(RoundedRectangle(cornerRadius: 4 * fontScale))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.5 * fontScale)
                            )
                    }
                    .padding(.horizontal, 4 * fontScale)
                    .onTapGesture { showingImageViewer = true }
                }
                
                // 画像がある場合はヘッダーを写真の下に表示
                if showMeta && hasImage {
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
                    .padding(.top, 4 * fontScale)
                }

                if !post.text.isEmpty {
                    Text(post.text)
                        .font(.system(size: 9 * fontScale))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(scaleFactor < 0.9 ? 2 : nil)
                        .truncationMode(.tail)
                        .frame(maxWidth: cardWidth - 8, alignment: .leading)
                        // Start text one character to the right
                        .padding(.leading, (4 + 9) * fontScale)
                        .padding(.trailing, 4 * fontScale)
                        // 画像がある場合は画像との間を少し空ける
                        .padding(.top, hasImage ? (4 * fontScale) : (isCompactTextOnly ? 0 : (showMeta ? (post.isAnonymous ? 6 * fontScale : 2 * fontScale) : 2 * fontScale)))
                        .padding(.bottom, isCompactTextOnly ? 0 : (showMeta ? ((isSingleLine ? 2 : 4) * fontScale) : ((isSingleLine ? 1 : 2) * fontScale)))
                }
                // Remove Spacer to avoid extra vertical whitespace
                
                if showHeaderMeta {
                    HStack(spacing: 2 * fontScale) {
                        // Like (left) then Comment (right)
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
                            showingDetailedPost = true
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
                    .padding(.leading, 0)
                    .padding(.trailing, 4 * fontScale)
                    // Bring actions closer to the bottom but keep a small safety gap
                    .padding(.top, 1 * fontScale)
                    .padding(.bottom, max(6, (6 + borderWidth) * fontScale))
                    .contentShape(Rectangle())
                }
            }
            .frame(width: cardWidth, height: dynamicHeight)
            // Unified bubble fill (rounded rect + V-tail)
            .background(
                SpeechBubbleShape(
                    cornerRadius: 8 * fontScale,
                    tailWidth: triangleSize.width,
                    tailHeight: triangleSize.height
                )
                .fill(customBlack)
            )
            // Clip inner content to bubble shape to avoid overflow beyond border
            .clipShape(
                SpeechBubbleShape(
                    cornerRadius: 8 * fontScale,
                    tailWidth: triangleSize.width,
                    tailHeight: triangleSize.height
                )
            )
            // Unified bubble border with consistent width
            .overlay(
                SpeechBubbleShape(
                    cornerRadius: 8 * fontScale,
                    tailWidth: triangleSize.width,
                    tailHeight: triangleSize.height
                )
                .strokeBorder(Color.white.opacity(0.9), lineWidth: borderWidth)
                .allowsHitTesting(false)
            )
            // Profile icon at the exact V-tip (apex) for non-anonymous posts
            .overlay(alignment: .bottom) {
                if !post.isAnonymous {
                    let diameter = 28 * fontScale
                    Group {
                        if let urlString = post.authorAvatarUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                                    .overlay(Image(systemName: "person.fill").foregroundColor(.white))
                            }
                            .frame(width: diameter, height: diameter)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else {
                            Circle().fill(Color.gray.opacity(0.3))
                                .overlay(Image(systemName: "person.fill").foregroundColor(.white))
                                .frame(width: diameter, height: diameter)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                    // Position at the V-tip: move down by triangle height + half avatar
                    .offset(y: triangleSize.height + diameter/2)
                    .zIndex(10)
                    .allowsHitTesting(false)
                }
            }
            // Extra bottom inset so the outside avatar is not clipped by parent bounds
            .padding(.bottom, triangleSize.height + (14 * fontScale))
            .shadow(color: customBlack.opacity(0.3), radius: 4 * fontScale, x: 0, y: 2 * fontScale)
        }
        .onAppear {
            commentService.loadComments(for: post.id)
            likeService.initializePost(post)
        }
        .sheet(isPresented: $showingUserProfile) {
            UserProfileView(
                userName: post.authorName,
                userId: post.authorId,
                isPresented: $showingUserProfile
            )
        }
        .sheet(isPresented: $showingDetailedPost) {
            DetailedPostView(
                post: post,
                isPresented: $showingDetailedPost
            )
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            if let data = post.imageData, let ui = UIImage(data: data) {
                PhotoViewerView(image: ui) { showingImageViewer = false }
            } else if let urlString = post.imageUrl, let url = URL(string: urlString) {
                PhotoViewerView(imageURL: url) { showingImageViewer = false }
            }
        }
    }
}

// Triangle shape for post pin speech bubble
struct PostPinTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

// Outline-only shape for the triangle's two sides (no base line)
struct PostPinTriangleOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let apex = CGPoint(x: rect.midX, y: rect.minY)
        let left = CGPoint(x: rect.minX, y: rect.maxY)
        let right = CGPoint(x: rect.maxX, y: rect.maxY)
        path.move(to: apex)
        path.addLine(to: left)
        path.move(to: apex)
        path.addLine(to: right)
        return path
    }
}

// Mask shape to hide a bottom-center segment of the card border
// Creates a rectangular hole (gap) on the bottom edge so the horizontal base line
// doesn't appear behind the V-tail.
struct BottomEdgeGapMask: Shape {
    let gapWidth: CGFloat
    let gapHeight: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Full rect
        p.addRect(rect)
        // Gap rect at bottom center
        let gapRect = CGRect(
            x: rect.midX - gapWidth / 2,
            y: rect.maxY - gapHeight,
            width: gapWidth,
            height: gapHeight
        )
        p.addRect(gapRect)
        return p
    }
}

//======================================================================
// MARK: - SpeechBubbleShape
// Purpose: Single shape combining rounded rect body and V-tail for crisp fill/stroke
//======================================================================
struct SpeechBubbleShape: InsettableShape {
    var cornerRadius: CGFloat
    var tailWidth: CGFloat
    var tailHeight: CGFloat
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var s = self
        s.insetAmount += amount
        return s
    }

    func path(in rect: CGRect) -> Path {
        let rectInset = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let r = max(0, min(cornerRadius - insetAmount, min(rectInset.width, rectInset.height) / 2))
        let minX = rectInset.minX
        let maxX = rectInset.maxX
        let minY = rectInset.minY
        let maxY = rectInset.maxY
        let midX = rectInset.midX

        let adjustedTailWidth = max(0, tailWidth - insetAmount * 2)
        let adjustedTailHeight = max(0, tailHeight - insetAmount)
        let halfTail = max(0, min(adjustedTailWidth / 2, (rectInset.width / 2) - r))
        let leftJoin = CGPoint(x: midX - halfTail, y: maxY)
        let rightJoin = CGPoint(x: midX + halfTail, y: maxY)
        let apex = CGPoint(x: midX, y: maxY + adjustedTailHeight)

        var p = Path()
        // Start at top-left horizontal start
        p.move(to: CGPoint(x: minX + r, y: minY))
        // Top edge to top-right
        p.addLine(to: CGPoint(x: maxX - r, y: minY))
        // Top-right corner arc
        p.addArc(
            center: CGPoint(x: maxX - r, y: minY + r),
            radius: r,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        // Right edge down
        p.addLine(to: CGPoint(x: maxX, y: maxY - r))
        // Bottom-right corner arc
        p.addArc(
            center: CGPoint(x: maxX - r, y: maxY - r),
            radius: r,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        // Bottom edge to tail start
        p.addLine(to: rightJoin)
        // Tail V
        p.addLine(to: apex)
        p.addLine(to: leftJoin)
        // Bottom edge continue to bottom-left arc start
        p.addLine(to: CGPoint(x: minX + r, y: maxY))
        // Bottom-left corner arc
        p.addArc(
            center: CGPoint(x: minX + r, y: maxY - r),
            radius: r,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        // Left edge up
        p.addLine(to: CGPoint(x: minX, y: minY + r))
        // Top-left corner arc
        p.addArc(
            center: CGPoint(x: minX + r, y: minY + r),
            radius: r,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        p.closeSubpath()
        return p
    }
}
