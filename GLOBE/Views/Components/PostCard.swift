//======================================================================
// MARK: - PostCard.swift
// Purpose: Reusable post card component for displaying posts
// Path: GLOBE/Views/Components/PostCard.swift
//======================================================================

import SwiftUI
import MapKit
import UIKit

struct PostCard: View {
    let post: Post
    @StateObject private var likeService = LikeService.shared
    @StateObject private var commentService = CommentService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingUserProfile = false
    
    private let cardCornerRadius: CGFloat = 18

    var body: some View {
        let glassId = "post-card-\(post.id.uuidString)"

        GlassEffectContainer {
            GeometryReader { geometry in
                let cardWidth = geometry.size.width
                // Increase height further to ensure action buttons never clip
                let heightRatio: CGFloat = 3.0 // was: 1.6
                let baseCardHeight = cardWidth * heightRatio
                let isTextOnlyPost = post.imageData == nil
                let primaryTextFont = UIFont.systemFont(ofSize: 16)
                let hasBodyText = !post.text.isEmpty
                let textLineCount = isTextOnlyPost
                    ? lineCountForText(
                        post.text,
                        font: primaryTextFont,
                        availableWidth: cardWidth - 32 // 16pt padding on each side
                    )
                    : 0
                let resolvedCardHeight = isTextOnlyPost
                    ? max(
                        textCardHeight(
                            lineCount: textLineCount,
                            font: primaryTextFont,
                            hasText: hasBodyText
                        ),
                        baseCardHeight
                    )
                    : baseCardHeight
                
                // Card content with a small bottom inset so controls avoid the rounded mask
                VStack(alignment: .leading, spacing: 0) {
                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                    // Photo layout: Full-width square image at top, content below
                    
                    // Square image - full card width with no horizontal padding
                    Image(uiImage: uiImage.fixOrientation())
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: cardWidth) // Perfect square, full width
                        .clipped()
                        .padding(.top, 0) // No top padding for maximum size
                    
                    // Content area - fills remaining space after square image
                    VStack(alignment: .leading, spacing: 6) {
                        // Post Header
                        HStack(spacing: 8) {
                            // Profile icon - tappable
                            Button(action: {
                                showingUserProfile = true
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Text(post.authorName.prefix(1).uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(post.authorName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text(timeAgoText(from: post.createdAt))
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        // Post text (compact)
                        if !post.text.isEmpty {
                            Text(post.text)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .padding(.horizontal, 16)
                        }
                        
                        // Bottom row: Location and Action buttons
                        HStack {
                            // Location info
                            if let locationName = post.locationName {
                                HStack(spacing: 3) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Text(locationName)
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            // Action buttons
                            HStack(spacing: 12) {
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
                                    HStack(spacing: 3) {
                                        Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                                            .font(.system(size: 14))
                                            .foregroundColor(likeService.isLiked(post.id) ? .red : .white)
                                        
                                        let likeCount = likeService.getLikeCount(for: post.id)
                                        if likeCount > 0 {
                                            Text("\(likeCount)")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Comment button
                                Button(action: {
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "bubble.left")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                        
                                        let commentCount = commentService.getCommentCount(for: post.id)
                                        if commentCount > 0 {
                                            Text("\(commentCount)")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Map icon
                                Button(action: {
                                }) {
                                    Image(systemName: "map")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                } else {
                    // Text-only layout: 3:4 vertical layout with larger text area
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Post Header
                        HStack(spacing: 12) {
                            // Profile icon - tappable
                            Button(action: {
                                showingUserProfile = true
                            }) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(post.authorName.prefix(1).uppercased())
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(post.authorName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text(timeAgoText(from: post.createdAt))
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        
                        // Post text (larger area for text-only posts)
                        if !post.text.isEmpty {
                            Text(post.text)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .lineLimit(8)
                        }
                        
                        // Bottom row: Location and Action buttons
                        HStack {
                            // Location info
                            if let locationName = post.locationName {
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Text(locationName)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            // Action buttons
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
                                    HStack(spacing: 6) {
                                        Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                                            .font(.system(size: 18))
                                            .foregroundColor(likeService.isLiked(post.id) ? .red : .white)
                                        
                                        let likeCount = likeService.getLikeCount(for: post.id)
                                        if likeCount > 0 {
                                            Text("\(likeCount)")
                                                .font(.system(size: 15))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Comment button
                                Button(action: {
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "bubble.left")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                        
                                        let commentCount = commentService.getCommentCount(for: post.id)
                                        if commentCount > 0 {
                                            Text("\(commentCount)")
                                                .font(.system(size: 15))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Map icon
                                Button(action: {
                                }) {
                                    Image(systemName: "map")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(16)
                    .frame(height: resolvedCardHeight, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            // Add inner bottom padding to keep like/comment above the rounded corner clip
            .padding(.bottom, 12)
            .frame(
                width: cardWidth,
                height: isTextOnlyPost ? resolvedCardHeight : baseCardHeight,
                alignment: .top
            )
                .coordinatedGlassEffect(id: glassId, cornerRadius: cardCornerRadius)
                .background(
                    RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 0.65)
                        .blendMode(.screen)
                        .allowsHitTesting(false)
                )
                .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
            }
        }
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .sheet(isPresented: $showingUserProfile) {
            Text("User Profile: \(post.authorName)")
        }
    }
    
    private func timeAgoText(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: date, to: now)
        
        if let hours = components.hour, hours > 0 {
            if hours >= 24 {
                return "期限切れ"
            }
            return "\(hours)時間前"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)分前"
        } else {
            return "たった今"
        }
    }

    /// 指定した幅とフォントでテキストが占める行数を推定する
    private func lineCountForText(_ text: String, font: UIFont, availableWidth: CGFloat) -> Int {
        guard !text.isEmpty else { return 0 }

        let constraintRect = CGSize(width: availableWidth, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )

        return max(1, Int(ceil(boundingBox.height / font.lineHeight)))
    }

    /// テキスト投稿全体の高さを、本文の行数に合わせて算出する
    private func textCardHeight(lineCount: Int, font: UIFont, hasText: Bool) -> CGFloat {
        let topBottomPadding: CGFloat = 32 // VStack padding(.vertical, 16)
        let headerHeight: CGFloat = 40
        let spacingAboveText: CGFloat = hasText ? 12 : 0
        let textHeight = hasText ? CGFloat(max(lineCount, 1)) * font.lineHeight : 0
        let spacingBelowText: CGFloat = hasText ? 12 : 0
        let actionRowHeight: CGFloat = 32
        let bottomSafePadding: CGFloat = 12 // outer padding(.bottom, 12)

        return topBottomPadding
            + headerHeight
            + spacingAboveText
            + textHeight
            + spacingBelowText
            + actionRowHeight
            + bottomSafePadding
    }
}
