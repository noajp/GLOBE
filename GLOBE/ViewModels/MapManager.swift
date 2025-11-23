//======================================================================
// MARK: - MapManager.swift
// 機能名: 地図管理マネージャー
// 機能概要: 地図の状態、投稿表示ロジック、クラスタリングを管理
// 処理内容: ズームレベルに応じた投稿フィルタリング、衝突回避、透明度制御
//======================================================================

import Foundation
import SwiftUI
import MapKit
import Combine

//###############################################################################
// MARK: - MapManager Class
//###############################################################################

@MainActor
class MapManager: ObservableObject {

    //###########################################################################
    // MARK: - Published Properties
    // 機能概要: SwiftUIビューにバインドされる公開プロパティ
    // 処理内容: @Publishedでビューの自動更新をトリガー
    //###########################################################################

    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    @Published var posts: [Post] = []
    @Published var adjustedPostPositions: [UUID: CLLocationCoordinate2D] = [:]
    @Published var postOpacities: [UUID: Double] = [:]
    @Published var postClusters: [PostCluster] = []
    @Published var shouldUpdateMapPosition: MapCameraPosition?
    @Published var draftPostCoordinate: CLLocationCoordinate2D?

    //###########################################################################
    // MARK: - Private Properties
    // 機能概要: 内部状態管理用のプライベートプロパティ
    // 処理内容: キャッシュ、依存関係、タイマーを保持
    //###########################################################################

    private var lastFetchedRegion: MKCoordinateRegion?
    private var lastFetchedZoomLevel: Double?
    private var didFetchInitial = false

    private let postManager = PostManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var cleanupTimer: Timer?

    //###########################################################################
    // MARK: - Display Mode Configuration
    // 機能概要: ズームレベル別の表示モード定義
    // 処理内容: 距離に応じて3段階のモードを切り替え
    //###########################################################################

    private let nearDistanceThreshold = 0.01   // ~1km
    private let midDistanceThreshold = 0.2     // ~20km

    enum DisplayMode {
        case nearDistance   // 全投稿+衝突回避
        case midDistance    // 高エンゲージメント投稿のみ
        case farDistance    // クラスター表示
    }

    var currentDisplayMode: DisplayMode {
        let span = region.span.latitudeDelta
        if span <= nearDistanceThreshold {
            return .nearDistance
        } else if span <= midDistanceThreshold {
            return .midDistance
        } else {
            return .farDistance
        }
    }

    //###########################################################################
    // MARK: - Computed Properties
    // 機能概要: 表示モードに応じた投稿フィルタリング
    // 処理内容: nearは全投稿、midは上位60件、farは空配列
    //###########################################################################

    var visiblePosts: [Post] {
        switch currentDisplayMode {
        case .nearDistance:
            return posts

        case .midDistance:
            let highEngagement = posts.filter { !$0.isAnonymous && $0.likeCount > 0 }
            let regular = posts.filter { $0.isAnonymous || $0.likeCount == 0 }

            let sortedHighEngagement = highEngagement.sorted { $0.likeCount > $1.likeCount }.prefix(30)
            let limitedRegular = regular.prefix(30)

            return Array(sortedHighEngagement) + Array(limitedRegular)

        case .farDistance:
            return []
        }
    }

    //###########################################################################
    // MARK: - Initialization
    // 機能名: init
    // 機能概要: MapManagerの初期化
    // 処理内容: タイマー起動、投稿サブスクリプション設定
    //###########################################################################

    init() {
        draftPostCoordinate = nil
        startCleanupTimer()
        setupPostSubscription()
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    //###########################################################################
    // MARK: - Initial Setup
    //###########################################################################

    // 機能名: setInitialRegionToCurrentLocation
    // 機能概要: ユーザーの現在地を地図の初期表示位置に設定
    // 処理内容: 緯度経度から2km範囲のリージョンを生成し、regionとshouldUpdateMapPositionを更新
    func setInitialRegionToCurrentLocation(_ location: CLLocationCoordinate2D) {
        let initialRegion = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        self.region = initialRegion
        self.shouldUpdateMapPosition = MapCameraPosition.region(initialRegion)
    }

    // 機能名: setupPostSubscription
    // 機能概要: PostManagerの投稿データ変更を監視
    // 処理内容: Combineで投稿更新を受信し、表示モードに応じて位置調整/クラスタリングを実行
    private func setupPostSubscription() {
        postManager.$posts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPosts in
                guard let self = self else { return }
                self.posts = newPosts

                switch self.currentDisplayMode {
                case .nearDistance:
                    self.adjustPostPositions()
                    self.calculatePostOpacities()
                case .midDistance:
                    break
                case .farDistance:
                    self.updateClusters()
                }

                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    //###########################################################################
    // MARK: - Post Fetching
    // 機能概要: ビューポート内の投稿データ取得
    // 処理内容: キャッシュチェック、境界計算、PostManagerへのデータ要求
    //###########################################################################

    // 機能名: fetchInitialPostsIfNeeded
    // 機能概要: 初回のみ投稿データを取得
    // 処理内容: didFetchInitialフラグで重複取得を防ぎ、fetchPostsInViewportを呼び出し
    func fetchInitialPostsIfNeeded() async {
        guard !didFetchInitial else { return }
        didFetchInitial = true
        await fetchPostsInViewport()
    }

    // 機能名: fetchPostsInViewport
    // 機能概要: 現在の地図表示範囲内の投稿を取得
    // 処理内容: キャッシュチェック→パディング付き境界計算→PostManager経由でDB取得
    func fetchPostsInViewport() async {
        let center = region.center
        let span = region.span

        if shouldSkipFetch(center: center, span: span) {
            return
        }

        let bounds = calculatePaddedBounds(center: center, span: span)

        await postManager.fetchPostsInBounds(
            minLat: bounds.minLat,
            maxLat: bounds.maxLat,
            minLng: bounds.minLng,
            maxLng: bounds.maxLng,
            zoomLevel: span.latitudeDelta
        )

        lastFetchedRegion = region
        lastFetchedZoomLevel = span.latitudeDelta
    }

    // 機能名: shouldSkipFetch
    // 機能概要: 前回取得時と領域が類似している場合はスキップ
    // 処理内容: 中心点の移動距離とズーム変化率が30%未満ならtrueを返す
    private func shouldSkipFetch(center: CLLocationCoordinate2D, span: MKCoordinateSpan) -> Bool {
        guard let lastRegion = lastFetchedRegion,
              let lastZoom = lastFetchedZoomLevel else {
            return false
        }

        let centerDistance = sqrt(
            pow(center.latitude - lastRegion.center.latitude, 2) +
            pow(center.longitude - lastRegion.center.longitude, 2)
        )

        let zoomDiff = abs(span.latitudeDelta - lastZoom) / lastZoom

        return centerDistance < (span.latitudeDelta * 0.3) && zoomDiff < 0.3
    }

    // 機能名: calculatePaddedBounds
    // 機能概要: スムーズなパンのために20%パディングした境界を計算
    // 処理内容: 緯度経度のスパンを1.2倍に拡大し、min/max座標のタプルを返す
    private func calculatePaddedBounds(center: CLLocationCoordinate2D, span: MKCoordinateSpan) -> (minLat: Double, maxLat: Double, minLng: Double, maxLng: Double) {
        let padding = 0.2
        let paddedLatDelta = span.latitudeDelta * (1 + padding)
        let paddedLngDelta = span.longitudeDelta * (1 + padding)

        return (
            minLat: center.latitude - paddedLatDelta / 2,
            maxLat: center.latitude + paddedLatDelta / 2,
            minLng: center.longitude - paddedLngDelta / 2,
            maxLng: center.longitude + paddedLngDelta / 2
        )
    }

    // 機能名: refreshPosts
    // 機能概要: PostManagerから最新の投稿リストを取得
    // 処理内容: PostManager.postsをコピーしobjectWillChangeを発火
    func refreshPosts() {
        posts = postManager.posts
        objectWillChange.send()
    }

    //###########################################################################
    // MARK: - Map Navigation
    // 機能概要: 地図の移動とズーム制御
    // 処理内容: 指定座標へのフォーカス、リージョン更新
    //###########################################################################

    // 機能名: focusOnLocation
    // 機能概要: 指定座標にズームして地図を移動
    // 処理内容: 新しいリージョンを作成し、メインスレッドでshouldUpdateMapPositionを更新
    func focusOnLocation(_ coordinate: CLLocationCoordinate2D, zoomLevel: Double = 0.001) {
        let newRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: zoomLevel, longitudeDelta: zoomLevel)
        )

        self.region = newRegion

        if Thread.isMainThread {
            self.shouldUpdateMapPosition = MapCameraPosition.region(newRegion)
            self.objectWillChange.send()
        } else {
            DispatchQueue.main.async {
                self.shouldUpdateMapPosition = MapCameraPosition.region(newRegion)
                self.objectWillChange.send()
            }
        }
    }

    //###########################################################################
    // MARK: - Post Cleanup
    // 機能概要: 期限切れ投稿の自動削除
    // 処理内容: 5分ごとにタイマーで期限切れをチェックし削除
    //###########################################################################

    // 機能名: startCleanupTimer
    // 機能概要: 5分ごとの期限切れ投稿チェックタイマーを起動
    // 処理内容: Timer.scheduledTimerで300秒間隔でcleanupExpiredPostsを呼び出し
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            DispatchQueue.main.async {
                self.cleanupExpiredPosts()
            }
        }
    }

    // 機能名: cleanupExpiredPosts
    // 機能概要: 期限切れ投稿をフィルタして削除
    // 処理内容: isExpiredでフィルタし、PostManager.deletePostで各投稿を削除
    private func cleanupExpiredPosts() {
        let expiredPosts = posts.filter { $0.isExpired }

        if !expiredPosts.isEmpty {
            Task {
                for post in expiredPosts {
                    _ = await postManager.deletePost(post.id)
                }
            }
        }
    }

    //###########################################################################
    // MARK: - Collision Prevention
    // 機能概要: 近距離モードでの投稿カード衝突回避
    // 処理内容: 重複検出→8方向探索→調整済み位置を保存
    //###########################################################################

    // 機能名: adjustPostPositions
    // 機能概要: 投稿カードが重ならないように位置を調整
    // 処理内容: 作成日時順でソートし、既存投稿と20m以上離れるよう位置を微調整
    private func adjustPostPositions() {
        adjustedPostPositions.removeAll()

        guard currentDisplayMode == .nearDistance else { return }

        let sortedPosts = posts.sorted { $0.createdAt < $1.createdAt }

        for (index, post) in sortedPosts.enumerated() {
            let originalLocation = post.location
            var adjustedLocation = originalLocation

            for i in 0..<index {
                let existingPost = sortedPosts[i]
                let existingLocation = adjustedPostPositions[existingPost.id] ?? existingPost.location

                let distance = distanceBetweenCoordinates(adjustedLocation, existingLocation)
                let minDistance = minimumCardDistance()

                if distance < minDistance {
                    adjustedLocation = findNonOverlappingPosition(
                        around: originalLocation,
                        avoiding: Array(adjustedPostPositions.values),
                        minDistance: minDistance
                    )
                    break
                }
            }

            adjustedPostPositions[post.id] = adjustedLocation
        }
    }

    // 機能名: minimumCardDistance
    // 機能概要: カード間の最小距離を返す
    // 処理内容: カードサイズ135pxに対応する約20mを返す
    private func minimumCardDistance() -> Double {
        return 20.0
    }

    // 機能名: findNonOverlappingPosition
    // 機能概要: 重複しない位置を8方向から探索
    // 処理内容: 45度ステップで8方向を試し、全て重複なら2倍距離で返す
    private func findNonOverlappingPosition(
        around center: CLLocationCoordinate2D,
        avoiding existingPositions: [CLLocationCoordinate2D],
        minDistance: Double
    ) -> CLLocationCoordinate2D {
        let offsetDistance = minDistance * 1.1
        let angleStep = 45.0

        for angle in stride(from: 0.0, to: 360.0, by: angleStep) {
            let radians = angle * .pi / 180.0
            let offsetCoord = coordinateOffset(
                from: center,
                distance: offsetDistance,
                bearing: radians
            )

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

        return coordinateOffset(from: center, distance: offsetDistance * 2, bearing: 0)
    }

    // 機能名: coordinateOffset
    // 機能概要: 指定方位・距離だけオフセットした座標を計算
    // 処理内容: 球面三角法で緯度経度をオフセットした新座標を返す
    private func coordinateOffset(
        from coordinate: CLLocationCoordinate2D,
        distance: Double,
        bearing: Double
    ) -> CLLocationCoordinate2D {
        let R = 6378137.0
        let lat1 = coordinate.latitude * .pi / 180
        let lon1 = coordinate.longitude * .pi / 180

        let lat2 = asin(sin(lat1) * cos(distance / R) + cos(lat1) * sin(distance / R) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distance / R) * cos(lat1), cos(distance / R) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(
            latitude: lat2 * 180 / .pi,
            longitude: lon2 * 180 / .pi
        )
    }

    // 機能名: getAdjustedPosition
    // 機能概要: 調整済み位置を取得（なければ元の位置）
    // 処理内容: adjustedPostPositions辞書から取得、nilなら元の位置を返す
    func getAdjustedPosition(for postId: UUID, originalLocation: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return adjustedPostPositions[postId] ?? originalLocation
    }

    //###########################################################################
    // MARK: - Opacity Management
    // 機能概要: 重なり度に応じた透明度制御
    // 処理内容: 50m範囲内の投稿数で0-1.0の透明度を計算
    //###########################################################################

    // 機能名: calculatePostOpacities
    // 機能概要: 全投稿の透明度を計算
    // 処理内容: 各投稿の周囲50m内の重なり数から透明度を算出
    private func calculatePostOpacities() {
        postOpacities.removeAll()

        for post in posts {
            let overlapCount = countOverlappingPosts(around: post.location)
            let opacity = calculateOpacity(overlapCount: overlapCount)
            postOpacities[post.id] = opacity
        }
    }

    // 機能名: countOverlappingPosts
    // 機能概要: 指定位置から50m範囲内の投稿数をカウント
    // 処理内容: filterで50m以内の投稿を抽出し、自分を除いた数を返す
    private func countOverlappingPosts(around location: CLLocationCoordinate2D) -> Int {
        let overlapRadius: Double = 50.0

        return posts.filter { post in
            let distance = distanceBetweenCoordinates(location, post.location)
            return distance <= overlapRadius
        }.count - 1
    }

    // 機能名: calculateOpacity
    // 機能概要: 重なり数から透明度を計算
    // 処理内容: 0-4枚なら1.0、5-9枚で徐々にフェード、10枚以上で0.0
    private func calculateOpacity(overlapCount: Int) -> Double {
        switch overlapCount {
        case 0...4:
            return 1.0
        case 5...9:
            let fadeProgress = Double(overlapCount - 4) / 6.0
            return max(0.0, 1.0 - fadeProgress)
        default:
            return 0.0
        }
    }

    // 機能名: getPostOpacity
    // 機能概要: 投稿IDから透明度を取得
    // 処理内容: postOpacities辞書から取得、なければ1.0を返す
    func getPostOpacity(for postId: UUID) -> Double {
        return postOpacities[postId] ?? 1.0
    }

    //###########################################################################
    // MARK: - Clustering
    // 機能概要: 遠距離モードでの投稿クラスタリング
    // 処理内容: グリッドベースでグルーピングし、PostCluster配列を生成
    //###########################################################################

    // 機能名: updateClusters
    // 機能概要: 投稿をグリッドベースでクラスタリング
    // 処理内容: ズームレベルに応じたグリッドサイズで投稿をグループ化
    func updateClusters() {
        guard currentDisplayMode == .farDistance else {
            postClusters = []
            return
        }

        let currentSpan = region.span.latitudeDelta
        let gridSize = max(0.05, currentSpan * 0.3)

        var grid: [String: [Post]] = [:]

        for post in posts {
            let gridLat = Int(post.location.latitude / gridSize)
            let gridLng = Int(post.location.longitude / gridSize)
            let gridKey = "\(gridLat),\(gridLng)"

            grid[gridKey, default: []].append(post)
        }

        postClusters = grid.values.map { PostCluster(posts: $0) }
    }

    //###########################################################################
    // MARK: - Helper Functions
    // 機能概要: 共通のユーティリティ関数
    // 処理内容: 距離計算などの汎用処理
    //###########################################################################

    // 機能名: distanceBetweenCoordinates
    // 機能概要: 2点間の距離をメートルで計算
    // 処理内容: CLLocationのdistanceメソッドを使用
    private func distanceBetweenCoordinates(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
}
