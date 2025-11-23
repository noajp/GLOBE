//======================================================================
// MARK: - PostCard.swift
// Function: Post Card Component
// Overview: Reusable card for displaying posts with media, likes, and comments
// Processing: Render card layout → Display media/text → Show metadata → Handle interactions
//======================================================================

import SwiftUI
import MapKit
import UIKit

//###########################################################################
// MARK: - Post Card View
// Function: PostCard
// Overview: Glass-effect card component for post display with full interaction support
// Processing: Calculate layout → Render media → Display metadata → Handle like/comment actions
//###########################################################################

struct PostCard: View {
    let post: Post
    @EnvironmentObject var likeService: LikeService
    @EnvironmentObject var commentService: CommentService
    @EnvironmentObject var authManager: AuthManager
    @State private var showingUserProfile = false
    @State private var showingComments = false

    private let cardCornerRadius: CGFloat = 18
    private let mediaAspectRatio: CGFloat = 4.0 / 5.0

    //###########################################################################
    // MARK: - Computed Properties
    // Function: Content checks and identifiers
    // Overview: Calculate post metadata and media presence
    // Processing: Check media existence → Generate post identifier
    //###########################################################################

    private var hasMediaAttachment: Bool {
        post.imageData != nil || post.imageUrl != nil
    }

    private var postIdentifier: String {
        String(post.id.uuidString.prefix(8)).uppercased()
    }

    //###########################################################################
    // MARK: - UI Components
    // Function: speechBubbleTail
    // Overview: Decorative triangle tail for speech bubble effect
    // Processing: Create triangle → Apply glass effect → Rotate and position
    //###########################################################################

    private var speechBubbleTail: some View {
        Triangle()
            .fill(Color.clear)
            .frame(width: 20, height: 15)
            .glassEffect(.clear, in: Triangle())
            .rotationEffect(.degrees(180))
            .offset(y: 15)
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
                let cardHeight = proxy.size.height
                let imageHeight = cardWidth * mediaAspectRatio

                VStack(spacing: 0) {
                    if hasMediaAttachment {
                        mediaSection(width: cardWidth, height: imageHeight)
                    }

                    metadataRow(width: cardWidth)
                    dividerLine(width: cardWidth)

                    contentSection(hasMedia: hasMediaAttachment)
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    Spacer(minLength: 0)
                }
                .frame(width: cardWidth, height: cardHeight, alignment: .top)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
        .overlay(
            speechBubbleTail
                .allowsHitTesting(false),
            alignment: .bottom
        )
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .sheet(isPresented: $showingUserProfile) {
            Text("User Profile: \(post.authorName)")
        }
        .sheet(isPresented: $showingComments) {
            CommentView(post: post)
        }
    }

    //###########################################################################
    // MARK: - Media Section
    // Function: mediaSection
    // Overview: Display post media (image or async loaded URL)
    // Processing: Check imageData → Fallback to imageUrl → Display AsyncImage → Show placeholder on error
    //###########################################################################

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

    //###########################################################################
    // MARK: - Media Image Display
    // Function: mediaImageView
    // Overview: Render post image with rounded top corners and gradient overlay
    // Processing: Create shape → Apply image scaling → Add gradient overlay → Clip to shape
    //###########################################################################

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

    //###########################################################################
    // MARK: - Media Placeholder
    // Function: mediaPlaceholder
    // Overview: Display placeholder for loading or failed images
    // Processing: Create gradient background → Show progress/icon based on state → Clip to shape
    //###########################################################################

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

    //###########################################################################
    // MARK: - Content Section
    // Function: contentSection
    // Overview: Display post text and interaction buttons
    // Processing: Render text with dynamic sizing → Add interaction row → Apply glass backdrop
    //###########################################################################

    private func contentSection(hasMedia: Bool) -> some View {
        let contentShape = RoundedCornerShape(radius: cardCornerRadius - 2, corners: [.bottomLeft, .bottomRight])

        return VStack(alignment: .leading, spacing: 14) {
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

    //###########################################################################
    // MARK: - Content Backdrop
    // Function: contentBackdrop
    // Overview: Generate glass effect background for content area
    // Processing: Check hasMedia → Apply ultra-thin material OR black overlay → Add stroke
    //###########################################################################

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

    //###########################################################################
    // MARK: - Metadata Row
    // Function: metadataRow
    // Overview: Display post metadata (avatar, identifier, timestamp)
    // Processing: Render avatar → Show post ID → Display time ago → Style with black background
    //###########################################################################

    private func metadataRow(width: CGFloat) -> some View {
        HStack(spacing: 12) {
            avatarBadge(size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("#\(postIdentifier)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(timeAgoText(from: post.createdAt))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(width: width, alignment: .leading)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.32))
        )
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
        )
    }

    //###########################################################################
    // MARK: - Divider Line
    // Function: dividerLine
    // Overview: Horizontal separator line between sections
    // Processing: Create rectangle → Fill with semi-transparent white → Set to thin height
    //###########################################################################

    private func dividerLine(width: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
        .frame(width: width, height: 0.8)
    }

    //###########################################################################
    // MARK: - Interaction Row
    // Function: interactionRowCompact
    // Overview: Display like, comment, and map buttons with counts
    // Processing: Show location if available → Render like button with count → Show comment button → Add map button
    //###########################################################################

    private var interactionRowCompact: some View {
        HStack(spacing: 16) {
            if let locationName = post.locationName {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(MinimalDesign.Colors.accentRed.opacity(0.5))
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

                Button(action: {
                    showingComments = true
                }) {
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
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    //###########################################################################
    // MARK: - Avatar Badge
    // Function: avatarBadge
    // Overview: Circular avatar button with async image loading
    // Processing: Create circle background → Load avatar URL → Fallback to initials → Handle tap for profile view
    //###########################################################################

    private func avatarBadge(size: CGFloat) -> some View {
        Button(action: {
            showingUserProfile = true
        }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))

                if let avatarUrl = post.authorAvatarUrl,
                   let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Text(String(post.authorName.prefix(1)).uppercased())
                                .font(.system(size: size * 0.45, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .clipShape(Circle())
                } else {
                    Text(String(post.authorName.prefix(1)).uppercased())
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }

    //###########################################################################
    // MARK: - Like Action Handler
    // Function: handleLikeTap
    // Overview: Toggle like state and provide haptic feedback
    // Processing: Get current user → Toggle like in service → Trigger haptic if liked
    //###########################################################################

    private func handleLikeTap() {
        guard let userId = authManager.currentUser?.id else { return }
        let newState = likeService.toggleLike(for: post, userId: userId)
        if newState {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }

    //###########################################################################
    // MARK: - Time Display Helper
    // Function: timeAgoText
    // Overview: Convert timestamp to Japanese relative time string
    // Processing: Calculate time difference → Format as hours/minutes → Show "期限切れ" after 24h
    //###########################################################################

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

//###########################################################################
// MARK: - Rounded Corner Helper
// Function: RoundedCornerShape
// Overview: Custom Shape for selective corner rounding
// Processing: Create UIBezierPath with specified corners → Convert to SwiftUI Path
//###########################################################################

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

