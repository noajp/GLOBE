//======================================================================
// MARK: - MainTabViewModelTests.swift
// Purpose: Unit tests for MainTabViewModel
// Path: GLOBETests/ViewModels/MainTabViewModelTests.swift
//======================================================================

import XCTest
import Combine
@testable import GLOBE

@MainActor
final class MainTabViewModelTests: XCTestCase {

    // MARK: - Test Properties

    var viewModel: MainTabViewModel!
    var mockAuthService: MockAuthService!
    var mockPostService: MockPostService!
    var mockUserRepository: MockUserRepository!
    var mockPostRepository: MockPostRepository!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create mock services
        mockAuthService = MockAuthService()
        mockPostService = MockPostService()
        mockUserRepository = MockUserRepository()
        mockPostRepository = MockPostRepository()
        cancellables = Set<AnyCancellable>()

        // Create view model with mocked dependencies
        viewModel = MainTabViewModel(
            authService: mockAuthService,
            postService: mockPostService,
            userRepository: mockUserRepository,
            postRepository: mockPostRepository
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockAuthService = nil
        mockPostService = nil
        mockUserRepository = nil
        mockPostRepository = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertFalse(viewModel.showingAuth)
        XCTAssertFalse(viewModel.showingCreatePost)
        XCTAssertFalse(viewModel.showingProfile)
        XCTAssertEqual(viewModel.selectedTab, .map)
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertTrue(viewModel.stories.isEmpty)
        XCTAssertNil(viewModel.selectedPost)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Authentication Tests

    func testAuthenticationStateBinding() {
        // Initially not authenticated
        XCTAssertFalse(viewModel.isAuthenticated)

        // Authenticate user
        mockAuthService.simulateAuthenticatedUser()

        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.id, "test_user_123")
    }

    func testCheckAuthenticationStateWithValidUser() async {
        // Arrange
        mockAuthService.simulateAuthenticatedUser()

        // Act
        viewModel.checkAuthenticationState()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Assert
        XCTAssertEqual(mockUserRepository.getUserCallCount, 1)
        XCTAssertFalse(viewModel.showingAuth)
    }

    func testCheckAuthenticationStateWithNoUser() async {
        // Arrange
        mockUserRepository.simulateFailure()

        // Act
        viewModel.checkAuthenticationState()

        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Assert
        XCTAssertTrue(viewModel.showingAuth)
    }

    func testSignOut() async {
        // Arrange
        mockAuthService.simulateAuthenticatedUser()
        viewModel.posts = MockPostRepository.samplePosts

        // Act
        await viewModel.signOut()

        // Assert
        XCTAssertEqual(mockAuthService.signOutCallCount, 1)
        XCTAssertTrue(viewModel.showingAuth)
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertTrue(viewModel.stories.isEmpty)
    }

    // MARK: - Posts Management Tests

    func testLoadPosts() async {
        // Act
        await viewModel.loadPosts()

        // Assert
        XCTAssertEqual(mockPostRepository.getAllPostsCallCount, 1)
        XCTAssertEqual(viewModel.posts.count, MockPostRepository.samplePosts.count)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadPostsFailure() async {
        // Arrange
        mockPostRepository.simulateFailure()

        // Act
        await viewModel.loadPosts()

        // Assert
        XCTAssertEqual(mockPostRepository.getAllPostsCallCount, 1)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "投稿の読み込みに失敗しました")
    }

    func testCreatePost() async {
        // Arrange
        mockAuthService.simulateAuthenticatedUser()
        let content = "Test post content"
        let location = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        let locationName = "Tokyo"

        // Act
        await viewModel.createPost(
            content: content,
            imageData: nil,
            location: location,
            locationName: locationName
        )

        // Assert
        XCTAssertEqual(mockPostService.createPostCallCount, 1)
        XCTAssertFalse(viewModel.showingCreatePost)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testCreatePostFailure() async {
        // Arrange
        mockAuthService.simulateAuthenticatedUser()
        mockPostService.simulateFailure()

        // Act
        await viewModel.createPost(
            content: "Test content",
            imageData: nil,
            location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locationName: "Tokyo"
        )

        // Assert
        XCTAssertEqual(mockPostService.createPostCallCount, 1)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testDeletePost() async {
        // Arrange
        let testPost = MockPostRepository.samplePosts.first!
        viewModel.posts = MockPostRepository.samplePosts

        // Act
        await viewModel.deletePost(testPost)

        // Assert
        XCTAssertEqual(mockPostRepository.deletePostCallCount, 1)
        XCTAssertFalse(viewModel.posts.contains { $0.id == testPost.id })
        XCTAssertNil(viewModel.selectedPost)
    }

    func testToggleLike() async {
        // Arrange
        mockAuthService.simulateAuthenticatedUser()
        let testPost = MockPostRepository.samplePosts.first!
        viewModel.posts = MockPostRepository.samplePosts

        // Act
        await viewModel.toggleLike(for: testPost)

        // Assert
        XCTAssertEqual(mockPostRepository.toggleLikeCallCount, 1)

        // Check if like status was updated
        let updatedPost = viewModel.posts.first { $0.id == testPost.id }
        XCTAssertNotNil(updatedPost)
    }

    // MARK: - UI State Management Tests

    func testSelectPost() {
        // Arrange
        let testPost = MockPostRepository.samplePosts.first!

        // Act
        viewModel.selectPost(testPost)

        // Assert
        XCTAssertEqual(viewModel.selectedPost?.id, testPost.id)
    }

    func testDeselectPost() {
        // Arrange
        viewModel.selectedPost = MockPostRepository.samplePosts.first

        // Act
        viewModel.selectPost(nil)

        // Assert
        XCTAssertNil(viewModel.selectedPost)
    }

    func testShowCreatePostWhenAuthenticated() {
        // Arrange
        mockAuthService.simulateAuthenticatedUser()

        // Act
        viewModel.showCreatePost()

        // Assert
        XCTAssertTrue(viewModel.showingCreatePost)
    }

    func testShowCreatePostWhenNotAuthenticated() {
        // Arrange
        mockAuthService.isAuthenticated = false

        // Act
        viewModel.showCreatePost()

        // Assert
        XCTAssertFalse(viewModel.showingCreatePost)
        XCTAssertTrue(viewModel.showingAuth)
    }

    func testShowProfileWhenAuthenticated() {
        // Arrange
        mockAuthService.simulateAuthenticatedUser()

        // Act
        viewModel.showProfile()

        // Assert
        XCTAssertTrue(viewModel.showingProfile)
    }

    func testShowProfileWhenNotAuthenticated() {
        // Arrange
        mockAuthService.isAuthenticated = false

        // Act
        viewModel.showProfile()

        // Assert
        XCTAssertFalse(viewModel.showingProfile)
        XCTAssertTrue(viewModel.showingAuth)
    }

    func testClearError() {
        // Arrange
        viewModel.errorMessage = "Test error"

        // Act
        viewModel.clearError()

        // Assert
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Location Tests

    func testUpdateUserLocation() {
        // Arrange
        let testLocation = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

        // Act
        viewModel.updateUserLocation(testLocation)

        // Assert
        XCTAssertEqual(viewModel.userLocation?.latitude, testLocation.latitude)
        XCTAssertEqual(viewModel.userLocation?.longitude, testLocation.longitude)
    }

    func testUpdateLocationPermission() {
        // Act
        viewModel.updateLocationPermission(true)

        // Assert
        XCTAssertTrue(viewModel.isLocationPermissionGranted)

        // Act
        viewModel.updateLocationPermission(false)

        // Assert
        XCTAssertFalse(viewModel.isLocationPermissionGranted)
    }

    // MARK: - Async Loading Tests

    func testLoadInitialData() async {
        // Act
        await viewModel.loadInitialData()

        // Assert
        XCTAssertEqual(mockPostRepository.getAllPostsCallCount, 1)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testRefreshData() async {
        // Act
        await viewModel.refreshData()

        // Assert
        XCTAssertEqual(mockPostRepository.getAllPostsCallCount, 1)
    }

    // MARK: - Observer Tests

    func testPostServiceObserver() {
        // Arrange
        let expectation = XCTestExpectation(description: "Posts updated")
        let newPosts = [TestHelpers.createMockPost()]

        viewModel.$posts
            .dropFirst() // Skip initial empty value
            .sink { posts in
                if posts.count == newPosts.count {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        mockPostService.posts = newPosts

        // Assert
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Performance Tests

    func testPerformanceOfLoadPosts() {
        // Create a large number of mock posts
        mockPostRepository.mockPosts = Array(0..<1000).map { index in
            TestHelpers.createMockPost(
                id: UUID(),
                userId: "user_\(index)",
                content: "Test post \(index)"
            )
        }

        measure {
            let expectation = XCTestExpectation(description: "Load posts")
            Task {
                await viewModel.loadPosts()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
}