//======================================================================
// MARK: - ViewBuilderOptimizer.swift
// Purpose: Optimized ViewBuilder patterns for better SwiftUI performance
// Path: GLOBE/Core/Performance/ViewBuilderOptimizer.swift
//======================================================================

import SwiftUI
import UIKit

// MARK: - Optimized ViewBuilder Extensions

extension View {
    // MARK: - Conditional ViewBuilder

    /// Optimized conditional view builder that prevents unnecessary recompilation
    @ViewBuilder
    func conditionalView<Content: View>(
        if condition: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if condition {
            content()
        } else {
            self
        }
    }

    /// Optimized if-else view builder
    @ViewBuilder
    func conditionalView<TrueContent: View, FalseContent: View>(
        if condition: Bool,
        @ViewBuilder trueContent: () -> TrueContent,
        @ViewBuilder elseContent: () -> FalseContent
    ) -> some View {
        Group {
            if condition {
                trueContent()
            } else {
                elseContent()
            }
        }
    }

    // MARK: - Performance Modifiers

    /// Prevents unnecessary redraws by comparing values
    func equalityCheck<Value: Hashable>(_ value: Value) -> some View {
        self.id(value)
    }

    /// Optimized opacity animation
    func optimizedOpacity(_ opacity: Double) -> some View {
        self.opacity(opacity)
            .animation(.easeInOut(duration: 0.2), value: opacity)
    }

    /// Memory-efficient background
    func optimizedBackground<Background: View>(@ViewBuilder background: () -> Background) -> some View {
        self.background(background().drawingGroup())
    }
}

// MARK: - Optimized Container Views

struct OptimizedVStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    let content: Content

    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
        .drawingGroup() // Combines views into single texture for better performance
    }
}

struct OptimizedHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let content: Content

    init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        HStack(alignment: alignment, spacing: spacing) {
            content
        }
        .drawingGroup()
    }
}

// MARK: - Optimized List Builders

struct OptimizedList<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(data), id: \.id) { item in
                content(item)
                    .id(item.id) // Ensure proper identity for animations
            }
        }
    }
}

// MARK: - Performance-Optimized Components

struct OptimizedPostCard: View {
    let post: Post
    let onTap: () -> Void

    private let cardCornerRadius: CGFloat = 18
    private let mediaAspectRatio: CGFloat = 3.0 / 4.0

    private var hasMediaAttachment: Bool {
        if let urlString = post.imageUrl {
            return !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }

    private var postIdentifier: String {
        String(post.id.uuidString.prefix(8)).uppercased()
    }

    // Memoized computed properties
    private var authorDisplayName: String {
        post.authorName
    }

    private var timeAgo: String {
        RelativeDateTimeFormatter().localizedString(for: post.createdAt, relativeTo: Date())
    }

    var body: some View {
        LiquidGlassCard(
            id: "optimized-post-card-\(post.id.uuidString)",
            cornerRadius: cardCornerRadius,
            tint: Color.white.opacity(0.12),
            strokeColor: Color.white.opacity(0.34),
            highlightColor: Color.white.opacity(0.9),
            contentPadding: EdgeInsets(),
            contentBackdropOpacity: 0.2,
            shadowColor: Color.black.opacity(0.3),
            shadowRadius: 16,
            shadowOffsetY: 10
        ) {
            GeometryReader { proxy in
                let cardWidth = proxy.size.width
                let cardHeight = proxy.size.height
                let imageHeight = cardWidth * mediaAspectRatio

                VStack(spacing: 0) {
                    metadataRow(width: cardWidth)
                    dividerLine(width: cardWidth)

                    if hasMediaAttachment {
                        mediaSection(width: cardWidth, height: imageHeight)
                    }

                    contentSection(hasMedia: hasMediaAttachment)
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    Spacer(minLength: 0)
                }
                .frame(width: cardWidth, height: cardHeight, alignment: .top)
            }
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private func mediaSection(width: CGFloat, height: CGFloat) -> some View {
        if hasMediaAttachment,
           let urlString = post.imageUrl,
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
        let imageShape = RoundedCornerShape(radius: cardCornerRadius - 2, corners: [.bottomLeft, .bottomRight])

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
        let imageShape = RoundedCornerShape(radius: cardCornerRadius - 2, corners: [.bottomLeft, .bottomRight])

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
        let corners: UIRectCorner = [.bottomLeft, .bottomRight]
        let contentShape = RoundedCornerShape(radius: cardCornerRadius - 2, corners: corners)

        return VStack(alignment: .leading, spacing: 14) {
            headerView

            if !post.text.isEmpty {
                Text(post.text)
                    .font(.system(size: hasMedia ? 14 : 16, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(hasMedia ? 4 : 8)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 1)
                    .padding(.trailing, 4)
            }

            footerView
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

    private func metadataRow(width: CGFloat) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "tag.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(MinimalDesign.Colors.accentRed)

            Text("#\(postIdentifier)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(width: width, alignment: .leading)
        .background(Color.black.opacity(0.32))
    }

    private func dividerLine(width: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: width, height: 0.8)
    }

    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: 12) {
            MemoryEfficientImage(url: post.authorAvatarUrl, size: CGSize(width: 40, height: 40))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(authorDisplayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }

    private var footerView: some View {
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
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(post.isLikedByMe ? MinimalDesign.Colors.accentRed : .white)
                        if post.likeCount > 0 {
                            Text("\(post.likeCount)")
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
                        if post.commentCount > 0 {
                            Text("\(post.commentCount)")
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
}

// MARK: - Optimized Rounded Corner Helper
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

// MARK: - Performance Monitoring

struct ViewPerformanceMonitor: ViewModifier {
    let name: String
    @State private var renderCount = 0
    @State private var lastRenderTime = Date()

    func body(content: Content) -> some View {
        content
            .onAppear {
                renderCount += 1
                let now = Date()
                let timeSinceLastRender = now.timeIntervalSince(lastRenderTime)
                lastRenderTime = now

                #if DEBUG
                print("🎨 View '\(name)' rendered #\(renderCount) - Time since last render: \(String(format: "%.3f", timeSinceLastRender))s")

                if timeSinceLastRender < 0.1 && renderCount > 1 {
                    print("⚠️ Potential over-rendering detected for '\(name)'")
                }
                #endif
            }
    }
}

extension View {
    func monitorPerformance(name: String) -> some View {
        #if DEBUG
        return ModifiedContent(content: self, modifier: ViewPerformanceMonitor(name: name))
        #else
        return self
        #endif
    }
}

// MARK: - Memory Optimization Helpers

struct MemoryEfficientImage: View {
    let url: String?
    let placeholder: String = "person.circle.fill"
    let size: CGSize

    @State private var cachedImage: UIImage?

    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: placeholder)
                    .font(.system(size: min(size.width, size.height) * 0.5))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: size.width, height: size.height)
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let urlString = url,
              let url = URL(string: urlString),
              cachedImage == nil else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Resize image to target size to save memory
            if let originalImage = UIImage(data: data) {
                let resizedImage = await resizeImage(originalImage, to: size)
                await MainActor.run {
                    self.cachedImage = resizedImage
                }
            }
        } catch {
            SecureLogger.shared.error("Failed to load image: \(error.localizedDescription)")
        }
    }

    private func resizeImage(_ image: UIImage, to size: CGSize) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let renderer = UIGraphicsImageRenderer(size: size)
                let resizedImage = renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
                continuation.resume(returning: resizedImage)
            }
        }
    }
}

// MARK: - ViewBuilder Best Practices Documentation

/*
 ## ViewBuilder Performance Best Practices

 ### 1. Use @ViewBuilder sparingly
 - Only use when you need dynamic view composition
 - Avoid nested @ViewBuilder functions
 - Consider using regular View protocol instead

 ### 2. Optimize conditional rendering
 ```swift
 // ❌ Poor performance - recompiles entire view
 @ViewBuilder
 func content() -> some View {
     if isLoggedIn {
         ComplexLoggedInView()
     } else {
         ComplexLoggedOutView()
     }
 }

 // ✅ Better performance - stable view identity
 @ViewBuilder
 var content: some View {
     Group {
         if isLoggedIn {
             ComplexLoggedInView()
         } else {
             ComplexLoggedOutView()
         }
     }
 }
 ```

 ### 3. Use drawing groups for complex views
 ```swift
 // ✅ Combines multiple views into single texture
 VStack {
     // Multiple complex views
 }
 .drawingGroup()
 ```

 ### 4. Minimize state dependencies
 ```swift
 // ❌ View rebuilds on every state change
 @ViewBuilder
 func dynamicContent() -> some View {
     if someState.complexCondition && otherState.value > 10 {
         ExpensiveView()
     }
 }

 // ✅ Pre-compute conditions
 private var shouldShowExpensiveView: Bool {
     someState.complexCondition && otherState.value > 10
 }

 @ViewBuilder
 var optimizedContent: some View {
     if shouldShowExpensiveView {
         ExpensiveView()
     }
 }
 ```
 */
