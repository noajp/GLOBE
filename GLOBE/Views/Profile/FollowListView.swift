//======================================================================
// MARK: - FollowListView.swift
// Purpose: Display followers or following list for a user
// Path: GLOBE/Views/Profile/FollowListView.swift
//======================================================================
import SwiftUI
import Combine

enum FollowListType {
    case followers
    case following

    var title: String {
        switch self {
        case .followers:
            return "Followers"
        case .following:
            return "Following"
        }
    }
}

struct FollowListView: View {
    let userId: String
    let listType: FollowListType

    @StateObject private var viewModel = FollowListViewModel()
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // User List
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(MinimalDesign.Colors.primary)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(MinimalDesign.Colors.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.users.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: listType == .followers ? "person.crop.circle" : "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(MinimalDesign.Colors.tertiary)
                    Text("No \(listType.title.lowercased()) yet")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(MinimalDesign.Colors.primary)
                    Text(listType == .followers ? "When people follow this account, they'll appear here." : "When this account follows people, they'll appear here.")
                        .font(.body)
                        .foregroundColor(MinimalDesign.Colors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.users, id: \.id) { user in
                            FollowUserRow(user: user, initialFollowState: listType == .following)

                            if user.id != viewModel.users.last?.id {
                                Divider()
                                    .background(MinimalDesign.Colors.border)
                                    .padding(.leading, 70)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .background(MinimalDesign.Colors.background)
        .navigationTitle(listType.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadUsers(userId: userId, listType: listType)
            }
        }
        .refreshable {
            await viewModel.loadUsers(userId: userId, listType: listType)
        }
    }
}

// MARK: - Follow User Row
struct FollowUserRow: View {
    let user: UserProfile
    let initialFollowState: Bool // Track if this user should initially be shown as following

    @State private var isFollowing = false
    @State private var isLoading = false
    @State private var hasCheckedFollowStatus = false
    @StateObject private var authManager = AuthManager.shared

    private var isCurrentUser: Bool {
        user.id.lowercased() == authManager.currentUser?.id.lowercased()
    }

    init(user: UserProfile, initialFollowState: Bool = false) {
        self.user = user
        self.initialFollowState = initialFollowState
        _isFollowing = State(initialValue: initialFollowState)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Profile Avatar
            Circle()
                .fill(MinimalDesign.Colors.secondaryBackground)
                .frame(width: 50, height: 50)
                .overlay(
                    Group {
                        if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Text(user.displayName?.prefix(1).uppercased() ?? "?")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(MinimalDesign.Colors.tertiary)
                        }
                    }
                )

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                if let displayName = user.displayName {
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.primary)
                        .lineLimit(1)
                }

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Follow Button (only for other users)
            if !isCurrentUser {
                Button(action: { toggleFollow() }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: isFollowing ? MinimalDesign.Colors.primary : .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(isFollowing ? "Following" : "Follow")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(isFollowing ? MinimalDesign.Colors.primary : .white)
                    .frame(width: 90, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isFollowing ? Color.clear : Color(red: 0.0, green: 0.55, blue: 0.75))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isFollowing ? MinimalDesign.Colors.border : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MinimalDesign.Colors.background)
        .onAppear {
            if !isCurrentUser && !hasCheckedFollowStatus {
                checkFollowStatus()
            }
        }
    }

    private func checkFollowStatus() {
        Task {
            isFollowing = await SupabaseService.shared.isFollowing(userId: user.id)
            hasCheckedFollowStatus = true
        }
    }

    private func toggleFollow() {
        isLoading = true
        Task {
            if isFollowing {
                _ = await SupabaseService.shared.unfollowUser(userId: user.id)
            } else {
                _ = await SupabaseService.shared.followUser(userId: user.id)
            }
            checkFollowStatus() // Re-check status after action
            isLoading = false
        }
    }
}

// MARK: - ViewModel
@MainActor
class FollowListViewModel: ObservableObject {
    @Published var users: [UserProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadUsers(userId: String, listType: FollowListType) async {
        isLoading = true
        errorMessage = nil

        switch listType {
        case .followers:
            users = await SupabaseService.shared.getFollowers(userId: userId)
        case .following:
            users = await SupabaseService.shared.getFollowing(userId: userId)
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        FollowListView(userId: "test-user-id", listType: .followers)
    }
}
