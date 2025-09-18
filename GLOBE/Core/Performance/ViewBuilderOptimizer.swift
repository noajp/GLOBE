//======================================================================
// MARK: - ViewBuilderOptimizer.swift
// Purpose: Optimized ViewBuilder patterns for better SwiftUI performance
// Path: GLOBE/Core/Performance/ViewBuilderOptimizer.swift
//======================================================================

import SwiftUI

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
    private let imageHeight: CGFloat = 220

    // Memoized computed properties
    private var authorDisplayName: String {
        post.authorName
    }

    private var timeAgo: String {
        RelativeDateTimeFormatter().localizedString(for: post.createdAt, relativeTo: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if let imageUrl = post.imageUrl {
                    imageView(url: imageUrl)
                }

                VStack(alignment: .leading, spacing: 12) {
                    headerView

                    if !post.text.isEmpty {
                        Text(post.text)
                            .font(.system(size: post.imageUrl == nil ? 16 : 13))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    footerView
                }
                .padding(.horizontal, 16)
                .padding(.top, post.imageUrl == nil ? 16 : 12)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .aspectRatio(1.0 / 3.0, contentMode: .fit)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var headerView: some View {
        OptimizedHStack {
            AsyncImage(url: URL(string: post.authorAvatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(authorDisplayName)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func imageView(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: imageHeight)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(maxWidth: .infinity)
                .frame(height: imageHeight)
                .overlay {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
        }
    }

    @ViewBuilder
    private var footerView: some View {
        HStack(alignment: .center) {
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

            HStack(spacing: 20) {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(post.isLikedByMe ? .red : .white)
                        if post.likeCount > 0 {
                            Text("\(post.likeCount)")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        if post.commentCount > 0 {
                            Text("\(post.commentCount)")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {}) {
                    Image(systemName: "map")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
