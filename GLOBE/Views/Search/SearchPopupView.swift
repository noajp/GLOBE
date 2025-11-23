//======================================================================
// MARK: - SearchPopupView.swift
// Purpose: Glass effect search popup for user search
// Path: GLOBE/Views/Search/SearchPopupView.swift
//======================================================================

import SwiftUI

struct SearchPopupView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var searchResults: [UserProfile] = []
    @State private var isSearching = false
    @StateObject private var authManager = AuthManager.shared
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

                            TextField("Search users...", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .tint(.white)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onChange(of: searchText) { _, newValue in
                                    performSearch(query: newValue)
                                }
                                .colorScheme(.dark)

                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults = []
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
                        if isSearching {
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
                        } else if searchText.isEmpty {
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
                        } else if searchResults.isEmpty {
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
                                    ForEach(searchResults) { user in
                                        SearchResultRow(user: user)
                                            .onTapGesture {
                                                selectedUserId = user.id
                                                showUserProfile = true
                                            }

                                        if user.id != searchResults.last?.id {
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
            .sheet(isPresented: $showUserProfile) {
                if let userId = selectedUserId {
                    UserProfileView(
                        userName: searchResults.first(where: { $0.id == userId })?.displayName ?? "User",
                        userId: userId,
                        isPresented: $showUserProfile
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
    }

    // MARK: - Search Function
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        Task {
            do {
                let results = await SupabaseService.shared.searchUsers(query: query)

                await MainActor.run {
                    // Filter out current user from results
                    if let currentUserId = authManager.currentUser?.id {
                        searchResults = results.filter { $0.id.lowercased() != currentUserId.lowercased() }
                    } else {
                        searchResults = results
                    }
                    isSearching = false
                }
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

    var body: some View {
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

            // User info
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

            Spacer()

            // Follow button
            Button(action: {
                Task {
                    await toggleFollow()
                }
            }) {
                HStack(spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.7)
                    } else {
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundColor(isFollowing ? .white : .white)
                .frame(width: 90, height: 28)
                .background(isFollowing ? Color.white.opacity(0.15) : Color(red: 0.0, green: 0.55, blue: 0.75))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isFollowing ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            Task {
                await checkFollowStatus()
            }
        }
    }

    private func checkFollowStatus() async {
        isLoading = true
        let status = await SupabaseService.shared.isFollowing(userId: user.id)
        await MainActor.run {
            isFollowing = status
            isLoading = false
        }
    }

    private func toggleFollow() async {
        isLoading = true

        if isFollowing {
            let success = await SupabaseService.shared.unfollowUser(userId: user.id)
            await MainActor.run {
                if success {
                    isFollowing = false
                }
                isLoading = false
            }
        } else {
            let success = await SupabaseService.shared.followUser(userId: user.id)
            await MainActor.run {
                if success {
                    isFollowing = true
                }
                isLoading = false
            }
        }
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
