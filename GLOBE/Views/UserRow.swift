import SwiftUI

struct UserRow: View {
    let userId: String
    let isFollowing: Bool
    @StateObject private var followService = FollowService.shared
    @State private var isLoading = false
    
    // モックユーザーデータ（実際はSupabaseから取得）
    private var userName: String {
        switch userId {
        case "user2": return "田中太郎"
        case "user3": return "John Doe"
        case "user4": return "Marie"
        case "user5": return "山田花子"
        case "user6": return "Alice"
        default: return "User \(userId.suffix(1))"
        }
    }
    
    private var userHandle: String {
        switch userId {
        case "user2": return "@tanaka"
        case "user3": return "@john"
        case "user4": return "@marie"
        case "user5": return "@yamada"
        case "user6": return "@alice"
        default: return "@user\(userId.suffix(1))"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // プロフィール画像
            Circle()
                .fill(Color.blue.opacity(0.8))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(userName.prefix(1)))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            // ユーザー情報
            VStack(alignment: .leading, spacing: 2) {
                Text(userName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(userHandle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // フォロー/アンフォローボタン
            Button(action: {
                Task {
                    isLoading = true
                    await followService.toggleFollow(userId)
                    isLoading = false
                }
            }) {
                Text(isFollowing ? "フォロー中" : "フォロー")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isFollowing ? .white : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isFollowing ? Color.gray.opacity(0.3) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isFollowing ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.6 : 1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    VStack {
        UserRow(userId: "user2", isFollowing: true)
        UserRow(userId: "user3", isFollowing: false)
    }
    .padding()
    .background(Color.black)
}