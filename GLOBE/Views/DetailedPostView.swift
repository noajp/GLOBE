//======================================================================
// MARK: - DetailedPostView.swift
// Purpose: Full-screen detailed view of a post with comments and interactions
// Path: GLOBE/Views/DetailedPostView.swift
//======================================================================

import SwiftUI
import MapKit

struct DetailedPostView: View {
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    let post: Post
    @Binding var isPresented: Bool
    @StateObject private var commentService = CommentService.shared
    @StateObject private var likeService = LikeService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingUserProfile = false
    @State private var newCommentText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Post Header
                    HStack(spacing: 12) {
                        // Profile icon - tappable
                        Button(action: {
                            showingUserProfile = true
                        }) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(post.authorName.prefix(1).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            // Username - tappable
                            Button(action: {
                                showingUserProfile = true
                            }) {
                                Text(post.authorName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Location
                            if let locationName = post.locationName {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text(locationName)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(customBlack)
                    
                    // Image if available
                    if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .background(customBlack)
                    }
                    
                    // Post text
                    if !post.text.isEmpty {
                        HStack {
                            Text(post.text)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding()
                        .background(customBlack)
                    }
                    
                    // Like and Comment actions
                    HStack(spacing: 20) {
                        // Like button
                        Button(action: {
                            if let userId = authManager.currentUser?.id {
                                let newLikeState = likeService.toggleLike(for: post, userId: userId)
                                if newLikeState {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: likeService.isLiked(post.id) ? "heart.fill" : "heart")
                                    .font(.system(size: 20))
                                    .foregroundColor(likeService.isLiked(post.id) ? .red : .white)
                                
                                let likeCount = likeService.getLikeCount(for: post.id)
                                if likeCount > 0 {
                                    Text("\(likeCount)")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Comment indicator
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            let commentCount = commentService.getCommentCount(for: post.id)
                            Text("\(commentCount)")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(customBlack)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Comments section
                    LazyVStack(spacing: 12) {
                        ForEach(commentService.getComments(for: post.id)) { comment in
                            CommentRow(comment: comment)
                                .padding(.horizontal)
                        }
                        
                        if commentService.getComments(for: post.id).isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("まだコメントがありません")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 40)
                        }
                    }
                    .padding(.top)
                    .background(customBlack)
                    
                    // Bottom padding for comment input
                    Color.clear.frame(height: 80)
                }
            }
            .background(customBlack)
            .navigationBarHidden(true)
            .overlay(
                // Fixed comment input at bottom
                VStack {
                    Spacer()
                    
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
                        .background(customBlack)
                    }
                }
            )
        }
        .onAppear {
            commentService.loadComments(for: post.id)
            likeService.initializePost(post)
        }
        .sheet(isPresented: $showingUserProfile) {
            UserProfileView(
                userName: post.authorName,
                userId: post.authorId,
                isPresented: $showingUserProfile
            )
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
        
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}



#Preview {
    let samplePost = Post(
        location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        locationName: "東京タワー",
        text: "美しい景色！",
        authorName: "Sample User",
        authorId: "sample-user-id",
        likeCount: 10,
        commentCount: 5
    )
    
    DetailedPostView(
        post: samplePost,
        isPresented: .constant(true)
    )
}