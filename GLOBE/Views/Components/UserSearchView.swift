//======================================================================
// MARK: - UserSearchView.swift
// Purpose: User search interface for finding and following other users
// Path: GLOBE/Views/UserSearchView.swift
//======================================================================
import SwiftUI

struct UserSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var searchText = ""
    @State private var searchResults: [UserProfile] = []
    @State private var isSearching = false
    @State private var searchError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Unified header
            UnifiedHeader(
                title: "SEARCH USERS",
                showBackButton: true,
                onBack: { dismiss() }
            )
            .padding(.top)
            
            VStack(spacing: MinimalDesign.Spacing.md) {
                // Search field
                searchField
                
                Divider()
                    .padding(.horizontal, MinimalDesign.Spacing.md)
                
                // Search results area
                searchResultsArea
                
                Spacer()
            }
            .padding(.top, MinimalDesign.Spacing.md)
        }
        .background(MinimalDesign.Colors.background)
        .navigationBarHidden(true)
    }
    
    // MARK: - Search Field
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(MinimalDesign.Colors.primary)
                .font(.system(size: 16))
            
            TextField("Search by username", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .foregroundColor(MinimalDesign.Colors.primary)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit {
                    searchUsers()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(MinimalDesign.Colors.tertiary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(25)
        .padding(.horizontal, MinimalDesign.Spacing.md)
    }
    
    // MARK: - Search Results Area
    private var searchResultsArea: some View {
        VStack {
            if searchText.isEmpty && searchResults.isEmpty {
                emptyStateView
            } else if isSearching {
                loadingView
            } else if let error = searchError {
                errorView(error: error)
            } else if searchResults.isEmpty && !searchText.isEmpty {
                noResultsView
            } else {
                searchResultsList
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(MinimalDesign.Colors.tertiary)
            Text("Search for users")
                .font(.headline)
                .foregroundColor(MinimalDesign.Colors.primary)
            Text("Enter a username to find\nother users")
                .font(.caption)
                .foregroundColor(MinimalDesign.Colors.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MinimalDesign.Colors.primary))
            Text("Searching...")
                .foregroundColor(MinimalDesign.Colors.secondary)
                .padding(.top, 8)
        }
        .padding(.top, 50)
    }
    
    // MARK: - Error View
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("Error")
                .font(.headline)
                .foregroundColor(MinimalDesign.Colors.primary)
            Text(error)
                .font(.caption)
                .foregroundColor(MinimalDesign.Colors.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 40))
                .foregroundColor(MinimalDesign.Colors.tertiary)
            Text("No users found")
                .font(.headline)
                .foregroundColor(MinimalDesign.Colors.primary)
            Text("Try a different username")
                .font(.caption)
                .foregroundColor(MinimalDesign.Colors.secondary)
        }
        .padding(.top, 50)
    }
    
    // MARK: - Search Results List
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults, id: \.id) { user in
                    if user.id == authManager.currentUser?.id {
                        // Current user - just show the row
                        UserSearchResultRow(user: user, isCurrentUser: true)
                            .padding(.horizontal, MinimalDesign.Spacing.md)
                    } else {
                        // Other users - navigate to profile
                        Button(action: {
                            print("Navigate to user profile: \(user.displayName ?? user.id)")
                        }) {
                            UserSearchResultRow(user: user, isCurrentUser: false)
                                .padding(.horizontal, MinimalDesign.Spacing.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.top, 16)
        }
    }
    
    // MARK: - Search Function
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchError = nil
        
        Task {
            do {
                print("🔍 UserSearch - Searching for: \(searchText)")
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let users = try await searchMockUsers(query: query)
                
                await MainActor.run {
                    self.searchResults = users
                    self.isSearching = false
                    print("✅ UserSearch - Found \(users.count) users")
                }
            } catch {
                print("❌ UserSearch - Search error: \(error)")
                await MainActor.run {
                    self.searchError = "Failed to search users: \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }
    
    // MARK: - Mock Search Function
    private func searchMockUsers(query: String) async throws -> [UserProfile] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mock users for demonstration
        let mockUsers = [
            UserProfile(
                id: "user1",
                userid: "johndoe",
                displayName: "John Doe",
                bio: "iOS Developer",
                avatarUrl: nil,
                homeCountry: "US",
                postCount: 45,
                followerCount: 150,
                followingCount: 200
            ),
            UserProfile(
                id: "user2",
                userid: "janesmith",
                displayName: "Jane Smith",
                bio: "Designer & Photographer",
                avatarUrl: nil,
                homeCountry: "GB",
                postCount: 67,
                followerCount: 300,
                followingCount: 180
            )
        ]

        // Filter users based on query
        return mockUsers.filter { user in
            (user.displayName?.lowercased().contains(query.lowercased()) ?? false)
        }
    }
}

// MARK: - User Search Result Row Component
struct UserSearchResultRow: View {
    let user: UserProfile
    let isCurrentUser: Bool
    @EnvironmentObject var followManager: FollowManager
    @State private var isFollowing = false
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text((user.displayName ?? "?").prefix(1).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.displayName ?? "Unknown User")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MinimalDesign.Colors.primary)

                    // Lock icon for private accounts (disabled - not implemented)
                    // if user.isPrivate {
                    //     Image(systemName: "lock.fill")
                    //         .font(.system(size: 12))
                    //         .foregroundColor(.gray)
                    // }
                }

                Text("@\(user.id.prefix(8))")
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.secondary)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 12))
                        .foregroundColor(MinimalDesign.Colors.tertiary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Follow button (only for other users)
            if !isCurrentUser {
                Button(action: {
                    toggleFollow()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(isFollowing ? "Following" : "Follow")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isFollowing ? Color.clear : MinimalDesign.Colors.accentRed)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isFollowing ? MinimalDesign.Colors.primary : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .disabled(isLoading)
            } else {
                // Current user indicator
                Text("You")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MinimalDesign.Colors.tertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.2))
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func toggleFollow() {
        isLoading = true

        Task {
            _ = await followManager.toggleFollow(userId: user.id)
            isFollowing = await followManager.isFollowing(userId: user.id)
            isLoading = false
        }
    }
}