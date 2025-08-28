import SwiftUI
import Foundation

struct PostPin: View {
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    let post: Post
    let onTap: () -> Void
    @StateObject private var commentService = CommentService.shared
    @StateObject private var likeService = LikeService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingUserProfile = false
    @State private var showingDetailedPost = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 4:3 ratio card container
            HStack(spacing: 0) {
                // Left side: Image (square, 3:3)
                Group {
                    if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                        // ローカル画像データがある場合（投稿直後）
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipped()
                    } else if let imageUrl = post.imageUrl {
                        // リモート画像URLから読み込み
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 72, height: 72)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.5)
                                )
                        }
                    } else {
                        // Placeholder for no image
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                
                // Right side: Content (1:3 width)
                VStack(alignment: .leading, spacing: 2) {
                    // Header with profile icon and username
                    HStack(spacing: 3) {
                        Button(action: {
                            showingUserProfile = true
                        }) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Text(post.authorName.prefix(1).uppercased())
                                        .font(.system(size: 6, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("@\(post.authorName.lowercased().replacingOccurrences(of: " ", with: ""))")
                                .font(.system(size: 7, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                    
                    // Post text
                    if !post.text.isEmpty {
                        Text(post.text.prefix(25) + (post.text.count > 25 ? "..." : ""))
                            .font(.system(size: 7))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Location info
                    HStack(spacing: 1) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.red.opacity(0.8))
                        Text(post.locationName ?? "位置を取得中...")
                            .font(.system(size: 6, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    
                    // Action buttons
                    HStack(spacing: 6) {
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
                            HStack(spacing: 1) {
                                Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                                    .font(.system(size: 8))
                                    .foregroundColor(likeService.isLiked(post.id) ? .red : .white.opacity(0.8))
                                
                                let likeCount = likeService.getLikeCount(for: post.id)
                                if likeCount > 0 {
                                    Text("\(likeCount)")
                                        .font(.system(size: 7))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Comment button
                        Button(action: {
                            showingDetailedPost = true
                        }) {
                            HStack(spacing: 1) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                let count = commentService.getCommentCount(for: post.id)
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 7))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                }
                .padding(4)
                .frame(width: 24, height: 72) // Right side width (1:3 ratio)
            }
            .frame(width: 96, height: 72) // 4:3 aspect ratio (96:72)
            .background(customBlack)
            .cornerRadius(8)
            .overlay(
                // Speech bubble tail pointing down
                PostPinTriangle()
                    .fill(customBlack)
                    .frame(width: 16, height: 12)
                    .rotationEffect(.degrees(180))
                    .offset(y: 12),
                alignment: .bottom
            )
            .shadow(color: customBlack.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .onAppear {
            // Load comments for this post
            commentService.loadComments(for: post.id)
            // Initialize like data for this post
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
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    let post: Post
    let mapSpan: Double
    @StateObject private var commentService = CommentService.shared
    @StateObject private var likeService = LikeService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingUserProfile = false
    @State private var showingDetailedPost = false
    
    // Calculate scale factor based on map span
    private var scaleFactor: CGFloat {
        // Base scale when map span is around 0.01 (city level)
        let baseSpan: Double = 0.01
        let maxScale: CGFloat = 1.5  // より大きく表示
        let minScale: CGFloat = 0.6  // 最小サイズを大きく
        
        // Calculate scale inversely proportional to span
        let scale = CGFloat(baseSpan / max(mapSpan, 0.001))
        
        // 人気投稿はより大きく表示
        let popularityBonus: CGFloat = post.likeCount >= 10 ? 1.2 : 1.0
        
        return max(minScale, min(maxScale, scale * popularityBonus))
    }
    
    // Base dimensions that will be scaled
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
    
    // Scale font sizes appropriately
    private var fontScale: CGFloat {
        max(0.5, min(1.0, scaleFactor))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // カードコンテナ
            VStack(spacing: 4 * fontScale) {
                // Header with profile icon and user ID - tappable
                HStack(spacing: 6 * fontScale) {
                    // Profile icon - tappable
                    Button(action: {
                        showingUserProfile = true
                    }) {
                        RoundedRectangle(cornerRadius: 4 * fontScale)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20 * fontScale, height: 20 * fontScale)
                            .overlay(
                                Text(post.authorName.prefix(1).uppercased())
                                    .font(.system(size: 10 * fontScale, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Username and User ID - tappable
                    Button(action: {
                        showingUserProfile = true
                    }) {
                        VStack(alignment: .leading, spacing: 1 * fontScale) {
                            Text("@\(post.authorName.lowercased().replacingOccurrences(of: " ", with: ""))")
                                .font(.system(size: 9 * fontScale, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                            Text("ID: \(post.authorId.prefix(8))")
                                .font(.system(size: 7 * fontScale, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.horizontal, 6 * fontScale)
                .padding(.top, 6 * fontScale)
                
                // 写真がある場合は画像を表示
                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                    // ローカル画像データがある場合（投稿直後）
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 84 * scaleFactor, height: 50 * scaleFactor)
                        .clipShape(RoundedRectangle(cornerRadius: 4 * fontScale))
                        .padding(.horizontal, 6 * fontScale)
                } else if let imageUrl = post.imageUrl {
                    // リモート画像URLから読み込み
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
                    .padding(.horizontal, 6 * fontScale)
                }
                
                // 投稿テキスト - シンプル表示
                if !post.text.isEmpty {
                    Text(post.text.prefix(30) + (post.text.count > 30 ? "..." : ""))
                        .font(.system(size: 9 * fontScale))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: 84 * scaleFactor, alignment: .leading)
                        .padding(.horizontal, 6 * fontScale)
                }
                
                // Location display - shows the address where the pin tip points
                HStack(spacing: 2 * fontScale) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 8 * fontScale))
                        .foregroundColor(.red.opacity(0.8))
                    Text(post.locationName ?? "位置を取得中...")
                        .font(.system(size: 8 * fontScale, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 6 * fontScale)
                .padding(.vertical, 2 * fontScale)
                .background(customBlack.opacity(0.8))
                .cornerRadius(4 * fontScale)
                
                Spacer()
                
                // Like and Comment section at bottom right
                HStack {
                    Spacer()
                    
                    // Like button
                    Button(action: {
                        if let userId = authManager.currentUser?.id {
                            let newLikeState = likeService.toggleLike(for: post, userId: userId)
                            // Haptic feedback
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
                                    .font(.system(size: 9 * fontScale))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Comment button
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
                                    .font(.system(size: 9 * fontScale))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 6 * fontScale)
                .padding(.bottom, 6 * fontScale)
            }
            .frame(width: cardSize, height: cardSize)
            .background(customBlack)
            .cornerRadius(8 * fontScale)
            .overlay(
                // Speech bubble tail pointing down
                PostPinTriangle()
                    .fill(customBlack)
                    .frame(width: triangleSize.width, height: triangleSize.height)
                    .rotationEffect(.degrees(180))
                    .offset(y: triangleSize.height),
                alignment: .bottom
            )
            .shadow(color: customBlack.opacity(0.3), radius: 4 * fontScale, x: 0, y: 2 * fontScale)
        }
        .onAppear {
            // Load comments for this post
            commentService.loadComments(for: post.id)
            // Initialize like data for this post
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



// Triangle shape for post pin speech bubble tail
struct PostPinTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}