//======================================================================
// MARK: - MockServices.swift
// Purpose: Mock implementations for service testing
// Path: GLOBETests/Mocks/MockServices.swift
//======================================================================

import Foundation
import Combine
import CoreLocation
@testable import GLOBE

// MARK: - Mock Auth Service

@MainActor
class MockAuthService: AuthServiceProtocol, ObservableObject {

    // MARK: - Published Properties
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false

    // MARK: - Mock State
    var shouldSucceed = true
    var mockError: AuthError = .unknown("Mock auth error")
    var signInCallCount = 0
    var signUpCallCount = 0
    var signOutCallCount = 0
    var checkCurrentUserCallCount = 0

    // MARK: - Mock Delay
    var mockDelay: TimeInterval = 0.1

    // MARK: - AuthServiceProtocol Implementation

    func signIn(email: String, password: String) async throws {
        signInCallCount += 1
        isLoading = true

        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))

        if shouldSucceed {
            let user = AppUser(
                id: "test_user_123",
                email: email,
                username: email.components(separatedBy: "@").first,
                createdAt: Date().ISO8601Format()
            )
            currentUser = user
            isAuthenticated = true
            isLoading = false
        } else {
            isLoading = false
            throw mockError
        }
    }

    func signUp(email: String, password: String, username: String) async throws {
        signUpCallCount += 1
        isLoading = true

        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))

        if shouldSucceed {
            let user = AppUser(
                id: "test_user_\(UUID().uuidString.prefix(8))",
                email: email,
                username: username,
                createdAt: Date().ISO8601Format()
            )
            currentUser = user
            isAuthenticated = true
            isLoading = false
        } else {
            isLoading = false
            throw mockError
        }
    }

    func signOut() async {
        signOutCallCount += 1

        try? await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))

        currentUser = nil
        isAuthenticated = false
        isLoading = false
    }

    func checkCurrentUser() async -> Bool {
        checkCurrentUserCallCount += 1

        if shouldSucceed && currentUser != nil {
            isAuthenticated = true
            return true
        } else {
            isAuthenticated = false
            return false
        }
    }

    func validateSession() async throws -> Bool {
        if shouldSucceed && currentUser != nil {
            return true
        } else {
            throw mockError
        }
    }

    func sendPasswordResetEmail(email: String) async throws {
        if !shouldSucceed {
            throw mockError
        }
    }

    func checkRateLimit(for operation: String) -> Bool {
        return shouldSucceed
    }
}

// MARK: - Mock Post Service

@MainActor
class MockPostService: PostServiceProtocol, ObservableObject {

    // MARK: - Published Properties
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Mock State
    var shouldSucceed = true
    var mockError: AuthError = .unknown("Mock post error")
    var createPostCallCount = 0
    var fetchPostsCallCount = 0
    var deletePostCallCount = 0
    var mockDelay: TimeInterval = 0.1

    init() {
        // Initialize with sample posts
        posts = MockPostRepository.samplePosts
    }

    // MARK: - PostServiceProtocol Implementation

    func fetchPosts() async {
        fetchPostsCallCount += 1
        isLoading = true

        try? await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))

        if shouldSucceed {
            // Simulate fetching posts
            posts = MockPostRepository.samplePosts
            error = nil
        } else {
            error = mockError.localizedDescription
        }

        isLoading = false
    }

    func createPost(
        content: String,
        imageData: Data?,
        location: CLLocationCoordinate2D,
        locationName: String?,
        isAnonymous: Bool
    ) async throws {
        createPostCallCount += 1
        isLoading = true

        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))

        if shouldSucceed {
            let newPost = Post(
                id: UUID(),
                userId: "test_user_123",
                content: content,
                imageURL: imageData != nil ? "mock://image.jpg" : nil,
                latitude: location.latitude,
                longitude: location.longitude,
                locationName: locationName,
                isAnonymous: isAnonymous,
                createdAt: Date(),
                likeCount: 0,
                commentCount: 0,
                isLikedByMe: false,
                authorProfile: nil
            )
            posts.insert(newPost, at: 0)
            error = nil
            isLoading = false
        } else {
            isLoading = false
            throw mockError
        }
    }

    func deletePost(_ postId: UUID) async -> Bool {
        deletePostCallCount += 1

        try? await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))

        if shouldSucceed {
            posts.removeAll { $0.id == postId }
            return true
        } else {
            error = "Failed to delete post"
            return false
        }
    }

    func toggleLike(for postId: UUID) async -> Bool {
        if shouldSucceed {
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].isLikedByMe.toggle()
                posts[index].likeCount += posts[index].isLikedByMe ? 1 : -1
                return true
            }
        }
        return false
    }

    func updatePosts(_ newPosts: [Post]) {
        posts = newPosts
    }
}

// MARK: - Test Utilities and Extensions

extension MockAuthService {
    func reset() {
        shouldSucceed = true
        currentUser = nil
        isAuthenticated = false
        isLoading = false
        signInCallCount = 0
        signUpCallCount = 0
        signOutCallCount = 0
        checkCurrentUserCallCount = 0
        mockError = .unknown("Mock auth error")
    }

    func simulateAuthenticatedUser() {
        currentUser = AppUser(
            id: "test_user_123",
            email: "test@example.com",
            username: "testuser",
            createdAt: Date().ISO8601Format()
        )
        isAuthenticated = true
    }

    func simulateFailure(with error: AuthError = .unknown("Mock error")) {
        shouldSucceed = false
        mockError = error
    }

    func simulateRateLimitExceeded() {
        simulateFailure(with: .rateLimitExceeded(300))
    }

    func simulateInvalidCredentials() {
        simulateFailure(with: .invalidInput("Invalid credentials"))
    }
}

extension MockPostService {
    func reset() {
        shouldSucceed = true
        posts = MockPostRepository.samplePosts
        isLoading = false
        error = nil
        createPostCallCount = 0
        fetchPostsCallCount = 0
        deletePostCallCount = 0
        mockError = .unknown("Mock post error")
    }

    func simulateFailure(with error: AuthError = .unknown("Mock error")) {
        shouldSucceed = false
        mockError = error
    }

    func simulateNetworkError() {
        simulateFailure(with: .unknown("Network connection failed"))
    }

    func simulateEmptyPosts() {
        posts = []
    }

    func addMockPost() -> Post {
        let newPost = Post(
            id: UUID(),
            userId: "test_user_123",
            content: "Mock post content",
            imageURL: nil,
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: "Tokyo",
            isAnonymous: false,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            isLikedByMe: false,
            authorProfile: nil
        )
        posts.append(newPost)
        return newPost
    }
}

// MARK: - Mock Service Container

class MockServiceContainer: ServiceContainerProtocol {
    private var services: [String: Any] = [:]

    func register<T>(_ service: T, for type: T.Type) {
        let key = String(describing: type)
        services[key] = service
    }

    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }

    // MARK: - Convenience Registration Methods

    func registerMockServices() {
        let mockAuthService = MockAuthService()
        let mockPostService = MockPostService()
        let mockUserRepository = MockUserRepository()
        let mockPostRepository = MockPostRepository()
        let mockCacheRepository = MockCacheRepository()

        register(mockAuthService, for: AuthServiceProtocol.self)
        register(mockPostService, for: PostServiceProtocol.self)
        register(mockUserRepository, for: UserRepositoryProtocol.self)
        register(mockPostRepository, for: PostRepositoryProtocol.self)
        register(mockCacheRepository, for: CacheRepositoryProtocol.self)
    }

    func reset() {
        services.removeAll()
    }
}

// MARK: - Test Helpers

class TestHelpers {
    static func createMockServiceContainer() -> MockServiceContainer {
        let container = MockServiceContainer()
        container.registerMockServices()
        return container
    }

    static func createMockAppState() -> AppState {
        return AppState(
            authState: AuthState(
                isAuthenticated: true,
                currentUser: AppUser(
                    id: "test_user",
                    email: "test@example.com",
                    username: "testuser",
                    createdAt: Date().ISO8601Format()
                ),
                isLoading: false,
                error: nil,
                loginAttempts: 0,
                isLocked: false
            ),
            postsState: PostsState(
                posts: MockPostRepository.samplePosts,
                userPosts: [],
                selectedPost: nil,
                isLoading: false,
                error: nil,
                lastFetchTime: Date()
            ),
            mapState: MapState.initial,
            userState: UserState(
                profile: MockUserRepository.sampleProfile,
                stories: [],
                isLoading: false,
                error: nil
            ),
            uiState: UIState.initial
        )
    }

    static func createMockPost(
        id: UUID = UUID(),
        userId: String = "test_user",
        content: String = "Test post content",
        isLiked: Bool = false
    ) -> Post {
        return Post(
            id: id,
            userId: userId,
            content: content,
            imageURL: nil,
            latitude: 35.6762,
            longitude: 139.6503,
            locationName: "Test Location",
            isAnonymous: false,
            createdAt: Date(),
            likeCount: isLiked ? 1 : 0,
            commentCount: 0,
            isLikedByMe: isLiked,
            authorProfile: nil
        )
    }
}