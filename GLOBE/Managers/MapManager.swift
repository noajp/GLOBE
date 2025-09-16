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
    
    func focusOnLocation(_ coordinate: CLLocationCoordinate2D) {
        print("🗺🔥 MapManager: focusOnLocation called with coordinate: \(coordinate)")
        print("🗺🔥 MapManager: Current region center: \(region.center)")
        
        let newRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003) // より拡大（約300m範囲）
        )
        
        // Update the legacy region property
        region = newRegion
        
        // Trigger map position update for modern Map view - 記事.txtの手法を参考
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.shouldUpdateMapPosition = MapCameraPosition.region(newRegion)
            }
            // 記事.txtのように明示的にobjectWillChange.send()を呼び出し
            self.objectWillChange.send()
        }
        
        print("🗺🔥 MapManager: Updated region center: \(region.center)")
        print("🗺🔥 MapManager: Region span: \(region.span)")
        print("🗺🔥 MapManager: Triggered map position update with objectWillChange")
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
    
    deinit {
        cleanupTimer?.invalidate()
    }
}
