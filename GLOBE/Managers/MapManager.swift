import Foundation
import MapKit
import Combine
import SwiftUI

class MapManager: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // 東京
        span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0) // 日本周辺表示
    )
    @Published var posts: [Post] = []
    @Published var adjustedPostPositions: [UUID: CLLocationCoordinate2D] = [:]
    @Published var postOpacities: [UUID: Double] = [:]

    /// 密集度フィルタリングを適用した表示対象投稿
    var visiblePosts: [Post] {
        return posts.filter { shouldShowPost($0) }
    }
    
    // MapCameraPosition updates for modern Map view
    @Published var shouldUpdateMapPosition: MapCameraPosition?
    private var cleanupTimer: Timer?
    private let postManager = PostManager.shared
    private var cancellables = Set<AnyCancellable>()
    // 吹き出しV先端から算出されたドラフト投稿座標
    @Published var draftPostCoordinate: CLLocationCoordinate2D?
    
    init() {
        // Reset draft coordinate to prevent stale 3D corrections
        draftPostCoordinate = nil
        startCleanupTimer()
        setupPostSubscription()
    }

    private var didFetchInitial = false
    func fetchInitialPostsIfNeeded() async {
        guard !didFetchInitial else { return }
        didFetchInitial = true
        await postManager.fetchPosts()
    }
    
    private func setupPostSubscription() {
        // PostManager からの投稿データを監視
        postManager.$posts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPosts in
                print("🗺️ MapManager: Received \(newPosts.count) posts from PostManager")
                for (index, post) in newPosts.enumerated() {
                    print("🗺️ MapManager Post \(index): \(post.id) at (\(post.location.latitude), \(post.location.longitude)) - '\(post.text)'")
                }
                self?.posts = newPosts
                self?.adjustPostPositions()
                self?.calculatePostOpacities()
                self?.objectWillChange.send()
                print("🗺️ MapManager: Updated posts and sent objectWillChange")
            }
            .store(in: &cancellables)
    }

    func refreshPosts() {
        print("🗺️ MapManager: Manually refreshing posts")
        posts = postManager.posts
        objectWillChange.send()
    }

    func addTestPost() {
        print("🗺️ MapManager: Adding test post")
        let testPost = Post(
            location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locationName: "テスト位置",
            text: "テスト投稿",
            authorName: "Test User",
            authorId: "test-user-id"
        )
        posts.append(testPost)
        objectWillChange.send()
        print("🗺️ MapManager: Test post added, total posts: \(posts.count)")
    }
    
    func focusOnLocation(_ coordinate: CLLocationCoordinate2D, zoomLevel: Double = 0.001) {
        print("🗺🔥 MapManager: focusOnLocation called with coordinate: \(coordinate)")
        print("🗺🔥 MapManager: Current region center: \(region.center)")
        print("🗺🔥 MapManager: zoomLevel: \(zoomLevel)")

        let newRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: zoomLevel, longitudeDelta: zoomLevel) // デフォルトは約100m範囲
        )

        // Update the legacy region property first
        self.region = newRegion

        // Force update the map position immediately on main thread
        if Thread.isMainThread {
            self.shouldUpdateMapPosition = MapCameraPosition.region(newRegion)
            self.objectWillChange.send()
        } else {
            DispatchQueue.main.async {
                self.shouldUpdateMapPosition = MapCameraPosition.region(newRegion)
                self.objectWillChange.send()
            }
        }

        print("🗺🔥 MapManager: Updated region center: \(newRegion.center)")
        print("🗺🔥 MapManager: Region span: \(newRegion.span)")
        print("🗺🔥 MapManager: shouldUpdateMapPosition set to new region")
    }
    
    // 期限切れ投稿を削除
    private func cleanupExpiredPosts() {
        let expiredPosts = posts.filter { $0.isExpired }
        
        if !expiredPosts.isEmpty {
            Task {
                for post in expiredPosts {
                    let _ = await postManager.deletePost(post.id)
                }
            }
        }
    }
    
    // 定期的に期限切れ投稿をチェック（5分ごと）
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            DispatchQueue.main.async {
                self.cleanupExpiredPosts()
            }
        }
    }

    // MARK: - Card Position Adjustment (Collision Prevention)

    private func adjustPostPositions() {
        print("🗺️ MapManager: Adjusting post positions for \(posts.count) posts")

        // 新しい調整済み位置をクリア
        adjustedPostPositions.removeAll()

        // 投稿を作成日時順（新しいものが後）でソート
        let sortedPosts = posts.sorted { $0.createdAt < $1.createdAt }

        for (index, post) in sortedPosts.enumerated() {
            let originalLocation = post.location
            var adjustedLocation = originalLocation

            // 既存の投稿との重複をチェック
            for i in 0..<index {
                let existingPost = sortedPosts[i]
                let existingLocation = adjustedPostPositions[existingPost.id] ?? existingPost.location

                // 距離をチェック（カードサイズを考慮した最小距離）
                let distance = distanceBetweenCoordinates(adjustedLocation, existingLocation)
                let minDistance = minimumCardDistance()

                if distance < minDistance {
                    // 重複している場合、新しい位置を見つける
                    adjustedLocation = findNonOverlappingPosition(
                        around: originalLocation,
                        avoiding: Array(adjustedPostPositions.values),
                        minDistance: minDistance
                    )
                    print("🗺️ MapManager: Adjusted position for post \(post.id.uuidString.prefix(8))")
                    break
                }
            }

            adjustedPostPositions[post.id] = adjustedLocation
        }

        print("🗺️ MapManager: Position adjustment complete")
    }

    private func minimumCardDistance() -> Double {
        // カードサイズ135pxの真隣に配置（約20メートル）
        return 20.0
    }

    private func findNonOverlappingPosition(
        around center: CLLocationCoordinate2D,
        avoiding existingPositions: [CLLocationCoordinate2D],
        minDistance: Double
    ) -> CLLocationCoordinate2D {
        let offsetDistance = minDistance * 1.1 // 真隣に配置
        let angleStep = 45.0 // 8方向をチェック

        for angle in stride(from: 0.0, to: 360.0, by: angleStep) {
            let radians = angle * .pi / 180.0
            let offsetCoord = coordinateOffset(
                from: center,
                distance: offsetDistance,
                bearing: radians
            )

            // この位置が他の投稿と重複しないかチェック
            var isValidPosition = true
            for existingPos in existingPositions {
                if distanceBetweenCoordinates(offsetCoord, existingPos) < minDistance {
                    isValidPosition = false
                    break
                }
            }

            if isValidPosition {
                return offsetCoord
            }
        }

        // 全方向で重複する場合は、少し離れた位置を返す
        return coordinateOffset(from: center, distance: offsetDistance * 2, bearing: 0)
    }

    private func coordinateOffset(
        from coordinate: CLLocationCoordinate2D,
        distance: Double,
        bearing: Double
    ) -> CLLocationCoordinate2D {
        let R = 6378137.0 // 地球の半径（メートル）
        let lat1 = coordinate.latitude * .pi / 180
        let lon1 = coordinate.longitude * .pi / 180

        let lat2 = asin(sin(lat1) * cos(distance / R) + cos(lat1) * sin(distance / R) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distance / R) * cos(lat1), cos(distance / R) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(
            latitude: lat2 * 180 / .pi,
            longitude: lon2 * 180 / .pi
        )
    }

    // 調整済み位置を取得する関数
    func getAdjustedPosition(for postId: UUID, originalLocation: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return adjustedPostPositions[postId] ?? originalLocation
    }

    // MARK: - Opacity-Based Overlap Management

    private func calculatePostOpacities() {
        print("🗺️ MapManager: Calculating post opacities for \(posts.count) posts")

        postOpacities.removeAll()

        for post in posts {
            let overlapCount = countOverlappingPosts(around: post.location)
            let opacity = calculateOpacity(overlapCount: overlapCount)
            postOpacities[post.id] = opacity

            print("📍 Post[\(post.id.uuidString.prefix(8))] Overlaps: \(overlapCount), Opacity: \(String(format: "%.2f", opacity))")
        }

        print("🗺️ MapManager: Opacity calculation complete")
    }

    private func countOverlappingPosts(around location: CLLocationCoordinate2D) -> Int {
        let overlapRadius: Double = 50.0 // 50m範囲内の投稿を重なりと判定

        return posts.filter { post in
            let distance = distanceBetweenCoordinates(location, post.location)
            return distance <= overlapRadius
        }.count - 1 // 自分自身を除く
    }

    private func calculateOpacity(overlapCount: Int) -> Double {
        switch overlapCount {
        case 0...4:
            return 1.0 // 完全不透明
        case 5...9:
            // 5枚で徐々に薄くなり始め、10枚で消える
            let fadeProgress = Double(overlapCount - 4) / 6.0 // 0.0 to 1.0
            return max(0.0, 1.0 - fadeProgress) // 1.0 → 0.0
        default:
            return 0.0 // 完全透明（非表示）
        }
    }

    private func distanceBetweenCoordinates(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }

    // 投稿の透明度を取得する関数
    func getPostOpacity(for postId: UUID) -> Double {
        return postOpacities[postId] ?? 1.0
    }

    // MARK: - Configuration Constants (Smooth Logarithmic Visibility Control)

    /// 密度計算で考慮する画面内の最大投稿数。これ以上は密度が最大として扱われる。
    private let MAX_DENSITY_COUNT = 100.0

    /// 閾値計算に使うズームレベル（latitudeDelta）の最小値（最も拡大した状態）
    private let MIN_ZOOM_SPAN = 0.001

    /// 閾値計算に使うズームレベル（latitudeDelta）の最大値（最も縮小した状態）
    private let MAX_ZOOM_SPAN = 100.0 // 太平洋全体をカバー

    /// 投稿スコアが超えるべき閾値の最小値
    private let MIN_THRESHOLD = 0.2

    /// 投稿スコアが超えるべき閾値の最大値
    private let MAX_THRESHOLD = 0.7 // パリで最大拡大時も表示されるよう調整

    /// 閾値計算におけるズームレベルと密度の影響度（合計で1.0になるように）
    private let ZOOM_WEIGHT = 0.2 // ズームレベルの重要度
    private let DENSITY_WEIGHT = 0.8 // 密度の重要度（密集度を主要因子に）

    // MARK: - Smooth Logarithmic Visibility Control

    func shouldShowPost(_ post: Post) -> Bool {
        let currentZoomLevel = region.span.latitudeDelta

        // 1. パフォーマンスのため、まず画面内の投稿のみをフィルタリング
        let postsInRegion = posts.filter { isCoordinate($0.location, in: region) }
        let density = postsInRegion.count

        // 2. ズームレベルと密度から動的な閾値を計算
        let threshold = calculateDynamicThreshold(zoomLevel: currentZoomLevel, density: density)

        // 3. スコアが閾値を超えた投稿のみを表示対象とする
        let postScore = calculatePostScore(post)

        // デバッグログ
        print("🔍 Post[\(post.id.uuidString.prefix(8))] Density:\(density), Score:\(String(format: "%.3f", postScore)), Threshold:\(String(format: "%.3f", threshold)), Show:\(postScore >= threshold)")

        return postScore >= threshold
    }

    /// ズームレベルと密度から、表示/非表示の閾値を動的に計算する
    private func calculateDynamicThreshold(zoomLevel: Double, density: Int) -> Double {
        // --- ズーム係数を計算 (0.0: 最大拡大 ~ 1.0: 最大縮小) ---
        // 対数スケールでズームレベルを正規化し、急激な変化を防ぐ
        let clampedZoom = max(MIN_ZOOM_SPAN, min(MAX_ZOOM_SPAN, zoomLevel))
        let logMinZoom = log(MIN_ZOOM_SPAN)
        let logMaxZoom = log(MAX_ZOOM_SPAN)
        let zoomFactor = (log(clampedZoom) - logMinZoom) / (logMaxZoom - logMinZoom)

        // --- 密度係数を計算 (0.0: 低密度 ~ 1.0: 高密度) ---
        let densityFactor = min(1.0, Double(density) / MAX_DENSITY_COUNT)

        // --- 最終的な閾値を計算 ---
        // ズーム係数と密度係数を重み付けして合成
        let combinedFactor = (zoomFactor * ZOOM_WEIGHT) + (densityFactor * DENSITY_WEIGHT)

        // 最終的な閾値を MIN_THRESHOLD と MAX_THRESHOLD の間にマッピング
        let threshold = MIN_THRESHOLD + (MAX_THRESHOLD - MIN_THRESHOLD) * combinedFactor

        // デバッグログ
        print("📊 Threshold Calc - Zoom:\(String(format: "%.3f", zoomLevel)) -> ZoomFactor:\(String(format: "%.3f", zoomFactor)), DensityFactor:\(String(format: "%.3f", densityFactor)), Combined:\(String(format: "%.3f", combinedFactor)), Threshold:\(String(format: "%.3f", threshold))")

        return threshold
    }

    /// 投稿の重要度を計算する（密集度ベース制御のため一律スコア）
    private func calculatePostScore(_ post: Post) -> Double {
        // 純粋に密集度とズームレベルで制御するため、すべての投稿に同じスコアを付与
        return 0.6 // 密集地域でも最大拡大時は表示されるよう調整
    }

    // 指定した座標が領域内に含まれるかを判定するヘルパー
    private func isCoordinate(_ coordinate: CLLocationCoordinate2D, in region: MKCoordinateRegion) -> Bool {
        let center = region.center
        let span = region.span

        let maxLat = center.latitude + span.latitudeDelta / 2
        let minLat = center.latitude - span.latitudeDelta / 2
        let maxLon = center.longitude + span.longitudeDelta / 2
        let minLon = center.longitude - span.longitudeDelta / 2

        return coordinate.latitude >= minLat && coordinate.latitude <= maxLat &&
               coordinate.longitude >= minLon && coordinate.longitude <= maxLon
    }

    deinit {
        cleanupTimer?.invalidate()
    }
}
