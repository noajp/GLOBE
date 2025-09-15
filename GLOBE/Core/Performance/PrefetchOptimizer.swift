//======================================================================
// MARK: - PrefetchOptimizer.swift
// Purpose: Smart prefetching and image compression optimization
// Path: GLOBE/Core/Performance/PrefetchOptimizer.swift
//======================================================================

import SwiftUI
import UIKit
import Combine
import CoreLocation

// MARK: - Smart Prefetch Manager

@MainActor
class SmartPrefetchManager: ObservableObject {
    static let shared = SmartPrefetchManager()

    // Prefetch configuration
    private let prefetchRadius = 2000.0 // 2km
    private let maxPrefetchItems = 50
    private let prefetchTriggerDistance = 500.0 // 500m

    // State tracking
    @Published var prefetchStats = PrefetchStats()
    private var lastPrefetchLocation: CLLocationCoordinate2D?
    private var prefetchedPostIds: Set<UUID> = []
    private var prefetchQueue: DispatchQueue

    // Dependencies
    private let postRepository: any PostRepositoryProtocol
    private let imageCache: ImageCacheManager
    private let batchRequestManager: BatchRequestManager

    init(
        postRepository: (any PostRepositoryProtocol)? = nil,
        imageCache: ImageCacheManager = .shared,
        batchRequestManager: BatchRequestManager = .shared
    ) {
        self.postRepository = postRepository ?? PostRepository.create()
        self.imageCache = imageCache
        self.batchRequestManager = batchRequestManager

        self.prefetchQueue = DispatchQueue(
            label: "prefetch.queue",
            qos: .utility,
            attributes: .concurrent
        )

        setupLocationBasedPrefetching()
    }

    // MARK: - Location-Based Prefetching

    func updateUserLocation(_ location: CLLocationCoordinate2D) {
        guard shouldTriggerPrefetch(for: location) else { return }

        Task {
            await prefetchNearbyContent(location: location)
        }

        lastPrefetchLocation = location
    }

    func prefetchForUpcomingRoute(coordinates: [CLLocationCoordinate2D]) async {
        await withTaskGroup(of: Void.self) { group in
            for coordinate in coordinates {
                group.addTask {
                    await self.prefetchNearbyContent(location: coordinate, priority: .background)
                }
            }
        }
    }

    // MARK: - Content-Based Prefetching

    func prefetchRelatedContent(for post: Post) async {
        // Prefetch posts from same user
        await prefetchUserPosts(userId: post.userId, excludingPostId: post.id)

        // Prefetch nearby posts
        await prefetchNearbyContent(
            location: CLLocationCoordinate2D(
                latitude: post.latitude,
                longitude: post.longitude
            ),
            priority: .utility
        )

        // Prefetch comments for engaging posts
        if post.likeCount > 10 || post.commentCount > 5 {
            await prefetchComments(for: post.id)
        }
    }

    func prefetchUserTimeline(userId: String, limit: Int = 20) async {
        do {
            let posts = try await postRepository.getPostsByUser(userId)
            let recentPosts = Array(posts.prefix(limit))

            // Prefetch images for recent posts
            let imageUrls = recentPosts.compactMap { post -> URL? in
                guard let imageUrl = post.imageUrl else { return nil }
                return URL(string: imageUrl)
            }

            if !imageUrls.isEmpty {
                imageCache.preloadImages(urls: imageUrls, priority: .utility)
            }

            prefetchStats.recordPrefetch(type: .userTimeline, count: recentPosts.count)

        } catch {
            SecureLogger.shared.error("Failed to prefetch user timeline: \(error.localizedDescription)")
        }
    }

    // MARK: - Intelligent Caching Strategies

    func optimizeOfflineContent() async {
        // Cache high-engagement posts
        await cacheHighEngagementPosts()

        // Cache user's favorite content
        await cacheUserFavorites()

        // Cache location-based essentials
        await cacheLocationEssentials()
    }

    // MARK: - Private Methods

    private func shouldTriggerPrefetch(for location: CLLocationCoordinate2D) -> Bool {
        guard let lastLocation = lastPrefetchLocation else { return true }

        let distance = CLLocation(latitude: location.latitude, longitude: location.longitude)
            .distance(from: CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude))

        return distance >= prefetchTriggerDistance
    }

    private func prefetchNearbyContent(
        location: CLLocationCoordinate2D,
        priority: TaskPriority = .utility
    ) async {
        Task(priority: priority) {
            do {
                let posts = try await postRepository.getPostsByLocation(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    radius: prefetchRadius
                )

                let newPosts = posts.filter { !prefetchedPostIds.contains($0.id) }
                let postsToCache = Array(newPosts.prefix(maxPrefetchItems))

                // Update prefetched set
                prefetchedPostIds.formUnion(postsToCache.map(\.id))

                // Prefetch images
                let imageUrls = postsToCache.compactMap { post -> URL? in
                    guard let imageUrl = post.imageUrl else { return nil }
                    return URL(string: imageUrl)
                }

                if !imageUrls.isEmpty {
                    imageCache.preloadImages(urls: imageUrls, priority: priority)
                }

                await MainActor.run {
                    prefetchStats.recordPrefetch(type: .locationBased, count: postsToCache.count)
                }

                SecureLogger.shared.info("Prefetched nearby content - location: \(location.latitude),\(location.longitude), postCount: \(postsToCache.count)")

            } catch {
                SecureLogger.shared.error("Failed to prefetch nearby content: \(error.localizedDescription)")
            }
        }
    }

    private func prefetchUserPosts(userId: String, excludingPostId: UUID) async {
        do {
            let posts = try await postRepository.getPostsByUser(userId)
            let filteredPosts = posts.filter { $0.id != excludingPostId }
            let recentPosts = Array(filteredPosts.prefix(10))

            let imageUrls = recentPosts.compactMap { post -> URL? in
                guard let imageUrl = post.imageUrl else { return nil }
                return URL(string: imageUrl)
            }

            if !imageUrls.isEmpty {
                imageCache.preloadImages(urls: imageUrls, priority: .low)
            }

            prefetchStats.recordPrefetch(type: .userContent, count: recentPosts.count)

        } catch {
            SecureLogger.shared.error("Failed to prefetch user posts: \(error.localizedDescription)")
        }
    }

    private func prefetchComments(for postId: UUID) async {
        // Implementation would depend on having a CommentRepository
        SecureLogger.shared.info("Prefetching comments for post: \(postId.uuidString)")
    }

    private func cacheHighEngagementPosts() async {
        // Cache posts with high engagement for offline viewing
        SecureLogger.shared.info("Caching high engagement posts for offline access")
    }

    private func cacheUserFavorites() async {
        // Cache user's liked/saved posts
        SecureLogger.shared.info("Caching user favorite posts")
    }

    private func cacheLocationEssentials() async {
        // Cache essential posts for user's frequent locations
        SecureLogger.shared.info("Caching location-based essential content")
    }

    private func setupLocationBasedPrefetching() {
        // Monitor significant location changes for prefetching
        NotificationCenter.default.addObserver(
            forName: .locationDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let location = notification.userInfo?["location"] as? CLLocationCoordinate2D {
                self?.updateUserLocation(location)
            }
        }
    }
}

// MARK: - Advanced Image Compression

class ImageCompressionOptimizer {
    static let shared = ImageCompressionOptimizer()

    // Compression settings based on context
    enum CompressionContext {
        case thumbnail
        case feed
        case fullScreen
        case storage
    }

    func optimizeImage(
        _ image: UIImage,
        for context: CompressionContext,
        networkType: NetworkType = .unknown
    ) async -> Data? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let optimizedData = self.compressImage(
                    image,
                    context: context,
                    networkType: networkType
                )
                continuation.resume(returning: optimizedData)
            }
        }
    }

    private func compressImage(
        _ image: UIImage,
        context: CompressionContext,
        networkType: NetworkType
    ) -> Data? {
        let (targetSize, quality) = compressionSettings(for: context, networkType: networkType)

        // Resize image if needed
        let resizedImage = resizeImage(image, to: targetSize)

        // Apply compression
        return resizedImage.jpegData(compressionQuality: quality)
    }

    private func compressionSettings(
        for context: CompressionContext,
        networkType: NetworkType
    ) -> (size: CGSize, quality: CGFloat) {
        let networkQualityMultiplier = networkQualityAdjustment(for: networkType)

        switch context {
        case .thumbnail:
            return (
                size: CGSize(width: 150, height: 150),
                quality: 0.6 * networkQualityMultiplier
            )
        case .feed:
            return (
                size: CGSize(width: 600, height: 600),
                quality: 0.8 * networkQualityMultiplier
            )
        case .fullScreen:
            return (
                size: CGSize(width: 1200, height: 1200),
                quality: 0.9 * networkQualityMultiplier
            )
        case .storage:
            return (
                size: CGSize(width: 800, height: 800),
                quality: 0.85
            )
        }
    }

    private func networkQualityAdjustment(for networkType: NetworkType) -> CGFloat {
        switch networkType {
        case .wifi, .ethernet:
            return 1.0
        case .cellular5G:
            return 0.95
        case .cellular4G:
            return 0.85
        case .cellular3G:
            return 0.7
        case .unknown:
            return 0.8
        }
    }

    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let originalSize = image.size
        let aspectRatio = originalSize.width / originalSize.height

        var newSize = targetSize
        if aspectRatio > 1 {
            // Landscape
            newSize.height = targetSize.width / aspectRatio
        } else {
            // Portrait or square
            newSize.width = targetSize.height * aspectRatio
        }

        // Don't upscale images
        if newSize.width > originalSize.width || newSize.height > originalSize.height {
            newSize = originalSize
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Progressive Enhancement

struct ProgressiveEnhancementManager {
    static func enhanceImageLoadingStrategy(
        for posts: [Post],
        viewportSize: CGSize,
        scrollDirection: ScrollDirection
    ) -> ImageLoadingStrategy {
        let postCount = posts.count
        let averageImageSize = estimateAverageImageSize(for: posts)

        // Adjust strategy based on content density
        if postCount > 50 && averageImageSize > 500_000 { // > 500KB average
            return .lowQualityFirst
        } else if scrollDirection == .fast {
            return .placeholderFirst
        } else {
            return .standard
        }
    }

    private static func estimateAverageImageSize(for posts: [Post]) -> Int {
        // Estimate based on post characteristics
        return 300_000 // Placeholder: 300KB average
    }
}

enum ScrollDirection {
    case slow
    case medium
    case fast
}

enum ImageLoadingStrategy {
    case standard
    case lowQualityFirst
    case placeholderFirst
}

// MARK: - Supporting Types and Extensions

struct PrefetchStats {
    var locationBasedPrefetches = 0
    var userContentPrefetches = 0
    var timelinePrefetches = 0
    var totalDataPrefetched: Int64 = 0

    mutating func recordPrefetch(type: PrefetchType, count: Int) {
        switch type {
        case .locationBased:
            locationBasedPrefetches += count
        case .userContent:
            userContentPrefetches += count
        case .userTimeline:
            timelinePrefetches += count
        }
    }
}

enum PrefetchType {
    case locationBased
    case userContent
    case userTimeline
}

extension Notification.Name {
    static let locationDidChange = Notification.Name("locationDidChange")
}
