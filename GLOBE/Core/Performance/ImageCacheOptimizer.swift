//======================================================================
// MARK: - ImageCacheOptimizer.swift
// Purpose: Advanced image caching and optimization strategies
// Path: GLOBE/Core/Performance/ImageCacheOptimizer.swift
//======================================================================

import SwiftUI
import UIKit
import Combine

// MARK: - Advanced Image Cache Manager

@MainActor
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()

    // Multi-level cache system
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: URLCache
    private let cacheRepository: CacheRepositoryProtocol

    // Performance optimization settings
    private let maxMemoryCacheSize = 50 * 1024 * 1024 // 50MB
    private let maxDiskCacheSize = 200 * 1024 * 1024 // 200MB
    private let imageProcessingQueue = DispatchQueue(label: "image.processing", qos: .utility, attributes: .concurrent)

    // Cache metrics for monitoring
    @Published var cacheHitRate: Double = 0.0
    @Published var memoryUsage: Int64 = 0
    @Published var diskUsage: Int64 = 0

    private var cacheHits = 0
    private var totalRequests = 0

    init(cacheRepository: CacheRepositoryProtocol? = nil) {
        self.cacheRepository = cacheRepository ?? CacheRepository.create()

        // Configure memory cache
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 200

        // Configure disk cache
        diskCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024, // 10MB memory
            diskCapacity: maxDiskCacheSize,
            diskPath: "image_cache"
        )

        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleMemoryWarning()
            }
        }

        // Periodic cache maintenance
        setupCacheMaintenance()
    }

    // MARK: - Image Loading and Caching

    func loadImage(
        from url: URL,
        size: CGSize? = nil,
        placeholder: UIImage? = nil
    ) async -> UIImage? {
        totalRequests += 1
        let cacheKey = cacheKey(for: url, size: size)

        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: NSString(string: cacheKey)) {
            cacheHits += 1
            updateCacheHitRate()
            return cachedImage
        }

        // Check disk cache
        if let diskImage = await loadFromDiskCache(key: cacheKey) {
            cacheHits += 1
            updateCacheHitRate()

            // Store in memory cache for faster access
            memoryCache.setObject(diskImage, forKey: NSString(string: cacheKey))
            return diskImage
        }

        // Load from network
        return await loadFromNetwork(url: url, cacheKey: cacheKey, targetSize: size)
    }

    func preloadImages(urls: [URL], priority: TaskPriority = .medium) {
        Task(priority: priority) {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask { [weak self] in
                        _ = await self?.loadImage(from: url)
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private func loadFromDiskCache(key: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            Task {
                do {
                    if let data = try await self.cacheRepository.getCachedImage(for: key),
                       let image = UIImage(data: data) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadFromNetwork(url: URL, cacheKey: String, targetSize: CGSize?) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let originalImage = UIImage(data: data) else {
                return nil
            }

            // Process image asynchronously
            let processedImage = await processImage(
                originalImage,
                targetSize: targetSize,
                cacheKey: cacheKey
            )

            // Cache the processed image
            await cacheImage(processedImage, forKey: cacheKey, originalData: data)

            return processedImage

        } catch {
            SecureLogger.shared.error("Failed to load image from network: \(error.localizedDescription)")
            return nil
        }
    }

    private func processImage(
        _ image: UIImage,
        targetSize: CGSize?,
        cacheKey: String
    ) async -> UIImage {
        return await withCheckedContinuation { continuation in
            imageProcessingQueue.async {
                var processedImage = image

                // Resize if target size specified
                if let targetSize = targetSize {
                    processedImage = ImageCacheManager.resizeImage(processedImage, to: targetSize)
                }

                // Optimize for display
                processedImage = ImageCacheManager.optimizeImageForDisplay(processedImage)

                continuation.resume(returning: processedImage)
            }
        }
    }

    nonisolated private static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    nonisolated private static func optimizeImageForDisplay(_ image: UIImage) -> UIImage {
        // Force decode image to avoid on-demand decoding during scroll
        let renderer = UIGraphicsImageRenderer(size: image.size, format: image.imageRendererFormat)
        return renderer.image { _ in
            image.draw(at: .zero)
        }
    }

    private func cacheImage(_ image: UIImage, forKey key: String, originalData: Data) async {
        // Store in memory cache
        memoryCache.setObject(image, forKey: NSString(string: key))

        // Store in disk cache asynchronously
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            do {
                try await self.cacheRepository.cacheImage(data: originalData, for: key)
            } catch {
                await SecureLogger.shared.error("Failed to cache image to disk: \(error.localizedDescription)")
            }
        }
    }

    private func cacheKey(for url: URL, size: CGSize?) -> String {
        var key = url.absoluteString
        if let size = size {
            key += "_\(Int(size.width))x\(Int(size.height))"
        }
        return key.md5
    }

    private func updateCacheHitRate() {
        cacheHitRate = Double(cacheHits) / Double(totalRequests)
    }

    private func handleMemoryWarning() {
        memoryCache.removeAllObjects()
        SecureLogger.shared.warning("Memory warning: Cleared image memory cache")
    }

    private func setupCacheMaintenance() {
        // Clean up cache every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performCacheMaintenance()
            }
        }
    }

    private func performCacheMaintenance() async {
        do {
            diskUsage = try await cacheRepository.getCacheSize()

            // Clean old cache entries if needed
            if diskUsage > Int64(maxDiskCacheSize * 80 / 100) { // 80% threshold
                await cleanOldCacheEntries()
            }
        } catch {
            SecureLogger.shared.error("Cache maintenance failed: \(error.localizedDescription)")
        }
    }

    private func cleanOldCacheEntries() async {
        // Implementation would depend on cache repository having cleanup methods
        SecureLogger.shared.info("Cleaning old cache entries")
    }
}

// MARK: - Optimized AsyncImage

struct OptimizedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let targetSize: CGSize?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @StateObject private var cacheManager = ImageCacheManager.shared
    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        targetSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.targetSize = targetSize
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                content(Image(uiImage: loadedImage))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }

        isLoading = true

        Task {
            let image = await cacheManager.loadImage(
                from: url,
                size: targetSize
            )

            await MainActor.run {
                self.loadedImage = image
                self.isLoading = false
            }
        }
    }
}

// MARK: - Smart Image Preloader

class SmartImagePreloader {
    private let cacheManager = ImageCacheManager.shared
    private let prefetchDistance: Int
    private var prefetchQueue: Set<URL> = []

    init(prefetchDistance: Int = 3) {
        self.prefetchDistance = prefetchDistance
    }

    func prefetchImages(for posts: [Post], currentIndex: Int) {
        let startIndex = max(0, currentIndex - prefetchDistance)
        let endIndex = min(posts.count, currentIndex + prefetchDistance * 2)

        let urlsToPreload: [URL] = posts[startIndex..<endIndex].compactMap { post in
            guard let imageUrl = post.imageUrl else { return nil }
            return URL(string: imageUrl)
        }

        // Only preload new URLs
        let newURLs = urlsToPreload.filter { !prefetchQueue.contains($0) }

        if !newURLs.isEmpty {
            prefetchQueue.formUnion(newURLs)
            cacheManager.preloadImages(urls: newURLs, priority: .low)
        }
    }
}

// MARK: - Adaptive Image Quality

struct AdaptiveImageQuality {
    static func recommendedSize(for screenSize: CGSize, itemCount: Int) -> CGSize {
        let baseSize: CGFloat = 300
        let scaleFactor = min(1.0, sqrt(Double(itemCount)) / 10.0)
        let adaptiveSize = baseSize * scaleFactor

        return CGSize(
            width: min(adaptiveSize, screenSize.width * 0.8),
            height: min(adaptiveSize, screenSize.height * 0.8)
        )
    }

    static func compressionQuality(for networkType: NetworkType) -> CGFloat {
        switch networkType {
        case .wifi, .ethernet:
            return 0.9
        case .cellular5G:
            return 0.8
        case .cellular4G:
            return 0.7
        case .cellular3G:
            return 0.5
        case .unknown:
            return 0.6
        }
    }
}

enum NetworkType {
    case wifi
    case ethernet
    case cellular5G
    case cellular4G
    case cellular3G
    case unknown
}

// MARK: - Progressive Image Loading

struct ProgressiveImage: View {
    let url: URL?
    let aspectRatio: CGFloat

    @State private var lowQualityImage: UIImage?
    @State private var highQualityImage: UIImage?
    @State private var loadingProgress: Double = 0

    var body: some View {
        ZStack {
            // Low quality placeholder
            if let lowQualityImage = lowQualityImage {
                Image(uiImage: lowQualityImage)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .blur(radius: highQualityImage == nil ? 3 : 0)
                    .animation(.easeInOut(duration: 0.3), value: highQualityImage != nil)
            }

            // High quality image
            if let highQualityImage = highQualityImage {
                Image(uiImage: highQualityImage)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .transition(.opacity)
            }

            // Loading indicator
            if loadingProgress > 0 && loadingProgress < 1 {
                ProgressView(value: loadingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .onAppear {
            loadProgressiveImage()
        }
    }

    private func loadProgressiveImage() {
        guard let url = url else { return }

        Task {
            // Load low quality first
            await loadLowQuality(from: url)

            // Then load high quality
            await loadHighQuality(from: url)
        }
    }

    private func loadLowQuality(from url: URL) async {
        let lowQualitySize = CGSize(width: 50, height: 50 / aspectRatio)
        let image = await ImageCacheManager.shared.loadImage(from: url, size: lowQualitySize)

        await MainActor.run {
            self.lowQualityImage = image
            self.loadingProgress = 0.3
        }
    }

    private func loadHighQuality(from url: URL) async {
        let image = await ImageCacheManager.shared.loadImage(from: url)

        await MainActor.run {
            self.highQualityImage = image
            self.loadingProgress = 1.0
        }
    }
}

// MARK: - Helper Extensions

extension String {
    var md5: String {
        // Simple hash function for cache keys
        return String(self.hashValue)
    }
}
