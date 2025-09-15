//======================================================================
// MARK: - BatchRequestOptimizer.swift
// Purpose: Batch request optimization for improved network efficiency
// Path: GLOBE/Core/Performance/BatchRequestOptimizer.swift
//======================================================================

import Foundation
import Combine
import CoreLocation
import Supabase

// MARK: - Batch Request Manager

@MainActor
class BatchRequestManager: ObservableObject {
    static let shared = BatchRequestManager()

    // Batch configuration
    private let maxBatchSize = 10
    private let batchDelayInterval: TimeInterval = 0.5
    private let maxRetries = 3

    // Pending requests
    private var pendingPostRequests: [PostRequest] = []
    private var pendingLikeRequests: [LikeRequest] = []
    private var pendingCommentRequests: [CommentRequest] = []

    // Batch timers
    private var postBatchTimer: Timer?
    private var likeBatchTimer: Timer?
    private var commentBatchTimer: Timer?

    // Network monitoring
    @Published var networkEfficiency: NetworkEfficiency = .good
    @Published var batchStats = BatchStats()

    private init() {
        setupNetworkMonitoring()
    }

    // MARK: - Batch Operations

    func batchFetchPosts(
        userIds: [String]? = nil,
        locationRadius: LocationRadius? = nil,
        limit: Int = 20
    ) async -> Result<[Post], AppError> {
        let request = PostBatchRequest(
            userIds: userIds,
            locationRadius: locationRadius,
            limit: limit,
            timestamp: Date()
        )

        return await executeBatchPostRequest(request)
    }

    func queueLikeRequest(postId: UUID, userId: String, isLike: Bool) {
        let request = LikeRequest(
            postId: postId,
            userId: userId,
            isLike: isLike,
            timestamp: Date()
        )

        pendingLikeRequests.append(request)

        // Schedule batch processing
        scheduleLikeBatch()
    }

    func queuePostUpdate(post: Post) {
        let request = PostRequest(
            action: .update,
            post: post,
            timestamp: Date()
        )

        pendingPostRequests.append(request)

        // Schedule batch processing
        schedulePostBatch()
    }

    func queueCommentOperation(postId: UUID, comment: Comment?, action: CommentAction) {
        let request = CommentRequest(
            postId: postId,
            comment: comment,
            action: action,
            timestamp: Date()
        )

        pendingCommentRequests.append(request)

        // Schedule batch processing
        scheduleCommentBatch()
    }

    // MARK: - Smart Prefetching

    func prefetchNearbyPosts(
        userLocation: CLLocationCoordinate2D,
        radius: Double = 5000 // 5km
    ) async {
        let request = PrefetchRequest(
            location: userLocation,
            radius: radius,
            priority: .background
        )

        await executePrefetchRequest(request)
    }

    func prefetchUserContent(userId: String, contentTypes: [ContentType]) async {
        let requests = contentTypes.map { contentType in
            PrefetchRequest(
                userId: userId,
                contentType: contentType,
                priority: .utility
            )
        }

        await withTaskGroup(of: Void.self) { group in
            for request in requests {
                group.addTask {
                    await self.executePrefetchRequest(request)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func schedulePostBatch() {
        postBatchTimer?.invalidate()
        postBatchTimer = Timer.scheduledTimer(withTimeInterval: batchDelayInterval, repeats: false) { [weak self] _ in
            Task { [weak self] in
                await self?.processPostBatch()
            }
        }
    }

    private func scheduleLikeBatch() {
        likeBatchTimer?.invalidate()
        likeBatchTimer = Timer.scheduledTimer(withTimeInterval: batchDelayInterval, repeats: false) { [weak self] _ in
            Task { [weak self] in
                await self?.processLikeBatch()
            }
        }
    }

    private func scheduleCommentBatch() {
        commentBatchTimer?.invalidate()
        commentBatchTimer = Timer.scheduledTimer(withTimeInterval: batchDelayInterval, repeats: false) { [weak self] _ in
            Task { [weak self] in
                await self?.processCommentBatch()
            }
        }
    }

    private func processPostBatch() async {
        guard !pendingPostRequests.isEmpty else { return }

        let batchRequests = Array(pendingPostRequests.prefix(maxBatchSize))
        pendingPostRequests.removeFirst(batchRequests.count)

        let startTime = Date()
        let result = await executeBatchPostOperations(batchRequests)

        await updateBatchStats(
            operationType: .posts,
            batchSize: batchRequests.count,
            duration: Date().timeIntervalSince(startTime),
            success: result.isSuccess
        )
    }

    private func processLikeBatch() async {
        guard !pendingLikeRequests.isEmpty else { return }

        let batchRequests = Array(pendingLikeRequests.prefix(maxBatchSize))
        pendingLikeRequests.removeFirst(batchRequests.count)

        let startTime = Date()
        let result = await executeBatchLikeOperations(batchRequests)

        await updateBatchStats(
            operationType: .likes,
            batchSize: batchRequests.count,
            duration: Date().timeIntervalSince(startTime),
            success: result.isSuccess
        )
    }

    private func processCommentBatch() async {
        guard !pendingCommentRequests.isEmpty else { return }

        let batchRequests = Array(pendingCommentRequests.prefix(maxBatchSize))
        pendingCommentRequests.removeFirst(batchRequests.count)

        let startTime = Date()
        let result = await executeBatchCommentOperations(batchRequests)

        await updateBatchStats(
            operationType: .comments,
            batchSize: batchRequests.count,
            duration: Date().timeIntervalSince(startTime),
            success: result.isSuccess
        )
    }

    // MARK: - Network Execution

    private func executeBatchPostRequest(_ request: PostBatchRequest) async -> Result<[Post], AppError> {
        do {
            // Build optimized query
            var rpcParams: [String: AnyJSON] = [
                "limit_count": .double(Double(request.limit))
            ]

            if let userIds = request.userIds {
                rpcParams["user_ids"] = .array(userIds.map { .string($0) })
            }

            if let location = request.locationRadius {
                rpcParams["latitude"] = .double(location.coordinate.latitude)
                rpcParams["longitude"] = .double(location.coordinate.longitude)
                rpcParams["radius_meters"] = .double(location.radius)
            }

            let response = try await (await supabase)
                .rpc("get_posts_batch", params: rpcParams)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let posts = try decoder.decode([Post].self, from: response.data)

            batchStats.recordSuccess(operationType: .posts, count: posts.count)
            return .success(posts)

        } catch {
            batchStats.recordError(operationType: .posts)
            return .failure(AppError.from(error))
        }
    }

    private func executeBatchLikeOperations(_ requests: [LikeRequest]) async -> Result<Void, AppError> {
        do {
            let likeOperations: [[String: AnyJSON]] = requests.map { request in
                [
                    "post_id": .string(request.postId.uuidString),
                    "user_id": .string(request.userId),
                    "is_like": .bool(request.isLike)
                ]
            }

            let params: [String: AnyJSON] = ["operations": .array(likeOperations.map { .object($0) })]

            _ = try await (await supabase)
                .rpc("batch_like_operations", params: params)
                .execute()

            batchStats.recordSuccess(operationType: .likes, count: requests.count)
            return .success(())

        } catch {
            batchStats.recordError(operationType: .likes)
            return .failure(AppError.from(error))
        }
    }

    private func executeBatchPostOperations(_ requests: [PostRequest]) async -> Result<Void, AppError> {
        do {
            let operations: [[String: AnyJSON]] = requests.map { request -> [String: AnyJSON] in
                switch request.action {
                case .create:
                    return [
                        "action": .string("create"),
                        "data": .object(encodePost(request.post))
                    ]
                case .update:
                    return [
                        "action": .string("update"),
                        "post_id": .string(request.post.id.uuidString),
                        "data": .object(encodePost(request.post))
                    ]
                case .delete:
                    return [
                        "action": .string("delete"),
                        "post_id": .string(request.post.id.uuidString)
                    ]
                }
            }

            let params: [String: AnyJSON] = ["operations": .array(operations.map { .object($0) })]

            _ = try await (await supabase)
                .rpc("batch_post_operations", params: params)
                .execute()

            batchStats.recordSuccess(operationType: .posts, count: requests.count)
            return .success(())

        } catch {
            batchStats.recordError(operationType: .posts)
            return .failure(AppError.from(error))
        }
    }

    private func executeBatchCommentOperations(_ requests: [CommentRequest]) async -> Result<Void, AppError> {
        do {
            let operations: [[String: AnyJSON]] = requests.compactMap { request -> [String: AnyJSON]? in
                switch request.action {
                case .create:
                    guard let comment = request.comment else { return nil }
                    return [
                        "action": .string("create"),
                        "post_id": .string(request.postId.uuidString),
                        "data": .object(encodeComment(comment))
                    ]
                case .update:
                    guard let comment = request.comment else { return nil }
                    return [
                        "action": .string("update"),
                        "comment_id": .string(comment.id.uuidString),
                        "data": .object(encodeComment(comment))
                    ]
                case .delete:
                    guard let comment = request.comment else { return nil }
                    return [
                        "action": .string("delete"),
                        "comment_id": .string(comment.id.uuidString)
                    ]
                }
            }

            let params: [String: AnyJSON] = ["operations": .array(operations.map { .object($0) })]

            _ = try await (await supabase)
                .rpc("batch_comment_operations", params: params)
                .execute()

            batchStats.recordSuccess(operationType: .comments, count: requests.count)
            return .success(())

        } catch {
            batchStats.recordError(operationType: .comments)
            return .failure(AppError.from(error))
        }
    }

    private func executePrefetchRequest(_ request: PrefetchRequest) async {
        // Implement prefetch logic based on request type
        SecureLogger.shared.info("Executing prefetch request type=\(String(describing: request.contentType)) priority=\(String(describing: request.priority))")
    }

    // MARK: - Helper Methods

    private func encodePost(_ post: Post) -> [String: AnyJSON] {
        return [
            "content": .string(post.text),
            "latitude": .double(post.latitude),
            "longitude": .double(post.longitude),
            "location_name": post.locationName.map { .string($0) } ?? .null,
            "is_anonymous": .bool(post.isAnonymous)
        ]
    }

    private func encodeComment(_ comment: Comment) -> [String: AnyJSON] {
        return [
            "content": .string(comment.text),
            "user_id": .string(comment.authorId)
        ]
    }

    private func setupNetworkMonitoring() {
        // Monitor network quality and adjust batch sizes accordingly
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.assessNetworkEfficiency()
            }
        }
    }

    private func assessNetworkEfficiency() async {
        let recentStats = batchStats.getRecentStats()
        let efficiency = calculateNetworkEfficiency(from: recentStats)

        await MainActor.run {
            self.networkEfficiency = efficiency
        }
    }

    private func calculateNetworkEfficiency(from stats: BatchStats.RecentStats) -> NetworkEfficiency {
        let successRate = stats.totalRequests > 0 ? Double(stats.successfulRequests) / Double(stats.totalRequests) : 1.0
        let avgLatency = stats.averageLatency

        if successRate > 0.95 && avgLatency < 0.5 {
            return .excellent
        } else if successRate > 0.9 && avgLatency < 1.0 {
            return .good
        } else if successRate > 0.8 && avgLatency < 2.0 {
            return .fair
        } else {
            return .poor
        }
    }

    private func updateBatchStats(
        operationType: OperationType,
        batchSize: Int,
        duration: TimeInterval,
        success: Bool
    ) async {
        await MainActor.run {
            batchStats.recordBatchOperation(
                type: operationType,
                size: batchSize,
                duration: duration,
                success: success
            )
        }
    }
}

// MARK: - Supporting Types

struct PostBatchRequest {
    let userIds: [String]?
    let locationRadius: LocationRadius?
    let limit: Int
    let timestamp: Date
}

struct LocationRadius {
    let coordinate: CLLocationCoordinate2D
    let radius: Double
}

struct LikeRequest {
    let postId: UUID
    let userId: String
    let isLike: Bool
    let timestamp: Date
}

struct PostRequest {
    let action: PostAction
    let post: Post
    let timestamp: Date
}

struct CommentRequest {
    let postId: UUID
    let comment: Comment?
    let action: CommentAction
    let timestamp: Date
}

struct PrefetchRequest {
    let location: CLLocationCoordinate2D?
    let userId: String?
    let contentType: ContentType?
    let radius: Double?
    let priority: TaskPriority

    init(
        location: CLLocationCoordinate2D,
        radius: Double,
        priority: TaskPriority
    ) {
        self.location = location
        self.radius = radius
        self.priority = priority
        self.userId = nil
        self.contentType = nil
    }

    init(
        userId: String,
        contentType: ContentType,
        priority: TaskPriority
    ) {
        self.userId = userId
        self.contentType = contentType
        self.priority = priority
        self.location = nil
        self.radius = nil
    }
}

enum PostAction {
    case create
    case update
    case delete
}

enum CommentAction {
    case create
    case update
    case delete
}

enum ContentType {
    case posts
    case comments
    case likes
    case profile
    case stories
}

enum OperationType {
    case posts
    case comments
    case likes
    case prefetch
}

enum NetworkEfficiency {
    case excellent
    case good
    case fair
    case poor
}

// MARK: - Batch Statistics

class BatchStats: ObservableObject {
    @Published var totalBatches = 0
    @Published var successfulBatches = 0
    @Published var averageBatchSize = 0.0
    @Published var averageLatency = 0.0

    private var recentOperations: [(type: OperationType, size: Int, duration: TimeInterval, success: Bool, timestamp: Date)] = []
    private let maxRecentOperations = 100

    func recordBatchOperation(
        type: OperationType,
        size: Int,
        duration: TimeInterval,
        success: Bool
    ) {
        totalBatches += 1
        if success {
            successfulBatches += 1
        }

        let operation = (type: type, size: size, duration: duration, success: success, timestamp: Date())
        recentOperations.append(operation)

        // Keep only recent operations
        if recentOperations.count > maxRecentOperations {
            recentOperations.removeFirst(recentOperations.count - maxRecentOperations)
        }

        updateAverages()
    }

    func recordSuccess(operationType: OperationType, count: Int) {
        recordBatchOperation(type: operationType, size: count, duration: 0, success: true)
    }

    func recordError(operationType: OperationType) {
        recordBatchOperation(type: operationType, size: 0, duration: 0, success: false)
    }

    func getRecentStats() -> RecentStats {
        let recentOps = recentOperations.filter { Date().timeIntervalSince($0.timestamp) < 300 } // Last 5 minutes
        let successCount = recentOps.filter(\.success).count
        let totalCount = recentOps.count
        let avgLatency = recentOps.isEmpty ? 0 : recentOps.map(\.duration).reduce(0, +) / Double(recentOps.count)

        return RecentStats(
            successfulRequests: successCount,
            totalRequests: totalCount,
            averageLatency: avgLatency
        )
    }

    private func updateAverages() {
        let recentOps = recentOperations.filter { Date().timeIntervalSince($0.timestamp) < 600 } // Last 10 minutes
        averageBatchSize = recentOps.isEmpty ? 0 : Double(recentOps.map(\.size).reduce(0, +)) / Double(recentOps.count)
        averageLatency = recentOps.isEmpty ? 0 : recentOps.map(\.duration).reduce(0, +) / Double(recentOps.count)
    }

    struct RecentStats {
        let successfulRequests: Int
        let totalRequests: Int
        let averageLatency: TimeInterval
    }
}

// MARK: - Result Extensions

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}
