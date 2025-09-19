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
    private let mediaAspectRatio: CGFloat = 3.0 / 4.0

    private var hasMediaAttachment: Bool {
        post.imageData != nil || post.imageUrl != nil
    }

    var body: some View {
        let glassId = "post-card-\(post.id.uuidString)"

        LiquidGlassCard(
            id: glassId,
            cornerRadius: cardCornerRadius,
            tint: Color.white.opacity(0.12),
            strokeColor: Color.white.opacity(0.34),
            highlightColor: Color.white.opacity(0.9),
            contentPadding: EdgeInsets(),
            contentBackdropOpacity: 0.2,
            shadowColor: Color.black.opacity(0.35),
            shadowRadius: 18,
            shadowOffsetY: 12
        ) {
            GeometryReader { proxy in
                let cardWidth = proxy.size.width
                let imageHeight = cardWidth * mediaAspectRatio

                VStack(spacing: 0) {
                    mediaSection(width: cardWidth, height: imageHeight)

                    contentSection(hasMedia: hasMediaAttachment)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .sheet(isPresented: $showingUserProfile) {
            Text("User Profile: \(post.authorName)")
        }
    }

    @ViewBuilder
    private func mediaSection(width: CGFloat, height: CGFloat) -> some View {
        if let imageData = post.imageData,
           let uiImage = UIImage(data: imageData)?.fixOrientation() {
            mediaImageView(Image(uiImage: uiImage), width: width, height: height)
        } else if let urlString = post.imageUrl,
                  let url = URL(string: urlString) {
            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                switch phase {
                case .success(let image):
                    mediaImageView(image, width: width, height: height)
                case .failure:
                    mediaPlaceholder(width: width, height: height)
                case .empty:
                    mediaPlaceholder(width: width, height: height, showProgress: true)
                @unknown default:
                    mediaPlaceholder(width: width, height: height)
                }
            }
        } else {
            EmptyView()
        }
    }

    private func mediaImageView(_ image: Image, width: CGFloat, height: CGFloat) -> some View {
        let imageShape = RoundedCornerShape(radius: cardCornerRadius - 2, corners: [.topLeft, .topRight])

        return image
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(0.45)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: height * 0.6),
                alignment: .bottom
            )
            .clipShape(imageShape)
            .clipped()
            .accessibilityHidden(true)
    }

    private func mediaPlaceholder(width: CGFloat, height: CGFloat, showProgress: Bool = false) -> some View {
        let imageShape = RoundedCornerShape(radius: cardCornerRadius - 2, corners: [.topLeft, .topRight])

        return ZStack {
            LinearGradient(
                colors: [
                    MinimalDesign.Colors.secondary.opacity(0.25),
                    MinimalDesign.Colors.secondary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if showProgress {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
        .frame(width: width, height: height)
        .clipShape(imageShape)
        .accessibilityHidden(true)
    }

    private func contentSection(hasMedia: Bool) -> some View {
        let corners: UIRectCorner = hasMedia ? [.bottomLeft, .bottomRight] : [.allCorners]
        let contentShape = RoundedCornerShape(radius: cardCornerRadius - 2, corners: corners)

        return VStack(alignment: .leading, spacing: 14) {
            headerCompact

            if !post.text.isEmpty {
                Text(post.text)
                    .font(.system(size: hasMedia ? 14 : 16, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(hasMedia ? 4 : 8)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 1)
                    .padding(.trailing, 4)
            }

            interactionRowCompact
        }
        .padding(.horizontal, 18)
        .padding(.top, hasMedia ? 16 : 22)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(contentBackdrop(hasMedia: hasMedia, shape: contentShape))
        .clipShape(contentShape)
    }

    private func contentBackdrop(hasMedia: Bool, shape: RoundedCornerShape) -> some View {
        Group {
            if hasMedia {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(shape.fill(Color.black.opacity(0.42)))
                    .overlay(shape.stroke(Color.white.opacity(0.06), lineWidth: 0.6))
                    .compositingGroup()
                    .blur(radius: 14)
            } else {
                shape
                    .fill(Color.black.opacity(0.22))
                    .overlay(shape.stroke(Color.white.opacity(0.06), lineWidth: 0.5))
            }
        }
    }

    private var headerCompact: some View {
        HStack(spacing: 12) {
            Button(action: {
                showingUserProfile = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                    if let avatarUrl = post.authorAvatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Text(String(post.authorName.prefix(1)).uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .clipShape(Circle())
                    } else {
                        Text(String(post.authorName.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(timeAgoText(from: post.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }

    private var interactionRowCompact: some View {
        HStack(spacing: 16) {
            if let locationName = post.locationName {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                    Text(locationName)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 18) {
                Button(action: handleLikeTap) {
                    HStack(spacing: 6) {
                        Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(likeService.isLiked(post.id) ? MinimalDesign.Colors.accentRed : .white)

                        let likeCount = likeService.getLikeCount(for: post.id)
                        if likeCount > 0 {
                            Text("\(likeCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 18))
                            .foregroundColor(.white)

                        let commentCount = commentService.getCommentCount(for: post.id)
                        if commentCount > 0 {
                            Text("\(commentCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Image(systemName: "map")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleLikeTap() {
        guard let userId = authManager.currentUser?.id else { return }
        let newState = likeService.toggleLike(for: post, userId: userId)
        if newState {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
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

// MARK: - Rounded Corner Helper
private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
