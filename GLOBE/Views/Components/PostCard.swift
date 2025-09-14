//======================================================================
// MARK: - PostCard.swift
// Purpose: Reusable post card component for displaying posts
// Path: GLOBE/Views/Components/PostCard.swift
//======================================================================

import SwiftUI
import MapKit

struct PostCard: View {
    let post: Post
    @StateObject private var likeService = LikeService.shared
    @StateObject private var commentService = CommentService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingDetailedView = false
    @State private var showingUserProfile = false
    
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width
            // Increase height further to ensure action buttons never clip
            let heightRatio: CGFloat = 1.45 // was: 1.4 (4/3 ≈ 1.333)
            let cardHeight = cardWidth * heightRatio
            
            // Card content with a small bottom inset so controls avoid the rounded mask
            VStack(spacing: 0) {
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
                                    showingDetailedView = true
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
                    .frame(maxHeight: .infinity) // Fill remaining space in 3:4 card
                    
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
                        
                        Spacer()
                        
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
                                    showingDetailedView = true
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
                    .padding(16)
                    .frame(height: cardHeight)
                }
            }
            // Add inner bottom padding to keep like/comment above the rounded corner clip
            .padding(.bottom, 12)
            .frame(width: cardWidth, height: cardHeight)
        }
        // Match the new height ratio so the card lays out correctly
        .aspectRatio(1/1.45, contentMode: .fit)
        .background(customBlack)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onTapGesture {
            showingDetailedView = true
        }
        .sheet(isPresented: $showingDetailedView) {
            DetailedPostView(post: post, isPresented: $showingDetailedView)
        }
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
}
