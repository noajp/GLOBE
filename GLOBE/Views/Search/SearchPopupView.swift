//======================================================================
// MARK: - SearchPopupView.swift
// Function: User Search Popup View
// Overview: Glass effect search popup with user search functionality
// Processing: Delegate search to SearchViewModel (MVVM compliant)
//======================================================================

import SwiftUI

struct SearchPopupView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedUserId: String?
    @State private var showUserProfile = false
    @State private var dragOffset: CGFloat = 0
    @State private var isExpanded = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Rectangular popup card with glass effect
                GlassEffectContainer {
                    VStack(spacing: 0) {
                        // Drag handle
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 40, height: 5)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                        // Search header
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                            TextField("Search users...", text: $viewModel.searchQuery)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .tint(.white)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onChange(of: viewModel.searchQuery) { _, newValue in
                                    viewModel.performSearch(query: newValue)
                                }
                                .colorScheme(.dark)

                            if !viewModel.searchQuery.isEmpty {
                                Button(action: {
                                    viewModel.searchQuery = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }

                            // Close button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 28, height: 28)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.05))

                        Divider()
                            .background(Color.white.opacity(0.2))

                        // Search results
                        if viewModel.isSearching {
                            VStack {
                                Spacer()
                                ProgressView()
                                    .tint(.white)
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.top, 8)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        } else if viewModel.searchQuery.isEmpty {
                            VStack(spacing: 12) {
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.3))

                                Text("Search for users")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)

                                Text("Find people to follow and connect with")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                Spacer()
                            }
                        } else if viewModel.searchResults.isEmpty {
                            VStack(spacing: 12) {
                                Spacer()
                                Image(systemName: "person.slash")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.3))

                                Text("No users found")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)

                                Text("Try searching with a different name")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(viewModel.searchResults) { user in
                                        Button(action: {
                                            selectedUserId = user.id
                                            showUserProfile = true
                                        }) {
                                            SearchResultRow(user: user)
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        if user.id != viewModel.searchResults.last?.id {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                                .padding(.leading, 70)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: isExpanded ? geometry.size.height - 60 : 370)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -5)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .offset(y: isExpanded ? 0 : dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow upward drag
                            if value.translation.height < 0 {
                                dragOffset = value.translation.height
                            } else if value.translation.height > 0 && isExpanded {
                                // Allow downward drag when expanded
                                dragOffset = value.translation.height
                            } else if value.translation.height > 50 {
                                // Drag down to close
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if value.translation.height < -100 {
                                    // Expand to full screen
                                    isExpanded = true
                                    dragOffset = 0
                                } else if value.translation.height > 100 {
                                    // Close
                                    if isExpanded {
                                        isExpanded = false
                                        dragOffset = 0
                                    } else {
                                        isPresented = false
                                    }
                                } else {
                                    // Return to original position
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
        .fullScreenCover(isPresented: $showUserProfile) {
            if let userId = selectedUserId {
                UserProfileView(
                    userName: viewModel.searchResults.first(where: { $0.id == userId })?.displayName ?? "User",
                    userId: userId,
                    isPresented: $showUserProfile
                )
            }
        }
    }

}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let user: UserProfile
    @State private var isFollowing = false
    @State private var isLoading = false
    @StateObject private var authManager = AuthManager.shared

    init(user: UserProfile) {
        self.user = user
        SecureLogger.shared.info("SearchResultRow: Initialized for user: \(user.displayName ?? "Unknown") (id: \(user.id))")
    }

    var body: some View {
        let _ = SecureLogger.shared.info("SearchResultRow: Rendering body for user: \(user.displayName ?? "Unknown"), isFollowing: \(isFollowing)")

        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.displayName?.prefix(1).uppercased() ?? "U")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                )

            // User info with Follow button on the right
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName ?? "Unknown User")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    if let username = user.username {
                        Text("@\(username)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Follow button (aligned with display name)
                Button(action: {
                    SecureLogger.shared.info("SearchResultRow: Follow button tapped")
                    Task {
                        await toggleFollow()
                    }
                }) {
                    let buttonText = isFollowing ? "Following" : "Follow"
                    let _ = SecureLogger.shared.info("SearchResultRow: Button text = \(buttonText)")

                    HStack(spacing: 4) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                        } else {
                            Text(buttonText)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 28)
                    .background(isFollowing ? Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0) : Color(red: 0.0, green: 0.55, blue: 0.75))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            SecureLogger.shared.info("SearchResultRow: onAppear called for user: \(user.id)")
            Task {
                await checkFollowStatus()
            }
        }
    }

    private func checkFollowStatus() async {
        isLoading = true
        SecureLogger.shared.info("SearchResultRow: Checking follow status for userId: \(user.id)")
        let status = await SupabaseService.shared.isFollowing(userId: user.id)
        SecureLogger.shared.info("SearchResultRow: Follow status result: \(status)")
        await MainActor.run {
            isFollowing = status
            isLoading = false
            SecureLogger.shared.info("SearchResultRow: UI updated - isFollowing: \(isFollowing)")
        }
    }

    private func toggleFollow() async {
        isLoading = true
        SecureLogger.shared.info("SearchResultRow: toggleFollow called - current state: \(isFollowing ? "Following" : "Not Following")")

        if isFollowing {
            SecureLogger.shared.info("SearchResultRow: Attempting to unfollow user: \(user.id)")
            let success = await SupabaseService.shared.unfollowUser(userId: user.id)
            SecureLogger.shared.info("SearchResultRow: Unfollow result: \(success)")
            if success {
                await MainActor.run {
                    isFollowing = false
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        } else {
            SecureLogger.shared.info("SearchResultRow: Attempting to follow user: \(user.id)")
            let success = await SupabaseService.shared.followUser(userId: user.id)
            SecureLogger.shared.info("SearchResultRow: Follow result: \(success)")
            if success {
                await MainActor.run {
                    isFollowing = true
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }

        // Re-check follow status to ensure UI is in sync
        SecureLogger.shared.info("SearchResultRow: Re-checking follow status after toggle")
        await checkFollowStatus()
    }
}

#Preview {
    ZStack {
        // Map background
        Color.blue.opacity(0.3)
            .ignoresSafeArea()

        SearchPopupView(isPresented: .constant(true))
    }
    .glassContainer()
}
