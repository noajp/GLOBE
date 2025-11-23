//======================================================================
// MARK: - NotificationListView.swift
// Purpose: Display notifications (likes, comments, follows)
// Path: GLOBE/Views/Notifications/NotificationListView.swift
//======================================================================

import SwiftUI
import Combine

struct NotificationListView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0)
                .ignoresSafeArea()

            // Content
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Text("Loading notifications...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.notifications.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.5))

                    Text("No Notifications")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    Text("When someone likes, comments, or follows you, you'll see it here.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRowView(notification: notification)

                            if notification.id != viewModel.notifications.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                    .padding(.leading, 70)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadNotifications()
            }
        }
        .refreshable {
            await viewModel.loadNotifications()
        }
    }
}

// MARK: - Notification Row
struct NotificationRowView: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: notification.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(notification.timeAgo)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(notification.isRead ? Color.clear : Color.white.opacity(0.05))
    }
}

// MARK: - Notification Model
struct AppNotification: Identifiable {
    let id: String
    let type: NotificationType
    let actorName: String
    let actorId: String
    let actorAvatarUrl: String?
    let postId: String?
    let createdAt: Date
    let isRead: Bool

    var message: String {
        switch type {
        case .follow:
            return "\(actorName) started following you"
        case .like:
            return "\(actorName) liked your post"
        case .comment:
            return "\(actorName) commented on your post"
        }
    }

    var iconName: String {
        switch type {
        case .follow:
            return "person.fill.badge.plus"
        case .like:
            return "heart.fill"
        case .comment:
            return "bubble.right.fill"
        }
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

enum NotificationType: String, Codable {
    case follow
    case like
    case comment
}

// MARK: - ViewModel
@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadNotifications() async {
        isLoading = true
        errorMessage = nil

        // Load from Supabase
        notifications = await SupabaseService.shared.getNotifications()

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        NotificationListView()
    }
}
