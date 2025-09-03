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
    
    // Calculate dynamic height based on content
    private var cardHeight: CGFloat {
        // 匿名投稿は上部により余裕を持たせる
        let headerHeight: CGFloat = post.isAnonymous ? 18 : 8  // 匿名時は上部スペース多め
        let footerHeight: CGFloat = post.isAnonymous ? 6 : 8   // 匿名時は下部スペース
        let lineHeight: CGFloat = 9
        let padding: CGFloat = 8 // 上下パディング
        
        let contentHeight = CGFloat(actualTextLines) * lineHeight
        
        return headerHeight + contentHeight + footerHeight + padding
    }
    
    private var cardWidth: CGFloat {
        return 96
    }
    
    private var actualTextLines: Int {
        if post.text.isEmpty { return 0 }
        let charactersPerLine = 13
        let lineCount = Int(ceil(Double(post.text.count) / Double(charactersPerLine)))
        return max(1, lineCount)
    }
    
    var body: some View {
        VStack(spacing: post.isAnonymous ? 4 : 0) {
            // ヘッダー - 匿名投稿では非表示だがスペースは確保
            if !post.isAnonymous {
                HStack(spacing: 3) {
                    Button(action: { showingUserProfile = true }) {
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
                    
                    Text("ID: \(post.authorId.prefix(6))")
                        .font(.system(size: 6, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    Spacer()
                }
                .frame(height: 8)
                .padding(.horizontal, 4)
            } else {
                // 匿名投稿時は上部パディングを追加（より余裕を持たせる）
                Spacer()
                    .frame(height: 18)
            }
            
            // コンテンツエリア - 文字または写真（最大領域を使用）
            if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth - 8, height: CGFloat(actualTextLines) * 9)
                    .clipped()
                    .padding(.horizontal, 4)
            } else if let imageUrl = post.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth - 8, height: CGFloat(actualTextLines) * 9)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: cardWidth - 8, height: CGFloat(actualTextLines) * 9)
                        .overlay(ProgressView().scaleEffect(0.5))
                }
                .padding(.horizontal, 4)
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
                    .padding(.horizontal, 4)
                    .padding(.top, post.isAnonymous ? 8 : 0) // 匿名投稿時は上部パディング追加
            }
            
            // フッター - 匿名投稿では非表示だがスペースは確保
            if !post.isAnonymous {
                HStack(spacing: 4) {
                    Button(action: {
                        if let userId = authManager.currentUser?.id {
                            let newLikeState = likeService.toggleLike(for: post, userId: userId)
                            if newLikeState {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }) {
                        HStack(spacing: 1) {
                            Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                                .font(.system(size: 6))
                                .foregroundColor(likeService.isLiked(post.id) ? .red : .white.opacity(0.8))
                            
                            let likeCount = likeService.getLikeCount(for: post.id)
                            if likeCount > 0 {
                                Text("\(likeCount)")
                                    .font(.system(size: 5))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showingDetailedPost = true }) {
                        HStack(spacing: 1) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 6))
                                .foregroundColor(.white.opacity(0.8))
                            
                            let count = commentService.getCommentCount(for: post.id)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 5))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .frame(height: 8)
                .padding(.horizontal, 4)
            } else {
                // 匿名投稿時は下部パディングを追加
                Spacer()
                    .frame(height: 6)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(customBlack)
        .cornerRadius(8)
        .overlay(
            PostPinTriangle()
                .fill(customBlack)
                .frame(width: 16, height: 12)
                .rotationEffect(Angle.degrees(180))
                .offset(y: 12),
            alignment: .bottom
        )
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
    
    private var scaleFactor: CGFloat {
        let baseSpan: Double = 0.01
        let maxScale: CGFloat = 1.5
        // Prevent over-shrinking causing clipped/illegible content
        let minScale: CGFloat = 0.8
        let scale = CGFloat(baseSpan / max(mapSpan, 0.001))
        let popularityBonus: CGFloat = post.likeCount >= 10 ? 1.2 : 1.0
        return max(minScale, min(maxScale, scale * popularityBonus))
    }
    
    private let baseCardSize: CGFloat = 96
    private let baseTriangleWidth: CGFloat = 16
    private let baseTriangleHeight: CGFloat = 12
    
    private var cardSize: CGFloat {
        baseCardSize * scaleFactor
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

    private var showMeta: Bool { !post.isAnonymous && scaleFactor >= 0.9 }

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
        let base = cardSize * 0.75
        let hasImage = (post.imageData != nil) || (post.imageUrl != nil)
        if hasImage { return max(base, 72) }

        // Absolute minimums to avoid clipping when zoomed out
        let absMin = showMeta ? 68.0 : 56.0

        if isSingleLine {
            return max(absMin, base * 0.6)
        } else if estimatedTextLines == 2 {
            return max(absMin + 4, base * 0.7)
        }
        return max(absMin + 8, base)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: post.isAnonymous ? (6 * fontScale) : (3 * fontScale)) {
                if showMeta {
                    HStack(spacing: 4 * fontScale) {
                        Button(action: {
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
                            showingUserProfile = true
                        }) {
                            VStack(alignment: .leading, spacing: 1 * fontScale) {
                                Text("ID: \(post.authorId.prefix(8))")
                                    .font(.system(size: 9 * fontScale, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4 * fontScale)
                    .padding(.top, 4 * fontScale)
                }
                
                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 84 * scaleFactor, height: 50 * scaleFactor)
                        .clipShape(RoundedRectangle(cornerRadius: 4 * fontScale))
                    .padding(.horizontal, 4 * fontScale)
                } else if let imageUrl = post.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 84 * scaleFactor, height: 50 * scaleFactor)
                            .clipShape(RoundedRectangle(cornerRadius: 4 * fontScale))
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 84 * scaleFactor, height: 50 * scaleFactor)
                            .clipShape(RoundedRectangle(cornerRadius: 4 * fontScale))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.5 * fontScale)
                            )
                    }
                    .padding(.horizontal, 4 * fontScale)
                }
                
                if !post.text.isEmpty {
                    Text(post.text)
                        .font(.system(size: 9 * fontScale))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(scaleFactor < 0.9 ? 2 : nil)
                        .truncationMode(.tail)
                        .frame(maxWidth: 84 * scaleFactor, alignment: .leading)
                        .padding(.horizontal, 4 * fontScale)
                        // Keep a small top inset so text isn't glued to the edge
                        .padding(.top, post.isAnonymous || !showMeta ? 8 * fontScale : 2 * fontScale)
                        // Reduce bottom padding when single line to make the card slimmer
                        .padding(.bottom, (isSingleLine ? 4 : 6) * fontScale)
                }
                // Remove Spacer to avoid extra vertical whitespace
                
                if showMeta {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            if let userId = authManager.currentUser?.id {
                                let newLikeState = likeService.toggleLike(for: post, userId: userId)
                                if newLikeState {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                            }
                        }) {
                            HStack(spacing: 2 * fontScale) {
                                Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                                    .font(.system(size: 10 * fontScale))
                                    .foregroundColor(likeService.isLiked(post.id) ? .red : .white.opacity(0.8))
                                
                                let likeCount = likeService.getLikeCount(for: post.id)
                                if likeCount > 0 {
                                    Text("\(likeCount)")
                                        .font(.system(size: 8 * fontScale))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            showingDetailedPost = true
                        }) {
                            HStack(spacing: 2 * fontScale) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 10 * fontScale))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                let count = commentService.getCommentCount(for: post.id)
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 8 * fontScale))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 4 * fontScale)
                    .padding(.bottom, 4 * fontScale)
                }
            }
            .frame(width: cardSize, height: dynamicHeight)
            .background(customBlack)
            .cornerRadius(8 * fontScale)
            .overlay(
                PostPinTriangle()
                    .fill(customBlack)
                    .frame(width: triangleSize.width, height: triangleSize.height)
                    .rotationEffect(Angle.degrees(180))
                    .offset(y: triangleSize.height),
                alignment: .bottom
            )
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
