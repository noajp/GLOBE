import SwiftUI

struct StoriesView: View {
    let stories: [Story]
    let onCreatePost: () -> Void
    @State private var selectedStory: Story?
    @State private var showingStoryDetail = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 投稿追加ボタン
                Button(action: {
                    onCreatePost()
                }) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
                
                // フォロー中のユーザーのストーリー
                ForEach(stories.filter { !$0.isExpired }) { story in
                    Button(action: {
                        selectedStory = story
                        showingStoryDetail = true
                    }) {
                        ZStack {
                            // ストーリーがある場合のリング
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.pink, .orange, .yellow]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: 66, height: 66)
                            
                            // ユーザーアバター
                            if let avatarData = story.userAvatarData,
                               let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text(String(story.userName.prefix(1)))
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showingStoryDetail) {
            if let selectedStory = selectedStory {
                StoryDetailView(story: selectedStory, isPresented: $showingStoryDetail)
            }
        }
    }
}

struct StoryDetailView: View {
    let story: Story
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // ヘッダー
                HStack {
                    // ユーザー情報
                    HStack {
                        if let avatarData = story.userAvatarData,
                           let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(story.userName.prefix(1)))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                )
                        }
                        
                        VStack(alignment: .leading) {
                            Text(story.userName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text(formatTimeAgo(story.createdAt))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button("✕") {
                        isPresented = false
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                }
                .padding()
                
                // ストーリー画像
                if let uiImage = UIImage(data: story.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal)
                } else {
                    // モック画像の場合
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray)
                        .frame(height: 400)
                        .overlay(
                            Text("📸")
                                .font(.system(size: 60))
                        )
                        .padding(.horizontal)
                }
                
                // キャプション
                if let text = story.text {
                    Text(text)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
        }
        .onTapGesture {
            isPresented = false
        }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分前"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)時間前"
        }
    }
}

#Preview {
    StoriesView(stories: Story.mockStories) {
        // Preview用の空の実装
    }
}