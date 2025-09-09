import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var postManager = PostManager.shared
    @StateObject private var followService = FollowService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditProfile = false
    @State private var userPosts: [Post] = []
    @State private var selectedTab = 0 // 0: 投稿, 1: フォロワー, 2: フォロー中
    
    var body: some View {
        NavigationView {
            profileContent
        }
    }
    
    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader
                
                // タブ選択
                Picker("", selection: $selectedTab) {
                    Text("投稿").tag(0)
                    Text("フォロワー").tag(1)
                    Text("フォロー中").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // コンテンツエリア
                switch selectedTab {
                case 0:
                    postsSection
                case 1:
                    followersSection
                case 2:
                    followingSection
                default:
                    EmptyView()
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(profileBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("✕") {
                    dismiss()
                }
                .font(.title2)
                .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("ログアウト", role: .destructive) {
                        Task { @MainActor in
                            do {
                                try await authManager.signOut()
                                dismiss()
                            } catch {
                                print("❌ サインアウトエラー: \(error.localizedDescription)")
                                // エラーが発生してもUIを更新して強制的にサインアウト状態にする
                                dismiss()
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadUserPosts()
        }
        .background(EmptyView())
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            profileImageButton
            userInfoSection
            statsSection
            editProfileButton
        }
        .padding(.top, 20)
        .padding(.horizontal)
    }
    
    private var profileImageButton: some View {
        // Tapping the icon should NOT change the avatar on this screen.
        // Only the Edit screen allows changing the profile photo.
        Circle()
            .fill(Color.blue)
            .frame(width: 120, height: 120)
            .overlay(profileImageContent)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            )
    }
    
    private var profileImageContent: some View {
        Group {
            if let user = authManager.currentUser {
                Text(String(user.email?.prefix(1) ?? "U").uppercased())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var userInfoSection: some View {
        VStack(spacing: 8) {
            if let user = authManager.currentUser {
                Text(user.email ?? "Unknown")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("@\((user.email?.components(separatedBy: "@").first) ?? "user")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 40) {
            Button(action: { selectedTab = 0 }) {
                statItem(title: "投稿", count: "\(userPosts.count)")
            }
            Button(action: { selectedTab = 1 }) {
                statItem(title: "フォロワー", count: "\(followService.followersCount)")
            }
            Button(action: { selectedTab = 2 }) {
                statItem(title: "フォロー中", count: "\(followService.followingCount)")
            }
        }
    }
    
    private func statItem(title: String, count: String) -> some View {
        VStack {
            Text(count)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var editProfileButton: some View {
        NavigationLink(destination: EditProfileView()) {
            Text("プロフィールを編集")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
        .padding(.horizontal, 40)
    }
    
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if userPosts.isEmpty {
                emptyPostsView
            } else {
                postsList
            }
        }
    }
    
    private var followersSection: some View {
        VStack(spacing: 12) {
            if followService.followers.isEmpty {
                Text("フォロワーはまだいません")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            } else {
                ForEach(Array(followService.followers), id: \.self) { userId in
                    UserRow(userId: userId, isFollowing: followService.isFollowing(userId))
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var followingSection: some View {
        VStack(spacing: 12) {
            if followService.following.isEmpty {
                Text("まだ誰もフォローしていません")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            } else {
                ForEach(Array(followService.following), id: \.self) { userId in
                    UserRow(userId: userId, isFollowing: true)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var emptyPostsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("まだ投稿がありません")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("地球上のどこかで最初の投稿をしてみましょう！")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    private var postsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(userPosts) { post in
                PostCard(post: post)
            }
        }
        .padding(.top, 16)
    }
    
    private var profileBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color(red: 0.05, green: 0.1, blue: 0.2),
                Color.black
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func loadUserPosts() {
        guard let userId = authManager.currentUser?.id else { return }
        
        Task {
            // データベースから実際のユーザーの投稿を取得
            let posts = await SupabaseService.shared.fetchUserPosts(userId: userId)
            await MainActor.run {
                self.userPosts = posts
            }
        }
    }
}


// EditProfileView moved to separate file
