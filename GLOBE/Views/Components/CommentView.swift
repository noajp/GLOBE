//======================================================================
// MARK: - CommentView.swift
// Purpose: Comment view for displaying and adding comments to posts
// Path: GLOBE/Views/Components/CommentView.swift
//======================================================================

import SwiftUI
import CoreLocation

struct CommentView: View {
    let post: Post
    @EnvironmentObject var commentService: CommentService
    @EnvironmentObject var authManager: AuthManager
    @State private var newCommentText = ""
    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header with drag indicator area
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Header
            HStack {
                Button("キャンセル") {
                    dismiss()
                }

                Spacer()

                Text("コメント")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Placeholder for balance
                Button("") { }
                    .opacity(0)
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            // Original post summary
            postSummaryView

            Divider()

            // Comments list
            commentsList

            Divider()

            // Comment input
            commentInputView
        }
        .background(Color(.systemBackground))
    }

    private var postSummaryView: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(post.authorName.prefix(1)))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(post.authorName)
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()

                    Text(timeAgoText(from: post.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(post.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding()
    }

    private var commentsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                let comments = commentService.getComments(for: post.id)

                if comments.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)

                        Text("まだコメントがありません")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        Text("最初のコメントを投稿してみましょう")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ForEach(comments) { comment in
                        commentRow(comment: comment)
                    }
                }
            }
            .padding()
        }
    }

    private func commentRow(comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(comment.authorName.prefix(1)))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.system(size: 13, weight: .semibold))

                    Spacer()

                    Text(timeAgoText(from: comment.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
    }

    private var commentInputView: some View {
        HStack(spacing: 12) {
            // User avatar
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String((authManager.currentUser?.email ?? "U").prefix(1).uppercased()))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                )

            TextField("コメントを追加...", text: $newCommentText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button(action: submitComment) {
                Text("投稿")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(canSubmit ? .blue : .gray)
            }
            .disabled(!canSubmit || isSubmitting)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var canSubmit: Bool {
        !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitComment() {
        guard canSubmit, !isSubmitting else { return }

        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        isSubmitting = true

        Task {
            do {
                try await commentService.addComment(
                    to: post.id,
                    content: trimmedText,
                    authorId: authManager.currentUser?.id ?? UUID().uuidString,
                    authorName: authManager.currentUser?.email ?? "Anonymous"
                )

                await MainActor.run {
                    newCommentText = ""
                    isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    // TODO: Show error alert
                }
            }
        }
    }

    private func timeAgoText(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 60 {
            return "たった今"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)時間前"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)日前"
        }
    }
}

#Preview {
    CommentView(post: Post(
        id: UUID(),
        createdAt: Date(),
        expiresAt: nil,
        location: CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125),
        locationName: "東京都",
        imageData: nil,
        imageUrl: nil,
        text: "サンプルの投稿です。これはコメント機能のプレビューです。",
        authorName: "テストユーザー",
        authorId: UUID().uuidString,
        likeCount: 0,
        commentCount: 0,
        isPublic: true,
        isAnonymous: false,
        authorAvatarUrl: nil
    ))
}