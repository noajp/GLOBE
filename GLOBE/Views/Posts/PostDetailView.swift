import SwiftUI
import MapKit

struct PostDetailView: View {
    let post: Post
    @Binding var isPresented: Bool
    @StateObject private var postManager = PostManager.shared
    @StateObject private var authManager = AuthManager.shared
    @State private var hasLiked = false
    @State private var likesCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
                // ヘッダー
                HStack {
                    Button("✕") {
                        isPresented = false
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    // 投稿者が自分の場合、削除ボタン
                    if post.authorId == authManager.currentUser?.id {
                        Button(action: {
                            Task {
                                await deletePost()
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                // 投稿画像（フルサイズ表示）
                if let imageData = post.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(0)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // ユーザー情報とアクション
                    HStack {
                        // ユーザー情報
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(post.authorName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                            }
                        }
                        
                        Spacer()
                        
                        // アクションボタン
                        HStack(spacing: 16) {
                            // いいねボタン
                            Button(action: {
                                Task {
                                    await toggleLike()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: hasLiked ? "heart.fill" : "heart")
                                        .foregroundColor(hasLiked ? .red : .gray)
                                    Text("\(likesCount)")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            
                            // 共有ボタン
                            Button(action: {
                                sharePost()
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // 投稿キャプション（写真投稿の場合は大きく表示）
                    if !post.text.isEmpty {
                        Text(post.text)
                            .font(post.imageData != nil ? .title3 : .body)
                            .fontWeight(post.imageData != nil ? .medium : .regular)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // 位置情報
                    if let locationName = post.locationName {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Text(locationName)
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                    }
                    
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        .frame(maxWidth: 350)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .onAppear {
            loadPostStats()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadPostStats() {
        likesCount = Int.random(in: 0...50)
        hasLiked = false
    }
    
    private func toggleLike() async {
        guard authManager.isAuthenticated else { return }

        hasLiked.toggle()
        likesCount += hasLiked ? 1 : -1
    }
    
    private func sharePost() {
        // 投稿内容を共有
        let shareText = "\(post.authorName)の投稿: \(post.text)\n\n位置: \(post.latitude), \(post.longitude)\n\n#GLOBE"
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func deletePost() async {
        guard authManager.isAuthenticated,
              post.authorId == authManager.currentUser?.id else { return }

        postManager.posts.removeAll { $0.id == post.id }
        isPresented = false
    }
}

#Preview {
    let samplePost = Post(
        location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        locationName: "東京タワー",
        text: "素晴らしい投稿です！",
        authorName: "Sample User",
        authorId: "sample-user-id",
        likeCount: 15,
        commentCount: 8
    )
    
    PostDetailView(
        post: samplePost,
        isPresented: .constant(true)
    )
}