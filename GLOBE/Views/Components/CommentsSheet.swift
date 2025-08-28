//======================================================================
// MARK: - CommentsSheet.swift
// Purpose: Comments sheet view for displaying and adding comments to posts
// Path: GLOBE/Views/Components/CommentsSheet.swift
//======================================================================

import SwiftUI
import CoreLocation

struct CommentsSheet: View {
    let post: Post
    @Binding var isPresented: Bool
    @StateObject private var commentService = CommentService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var newCommentText = ""
    @State private var isComposingComment = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                // Half-screen comment popup
                VStack(spacing: 0) {
                    // Header with drag indicator
                    VStack(spacing: 8) {
                        // Drag indicator
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 40, height: 6)
                        
                        HStack {
                            Button("閉じる") {
                                isPresented = false
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("コメント")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Placeholder for balance
                            Text("")
                                .font(.subheadline)
                                .opacity(0)
                        }
                    }
                    .padding()
                    .background(Color.black)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Comments list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(commentService.getComments(for: post.id)) { comment in
                                CommentRow(comment: comment)
                            }
                            
                            if commentService.getComments(for: post.id).isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "bubble.left")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                    
                                    Text("まだコメントがありません")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text("最初のコメントを投稿してみましょう！")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .padding(.top, 40)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    .background(Color.black)
                    
                    // Comment input area
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        HStack(spacing: 12) {
                            // Profile icon
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(authManager.currentUser?.email?.prefix(1).uppercased() ?? "?")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                            
                            // Text input
                            TextField("コメントを追加...", text: $newCommentText, axis: .vertical)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .lineLimit(1...3)
                                .textFieldStyle(PlainTextFieldStyle())
                                .onTapGesture {
                                    isComposingComment = true
                                }
                            
                            // Send button
                            Button(action: {
                                addComment()
                            }) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(newCommentText.isEmpty ? .gray : .blue)
                            }
                            .disabled(newCommentText.isEmpty)
                        }
                        .padding()
                        .background(Color.black)
                    }
                }
                .frame(height: geometry.size.height * 0.5)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
            }
        }
        .background(Color.clear)
        .onAppear {
            commentService.loadComments(for: post.id)
        }
    }
    
    private func addComment() {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let user = authManager.currentUser else { return }
        
        let comment = Comment(
            postId: post.id,
            text: newCommentText.trimmingCharacters(in: .whitespacesAndNewlines),
            authorName: user.email?.components(separatedBy: "@").first ?? "匿名ユーザー",
            authorId: user.id
        )
        
        commentService.addComment(comment)
        newCommentText = ""
        isComposingComment = false
        
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Profile icon
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(comment.authorName.prefix(1).uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Username and time
                HStack {
                    Text(comment.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timeAgoString(from: comment.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Comment text
                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "今"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)時間"
        } else {
            let days = Int(interval / 86400)
            return "\(days)日"
        }
    }
}

#Preview {
    let samplePost = Post(
        location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        locationName: "東京タワー",
        text: "美しい景色！",
        authorName: "Sample User",
        authorId: "sample-user-id",
        likeCount: 5,
        commentCount: 3
    )
    
    CommentsSheet(
        post: samplePost,
        isPresented: .constant(true)
    )
}