import Foundation
import MapKit
import Combine

class MapManager: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // 東京
        span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0) // 日本周辺表示
    )
    @Published var posts: [Post] = []
    private var cleanupTimer: Timer?
    private let postManager = PostManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        startCleanupTimer()
        setupPostSubscription()
        
        // 初期データの読み込み
        Task {
            await postManager.fetchPosts()
        }
    }
    
    private func setupPostSubscription() {
        // PostManager からの投稿データを監視
        postManager.$posts
            .receive(on: DispatchQueue.main)
            .assign(to: \.posts, on: self)
            .store(in: &cancellables)
    }
    
    func focusOnLocation(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
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