import Foundation
import Combine

// フォロー関係のモデル
struct Follow: Identifiable, Codable {
    let id: String
    let followerId: String      // フォローする人
    let followingId: String     // フォローされる人
    let createdAt: Date
    
    init(followerId: String, followingId: String) {
        self.id = UUID().uuidString
        self.followerId = followerId
        self.followingId = followingId
        self.createdAt = Date()
    }
}

// フォロー管理サービス
@MainActor
class FollowService: ObservableObject {
    static let shared = FollowService()
    
    @Published var followers: Set<String> = []     // フォロワーのIDセット
    @Published var following: Set<String> = []     // フォロー中のIDセット
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    
    private init() {
        // 開発中はモックデータを設定
        #if DEBUG
        loadMockData()
        #endif
    }
    
    private func loadMockData() {
        // モックフォロワー
        followers = ["user2", "user3", "user4"]
        followersCount = followers.count
        
        // モックフォロー中
        following = ["user2", "user5", "user6"]
        followingCount = following.count
    }
    
    // 指定ユーザーをフォローしているか
    func isFollowing(_ userId: String) -> Bool {
        return following.contains(userId)
    }
    
    // フォロー/アンフォローのトグル
    func toggleFollow(_ userId: String) async {
        if isFollowing(userId) {
            await unfollowUser(userId)
        } else {
            await followUser(userId)
        }
    }
    
    // フォロー
    func followUser(_ userId: String) async {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return }
        guard currentUserId != userId else { return } // 自分自身はフォローできない
        
        following.insert(userId)
        followingCount = following.count
        
        // TODO: Supabaseに保存
        print("✅ Followed user: \(userId)")
    }
    
    // アンフォロー
    func unfollowUser(_ userId: String) async {
        following.remove(userId)
        followingCount = following.count
        
        // TODO: Supabaseから削除
        print("❌ Unfollowed user: \(userId)")
    }
    
    // フォロワーを取得
    func fetchFollowers(for userId: String) async {
        // TODO: Supabaseから取得
        // 現在はモックデータを使用
    }
    
    // フォロー中のユーザーを取得
    func fetchFollowing(for userId: String) async {
        // TODO: Supabaseから取得
        // 現在はモックデータを使用
    }
}