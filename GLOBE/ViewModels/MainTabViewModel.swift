//======================================================================
// MARK: - MainTabViewModel.swift
// Purpose: ViewModel for MainTabView following MVVM pattern
// Path: GLOBE/ViewModels/MainTabViewModel.swift
//======================================================================

import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class MainTabViewModel: ObservableObject {
    // MARK: - Dependencies
    private let authService: any AuthServiceProtocol
    private let postService: any PostServiceProtocol
    private let userRepository: any UserRepositoryProtocol
    private let postRepository: any PostRepositoryProtocol

    // MARK: - Published Properties
    @Published var showingAuth = false
    @Published var showingCreatePost = false
    @Published var showingProfile = false
    @Published var selectedPost: Post?
    @Published var selectedStory: Story?

    // MARK: - UI State
    @Published var selectedTab: MainTab = .map
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Data Properties
    @Published var posts: [Post] = []
    @Published var stories: [Story] = []

    // MARK: - Location Properties
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var isLocationPermissionGranted = false

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        authService.isAuthenticated
    }

    var currentUser: AppUser? {
        authService.currentUser
    }

    var activeStories: [Story] {
        stories.filter { !$0.isExpired }
    }

    // MARK: - Initialization
    init(
        authService: (any AuthServiceProtocol)? = nil,
        postService: (any PostServiceProtocol)? = nil,
        userRepository: (any UserRepositoryProtocol)? = nil,
        postRepository: (any PostRepositoryProtocol)? = nil
    ) {
        self.authService = authService ?? AuthManager.shared
        self.postService = postService ?? PostManager.shared
        self.userRepository = userRepository ?? UserRepository.create()
        self.postRepository = postRepository ?? PostRepository.create()

        setupObservers()
        checkAuthenticationState()
    }

    // MARK: - Setup Methods
    private func setupObservers() {
        // Observe authentication state changes
        if let authManager = authService as? AuthManager {
            authManager.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.handleAuthStateChange()
                }
                .store(in: &cancellables)
        }

        // Observe post service changes
        if let postManager = postService as? PostManager {
            postManager.$posts
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newPosts in
                    self?.posts = newPosts
                }
                .store(in: &cancellables)
        }
    }

    private func handleAuthStateChange() {
        if isAuthenticated {
            showingAuth = false
            Task {
                await loadInitialData()
            }
        } else {
            clearUserData()
        }
    }

    // MARK: - Authentication Methods
    func checkAuthenticationState() {
        Task {
            do {
                if let user = try await userRepository.getCurrentUser() {
                    SecureLogger.shared.info("User session restored for: \(user.email ?? "")")
                    await loadInitialData()
                } else {
                    await MainActor.run {
                        showingAuth = true
                    }
                }
            } catch {
                await MainActor.run {
                    showingAuth = true
                }
            }
        }
    }

    func signOut() {
        Task { @MainActor in
            _ = await authService.signOut()
            clearUserData()
            showingAuth = true
        }
    }

    // MARK: - Data Loading Methods
    func loadInitialData() async {
        await MainActor.run {
            isLoading = true
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.loadPosts()
            }

            group.addTask { [weak self] in
                await self?.loadStories()
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    func loadPosts() async {
        do {
            let fetchedPosts = try await postRepository.getAllPosts()
            await MainActor.run {
                self.posts = fetchedPosts
                SecureLogger.shared.info("Loaded \(fetchedPosts.count) posts")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "投稿の読み込みに失敗しました"
                SecureLogger.shared.error("Failed to load posts: \(error.localizedDescription)")
            }
        }
    }

    func loadStories() async {
        await MainActor.run {
            self.stories = []
        }
    }

    func refreshData() async {
        await loadInitialData()
    }

    // MARK: - Post Management Methods
    func createPost(content: String, imageData: Data?, location: CLLocationCoordinate2D, locationName: String?) async {
        do {
            try await postService.createPost(
                content: content,
                imageData: imageData,
                location: location,
                locationName: locationName,
                isAnonymous: false
            )

            // Refresh posts after creation
            await loadPosts()

            await MainActor.run {
                showingCreatePost = false
                SecureLogger.shared.info("Post created successfully")
            }
        } catch {
            await MainActor.run {
                errorMessage = AppError.from(error).localizedDescription
                SecureLogger.shared.error("Failed to create post: \(error.localizedDescription)")
            }
        }
    }

    func deletePost(_ post: Post) async {
        do {
            let success = try await postRepository.deletePost(post.id)
            if success {
                await MainActor.run {
                    posts.removeAll { $0.id == post.id }
                    selectedPost = nil
                }
                SecureLogger.shared.info("Post deleted successfully: \(post.id.uuidString)")
            }
        } catch {
            await MainActor.run {
                errorMessage = "投稿の削除に失敗しました"
                SecureLogger.shared.error("Failed to delete post: \(error.localizedDescription)")
            }
        }
    }

    func toggleLike(for post: Post) async {
        guard let userId = currentUser?.id else { return }

        do {
            let success = try await postRepository.likePost(postId: post.id, userId: userId)
            if success {
                // Update local post like status
                await MainActor.run {
                    if let index = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[index].isLikedByMe.toggle()
                        posts[index].likeCount += posts[index].isLikedByMe ? 1 : -1
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "いいねの更新に失敗しました"
                SecureLogger.shared.error("Failed to toggle like: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - UI State Management
    func selectPost(_ post: Post?) {
        selectedPost = post
    }

    func selectStory(_ story: Story?) {
        selectedStory = story
    }

    func showCreatePost() {
        guard isAuthenticated else {
            showingAuth = true
            return
        }
        showingCreatePost = true
    }

    func showProfile() {
        guard isAuthenticated else {
            showingAuth = true
            return
        }
        showingProfile = true
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Helper Methods
    private func clearUserData() {
        posts = []
        stories = []
        selectedPost = nil
        selectedStory = nil
        errorMessage = nil
    }

    // MARK: - Location Methods
    func updateUserLocation(_ location: CLLocationCoordinate2D) {
        userLocation = location
    }

    func updateLocationPermission(_ granted: Bool) {
        isLocationPermissionGranted = granted
    }
}

// MARK: - Main Tab Enum
enum MainTab {
    case map
    case profile
    case settings
}
