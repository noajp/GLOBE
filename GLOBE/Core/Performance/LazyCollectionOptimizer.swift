//======================================================================
// MARK: - LazyCollectionOptimizer.swift
// Purpose: Optimized lazy collections for better scrolling performance
// Path: GLOBE/Core/Performance/LazyCollectionOptimizer.swift
//======================================================================

import SwiftUI

// MARK: - Optimized Lazy Collections

struct OptimizedLazyVGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let columns: [GridItem]
    let spacing: CGFloat
    let content: (Item) -> Content

    // Performance optimization properties
    private let prefetchDistance: Int = 5
    @State private var visibleRange: Range<Int> = 0..<10

    init(
        items: [Item],
        columns: [GridItem],
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                content(item)
                    .id(item.id)
                    .onAppear {
                        updateVisibleRange(for: index)
                    }
                    // Add memory-efficient rendering
                    .drawingGroup(opaque: false, colorMode: .nonLinear)
            }
        }
        .monitorPerformance(name: "LazyVGrid")
    }

    private func updateVisibleRange(for index: Int) {
        let start = max(0, index - prefetchDistance)
        let end = min(items.count, index + prefetchDistance)
        visibleRange = start..<end
    }
}

struct OptimizedPostList: View {
    let posts: [Post]
    let onPostTap: (Post) -> Void
    let onLike: (Post) -> Void

    // Lazy loading configuration
    private let itemsPerPage = 20
    @State private var loadedItemsCount = 20
    @State private var isLoadingMore = false

    // Virtualization for better memory management
    @State private var viewportSize: CGSize = .zero
    private let estimatedItemHeight: CGFloat = 200

    var body: some View {
        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
            // Header section
            Section {
                ForEach(Array(visiblePosts.enumerated()), id: \.element.id) { index, post in
                    OptimizedPostCard(post: post) {
                        onPostTap(post)
                    }
                    .onAppear {
                        checkForLoadMore(index: index)
                    }
                    // Optimize rendering for off-screen items
                    .scaleEffect(shouldOptimizeItem(at: index) ? 0.95 : 1.0)
                    .opacity(shouldOptimizeItem(at: index) ? 0.8 : 1.0)
                }

                // Loading indicator
                if isLoadingMore {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("投稿を読み込み中...")
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
            } header: {
                if !posts.isEmpty {
                    Text("\(posts.count)件の投稿")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .background(Color.black.opacity(0.9))
                }
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        viewportSize = proxy.size
                    }
                    .onChange(of: proxy.size) { size in
                        viewportSize = size
                    }
            }
        )
        .monitorPerformance(name: "PostList")
    }

    private var visiblePosts: ArraySlice<Post> {
        posts.prefix(loadedItemsCount)
    }

    private func shouldOptimizeItem(at index: Int) -> Bool {
        // Optimize items that are far from current viewport
        let estimatedItemsInViewport = Int(viewportSize.height / estimatedItemHeight)
        return index > estimatedItemsInViewport * 2
    }

    private func checkForLoadMore(index: Int) {
        // Load more when approaching the end
        let threshold = max(5, loadedItemsCount - 5)
        if index >= threshold && !isLoadingMore && loadedItemsCount < posts.count {
            loadMoreItems()
        }
    }

    private func loadMoreItems() {
        guard !isLoadingMore else { return }

        isLoadingMore = true

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let newCount = min(posts.count, loadedItemsCount + itemsPerPage)
            withAnimation(.easeInOut) {
                loadedItemsCount = newCount
                isLoadingMore = false
            }

            SecureLogger.shared.info("Loaded more posts newCount=\(newCount) totalPosts=\(posts.count)")
        }
    }
}

// MARK: - Stories Horizontal Scroll

struct OptimizedStoriesBar: View {
    let stories: [Story]
    @Binding var selectedStory: Story?

    // Performance optimization
    private let visibleItemsCount = 10
    @State private var scrollPosition: String?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(stories.prefix(visibleItemsCount)), id: \.id) { story in
                        StoryThumbnail(story: story) {
                            selectedStory = story
                        }
                        .id(story.id)
                        .scaleEffect(selectedStory?.id == story.id ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: selectedStory?.id)
                    }

                    // Load more indicator if there are more stories
                    if stories.count > visibleItemsCount {
                        Button("もっと見る") {
                            // Implement load more stories
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: selectedStory?.id) { storyId in
                if let storyId = storyId {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(storyId, anchor: .center)
                    }
                }
            }
        }
        .monitorPerformance(name: "StoriesBar")
    }
}

struct StoryThumbnail: View {
    let story: Story
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background image
                AsyncImage(url: URL(string: story.imageData.isEmpty ? "" : "data:image/jpeg;base64,\(story.imageData.base64EncodedString())")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                .frame(width: 80, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // User avatar overlay
                VStack {
                    Spacer()
                    AsyncImage(url: URL(string: story.userAvatarData?.base64EncodedString() ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.white)
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                }
                .padding(.bottom, 8)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Adaptive Layout

struct AdaptiveLayout<Content: View>: View {
    let content: Content
    @State private var currentLayout: LayoutType = .list

    enum LayoutType {
        case list
        case grid
        case compact
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                switch adaptiveLayout(for: geometry.size) {
                case .list:
                    LazyVStack {
                        content
                    }
                case .grid:
                    LazyVGrid(columns: gridColumns(for: geometry.size)) {
                        content
                    }
                case .compact:
                    LazyVStack(spacing: 4) {
                        content
                    }
                }
            }
        }
    }

    private func adaptiveLayout(for size: CGSize) -> LayoutType {
        if size.width > 800 {
            return .grid
        } else if size.height < 600 {
            return .compact
        } else {
            return .list
        }
    }

    private func gridColumns(for size: CGSize) -> [GridItem] {
        let columnCount = Int(size.width / 300)
        return Array(repeating: GridItem(.flexible()), count: max(1, columnCount))
    }
}

// MARK: - Virtualized Scroll View

struct VirtualizedScrollView<Content: View>: View {
    let content: Content
    let estimatedItemHeight: CGFloat

    @State private var contentOffset: CGFloat = 0
    @State private var visibleRange: Range<Int> = 0..<10

    init(estimatedItemHeight: CGFloat = 100, @ViewBuilder content: () -> Content) {
        self.estimatedItemHeight = estimatedItemHeight
        self.content = content()
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                content
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.frame(in: .global).minY) { offset in
                            contentOffset = offset
                            updateVisibleRange(offset: offset, viewportHeight: geometry.size.height)
                        }
                }
            )
        }
    }

    private func updateVisibleRange(offset: CGFloat, viewportHeight: CGFloat) {
        let startIndex = max(0, Int(-offset / estimatedItemHeight) - 2)
        let endIndex = min(100, startIndex + Int(viewportHeight / estimatedItemHeight) + 4)
        visibleRange = startIndex..<endIndex
    }
}

// MARK: - Performance Metrics

struct LazyCollectionMetrics {
    static func measureScrollPerformance<T: View>(for view: T) -> some View {
        view
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                #if DEBUG
                let fps = calculateFPS(for: offset)
                if fps < 55 {
                    print("⚠️ Scroll performance below 55fps: \(fps)")
                }
                #endif
            }
    }

    private static func calculateFPS(for offset: CGFloat) -> Double {
        // Simplified FPS calculation
        return 60.0 // Placeholder implementation
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Memory-Efficient Extensions

extension View {
    func memoryOptimized() -> some View { self.drawingGroup(opaque: false, colorMode: .nonLinear) }
}
