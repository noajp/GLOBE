//======================================================================
// MARK: - MyPageViewModel.swift
// Purpose: Manages the user's profile page state and operations
// Path: GLOBE/Features/Profile/MyPageViewModel.swift
//======================================================================
import SwiftUI
import Combine
import Supabase
import CoreLocation

@MainActor
final class MyPageViewModel: ObservableObject, @unchecked Sendable {
    // MARK: - Published Properties
    
    @Published var userProfile: UserProfile?
    @Published var userPosts: [Post] = []
    @Published var postsCount: Int = 0
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var stories: [Story] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let authManager = AuthManager.shared
    private let postManager = PostManager.shared
    private let logger = DebugLogger.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private Properties
    
    private var hasLoadedInitially = false
    private var currentUserId: String? {
        // 常にSupabaseのセッションから取得
        get async {
            do {
                let session = try await supabase.auth.session
                return session.user.id.uuidString
            } catch {
                return authManager.currentUser?.id
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        Task {
            // まずプロフィールと認証情報を同期
            await syncProfileWithAuthData()
            await loadUserDataIfNeeded()
            await loadFollowedStories()
        }
        
        // Listen for post updates
        postManager.$posts
            .sink { [weak self] posts in
                guard let self = self else { return }
                Task {
                    guard let userId = await self.currentUserId else { return }
                    self.userPosts = posts.filter { $0.userId == userId }
                    self.postsCount = self.userPosts.count
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadUserDataIfNeeded() async {
        guard !hasLoadedInitially else { return }
        await loadUserData()
    }
    
    func loadUserData() async {
        guard let userId = await currentUserId else {
            logger.warning("Load user data attempted without user ID", category: "MyPageViewModel")
            return
        }
        
        logger.info("Starting to load user data", category: "MyPageViewModel", details: [
            "user_id": userId
        ])
        isLoading = true
        
        do {
            // Load profile
            let profileData = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
            
            let profiles: [UserProfile] = try JSONDecoder().decode([UserProfile].self, from: profileData.data)
            
            if let profile = profiles.first {
                userProfile = profile
                print("✅ MyPageViewModel: Profile loaded for \(profile.username)")
            } else {
                // プロフィールが存在しない場合、認証情報から作成
                print("⚠️ MyPageViewModel: Profile not found, creating from auth data...")
                await createProfileFromAuthData()
                return // createProfileFromAuthData内でloadUserDataを再帰呼び出しするため、ここで終了
            }
            
            // Load posts
            let postData = try await supabase
                .from("posts")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
            
            // Decode with ISO8601 dates and map to Post
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let dbPosts = try? decoder.decode([DatabasePost].self, from: postData.data) {
                self.userPosts = dbPosts.map { dbPost in
                    Post(
                        id: dbPost.id,
                        createdAt: dbPost.created_at,
                        location: CLLocationCoordinate2D(latitude: dbPost.latitude, longitude: dbPost.longitude),
                        locationName: dbPost.location_name,
                        imageData: nil,
                        imageUrl: dbPost.image_url,
                        text: dbPost.content,
                        authorName: (dbPost.is_anonymous ?? false) ? "匿名ユーザー" : (dbPost.profiles?.display_name ?? dbPost.profiles?.username ?? "匿名ユーザー"),
                        authorId: (dbPost.is_anonymous ?? false) ? "anonymous" : dbPost.user_id.uuidString,
                        likeCount: 0,
                        commentCount: 0,
                        isPublic: true,
                        isAnonymous: dbPost.is_anonymous ?? false
                    )
                }
            } else {
                // Fallback: decode directly to Post with ISO8601 dates
                self.userPosts = try decoder.decode([Post].self, from: postData.data)
            }
            postsCount = userPosts.count
            
            // Load follower/following counts
            let followersData = try await supabase
                .from("follows")
                .select("*", head: false, count: .exact)
                .eq("following_id", value: userId)
                .execute()
            
            followersCount = followersData.count ?? 0
            
            let followingData = try await supabase
                .from("follows")
                .select("*", head: false, count: .exact)
                .eq("follower_id", value: userId)
                .execute()
            
            followingCount = followingData.count ?? 0
            
            print("📊 Stats - Posts: \(postsCount), Followers: \(followersCount), Following: \(followingCount)")
            
            hasLoadedInitially = true
            isLoading = false
            
        } catch {
            print("❌ MyPageViewModel: Error loading user data: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// フォロー中ユーザーの最新ストーリーを取得（24時間以内の画像付き投稿）
    func loadFollowedStories(limit: Int = 20) async {
        guard let userId = await currentUserId else { return }
        do {
            // 1) フォロー中のユーザーID一覧
            let followsRes = try await supabase
                .from("follows")
                .select("following_id")
                .eq("follower_id", value: userId)
                .eq("status", value: "accepted")
                .execute()

            struct FollowRow: Decodable { let following_id: String }
            let followingRows = try JSONDecoder().decode([FollowRow].self, from: followsRes.data)
            let followingIds = followingRows.map { $0.following_id }
            guard !followingIds.isEmpty else {
                await MainActor.run { self.stories = [] }
                return
            }

            // 2) 24時間以内の画像付き投稿を取得（プロフィール名・アバター付き）
            // 注意: in() フィルタはSDKにより表記が異なるため、orクエリで代替
            let sinceISO = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-24*60*60))
            let orFilter = followingIds.map { "user_id.eq.\($0)" }.joined(separator: ",")
            let postsRes = try await supabase
                .from("posts")
                .select("id,user_id,content,image_url,created_at,profiles(display_name,username,avatar_url)")
                .or(orFilter)
                .not("image_url", operator: .is, value: "null")
                .gte("created_at", value: sinceISO)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()

            struct Row: Decodable {
                let user_id: String
                let content: String?
                let image_url: String?
                let created_at: Date
                let profiles: DatabaseProfile?
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let rows = try decoder.decode([Row].self, from: postsRes.data)

            var built: [Story] = []
            for row in rows {
                let name = row.profiles?.display_name ?? row.profiles?.username ?? "ユーザー"
                // 可能ならアバターと画像をフェッチ（失敗は無視して軽量に）
                var avatarData: Data? = nil
                if let avatar = row.profiles?.avatar_url, let url = URL(string: avatar) {
                    if let data = try? await URLSession.shared.data(from: url).0 { avatarData = data }
                }
                var imageData = Data()
                if let iu = row.image_url, let url = URL(string: iu) {
                    if let data = try? await URLSession.shared.data(from: url).0 { imageData = data }
                }
                let story = Story(
                    userId: row.user_id,
                    userName: name,
                    userAvatarData: avatarData,
                    imageData: imageData,
                    text: row.content,
                    createdAt: row.created_at
                )
                built.append(story)
            }

            await MainActor.run { self.stories = built }
        } catch {
            DebugLogger.shared.error("Failed to load followed stories: \(error.localizedDescription)", category: "MyPageViewModel")
        }
    }
    
    // MARK: - Profile Creation
    
    /// 認証情報からプロフィールを作成
    private func createProfileFromAuthData() async {
        // Supabaseのセッションから実際のユーザーIDを取得
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString
            let _ = session.user.userMetadata["username"]?.stringValue ?? 
                         session.user.email?.components(separatedBy: "@").first ?? "user"
            
            print("🔄 MyPageViewModel: Checking profile for user: \(userId)")
            
            // まずプロフィールが既に存在するか確認
            let existingProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
            
            let decoder = JSONDecoder()
            let profiles = try? decoder.decode([UserProfile].self, from: existingProfile.data)
            
            if let profile = profiles?.first {
                print("ℹ️ MyPageViewModel: Profile already exists for user: \(userId)")
                userProfile = profile
            } else {
                // プロフィールが存在しない場合、handle_new_userトリガーが作成するのを待つ
                print("⏳ MyPageViewModel: Waiting for profile to be created by database trigger...")
                
                // 少し待ってから再度確認
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
                
                let retryProfile = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .execute()
                
                let retryProfiles = try? decoder.decode([UserProfile].self, from: retryProfile.data)
                if let profile = retryProfiles?.first {
                    print("✅ MyPageViewModel: Profile found after retry")
                    userProfile = profile
                } else {
                    print("⚠️ MyPageViewModel: Profile still not found after retry")
                    errorMessage = "プロフィールの作成を待っています。しばらくしてから再度お試しください。"
                }
            }
            
            // データを再読み込み
            await loadUserData()
            
        } catch {
            print("❌ MyPageViewModel: Failed during profile check: \(error)")
            if error.localizedDescription.contains("sessionMissing") {
                errorMessage = "セッションが無効です。再度ログインしてください。"
                // AuthManagerに再認証を促す
                await authManager.checkCurrentUser()
            } else {
                errorMessage = "プロフィール取得に失敗しました: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    /// プロフィールと認証情報の整合性をチェックし、必要に応じて修正
    @MainActor
    func syncProfileWithAuthData() async {
        guard let currentUser = authManager.currentUser,
              let userId = await currentUserId else {
            print("❌ MyPageViewModel: No current user for sync")
            return
        }
        
        print("🔄 MyPageViewModel: Syncing profile with auth data")
        
        do {
            // 現在のプロフィール情報を取得
            let profileData = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
            
            let profiles: [UserProfile] = try JSONDecoder().decode([UserProfile].self, from: profileData.data)
            
            if let existingProfile = profiles.first {
                // プロフィールが存在する場合、認証情報と一致しているかチェック
                let authUsername = currentUser.username ?? currentUser.email?.components(separatedBy: "@").first ?? "user"
                
                if existingProfile.username != authUsername {
                    print("⚠️ MyPageViewModel: Username mismatch detected. Auth: \(authUsername), Profile: \(existingProfile.username)")
                    
                    // 認証情報に基づいてプロフィールを更新
                    let updateDict: [String: AnyJSON] = [
                        "username": AnyJSON.string(authUsername),
                        "display_name": AnyJSON.string(existingProfile.displayName ?? authUsername)
                    ]
                    
                    try await supabase
                        .from("profiles")
                        .update(updateDict)
                        .eq("id", value: userId)
                        .execute()
                    
                    print("✅ MyPageViewModel: Profile synced with auth username: \(authUsername)")
                    
                    // データを再読み込み
                    await loadUserData()
                }
            } else {
                // プロフィールが存在しない場合は作成
                await createProfileFromAuthData()
            }
            
        } catch {
            print("❌ MyPageViewModel: Failed to sync profile: \(error)")
        }
    }
    
    func updateProfile(username: String, displayName: String, bio: String) async {
        guard let userId = await currentUserId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 入力検証
            let validatedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            let validatedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let validatedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // ユーザー名の検証（英数字とアンダースコアのみ）
            let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
            let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
            guard usernamePredicate.evaluate(with: validatedUsername) else {
                errorMessage = "ユーザー名は3-20文字の英数字とアンダースコアのみ使用できます"
                return
            }
            
            let updatedProfile = UserProfile(
                id: userId,
                username: validatedUsername,
                displayName: validatedDisplayName.isEmpty ? validatedUsername : validatedDisplayName,
                bio: validatedBio.isEmpty ? nil : validatedBio,
                avatarUrl: userProfile?.avatarUrl,
                postCount: userProfile?.postCount,
                followerCount: userProfile?.followerCount,
                followingCount: userProfile?.followingCount
            )
            
            let updateDict: [String: AnyJSON] = [
                "username": AnyJSON.string(validatedUsername),
                "display_name": AnyJSON.string(validatedDisplayName.isEmpty ? validatedUsername : validatedDisplayName),
                "bio": validatedBio.isEmpty ? AnyJSON.null : AnyJSON.string(validatedBio),
                "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ]
            
            try await supabase
                .from("profiles")
                .update(updateDict)
                .eq("id", value: userId)
                .execute()
            
            userProfile = updatedProfile
            logger.info("Profile updated successfully", category: "MyPageViewModel", details: [
                "username": validatedUsername,
                "displayName": validatedDisplayName
            ])
            
        } catch {
            logger.error("Failed to update profile", category: "MyPageViewModel", details: [
                "error": error.localizedDescription
            ])
            errorMessage = "プロフィールの更新に失敗しました: \(error.localizedDescription)"
        }
    }
    
    func deletePost(_ post: Post) async {
        do {
            try await supabase
                .from("posts")
                .delete()
                .eq("id", value: post.id.uuidString)
                .execute()
            
            await loadUserData() // Reload all data
            
        } catch {
            print("❌ Error deleting post: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}
