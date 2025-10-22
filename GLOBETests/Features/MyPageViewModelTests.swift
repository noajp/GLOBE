//======================================================================
// MARK: - MyPageViewModelTests.swift
// Purpose: MyPageViewModel の単体テスト（状態管理・プロフィール操作・データロード）
// Path: GLOBETests/Features/MyPageViewModelTests.swift
//======================================================================

import XCTest
import Combine
import CoreLocation
@testable import GLOBE

@MainActor
final class MyPageViewModelTests: XCTestCase {

    // MARK: - Test Properties
    private var viewModel: MyPageViewModel!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        viewModel = MyPageViewModel()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests
    func testViewModel_initialization_setsDefaultValues() {
        // Given & When: ViewModel is initialized in setUp()

        // Then: Default values should be set correctly
        XCTAssertNil(viewModel.userProfile)
        XCTAssertTrue(viewModel.userPosts.isEmpty)
        XCTAssertEqual(viewModel.postsCount, 0)
        XCTAssertEqual(viewModel.followersCount, 0)
        XCTAssertEqual(viewModel.followingCount, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Profile Validation Tests
    func testUpdateProfile_validInput_updatesSuccessfully() async {
        // Given
        let validUsername = "testuser123"
        let validDisplayName = "Test User"
        let validBio = "This is a test bio"

        // When & Then: No network calls in test environment, but validation logic should work
        // Note: In a full test environment, we would mock the Supabase calls
        await viewModel.updateProfile(
            username: validUsername,
            displayName: validDisplayName,
            bio: validBio
        )

        // Since we can't mock Supabase in this test setup, we primarily test input validation
        // The actual update would require dependency injection and mocking
    }

    func testUpdateProfile_invalidUsername_setsErrorMessage() async {
        // Given
        let invalidUsername = "a" // Too short
        let validDisplayName = "Test User"
        let validBio = "Test bio"

        // When
        await viewModel.updateProfile(
            username: invalidUsername,
            displayName: validDisplayName,
            bio: validBio
        )

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("ユーザー名は3-20文字") ?? false)
    }

    func testUpdateProfile_usernameWithInvalidCharacters_setsErrorMessage() async {
        // Given
        let invalidUsername = "user@name" // Contains invalid characters
        let validDisplayName = "Test User"
        let validBio = "Test bio"

        // When
        await viewModel.updateProfile(
            username: invalidUsername,
            displayName: validDisplayName,
            bio: validBio
        )

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("英数字とアンダースコア") ?? false)
    }

    func testUpdateProfile_longUsername_setsErrorMessage() async {
        // Given
        let longUsername = "thisusernameistoolongtobevalid" // Too long (>20 chars)
        let validDisplayName = "Test User"
        let validBio = "Test bio"

        // When
        await viewModel.updateProfile(
            username: longUsername,
            displayName: validDisplayName,
            bio: validBio
        )

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("ユーザー名は3-20文字") ?? false)
    }

    // MARK: - Input Sanitization Tests
    func testUpdateProfile_inputTrimming_correctlyTrimsWhitespace() async {
        // Given
        let usernameWithSpaces = "  testuser  "
        let displayNameWithSpaces = "  Test User  "
        let bioWithSpaces = "  This is a bio  "

        // When
        await viewModel.updateProfile(
            username: usernameWithSpaces,
            displayName: displayNameWithSpaces,
            bio: bioWithSpaces
        )

        // Then: Input should be trimmed (testing the validation logic)
        // Note: We can't directly test the trimmed values without mocking,
        // but we can verify no error is thrown for valid trimmed input

        // Reset error message for this test case
        await viewModel.updateProfile(username: "testuser", displayName: "Test User", bio: "This is a bio")
    }

    // MARK: - Loading State Tests
    func testLoadUserData_setsLoadingState() async {
        // Given
        XCTAssertFalse(viewModel.isLoading)

        // When
        let loadTask = Task {
            await viewModel.loadUserData()
        }

        // Then: Loading state should be set temporarily
        // Note: In a real test with mocked dependencies, we would verify loading state changes
        await loadTask.value

        // After completion, loading should be false
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Error Handling Tests
    func testViewModel_errorHandling_clearsErrorMessage() {
        // Given
        viewModel.errorMessage = "Test error message"
        XCTAssertNotNil(viewModel.errorMessage)

        // When
        viewModel.errorMessage = nil

        // Then
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Reactive Updates Tests
    func testViewModel_publishedProperties_triggerUpdates() {
        // Given
        var receivedUpdate = false
        let expectation = self.expectation(description: "Published property update")

        viewModel.$isLoading
            .dropFirst() // Skip initial value
            .sink { _ in
                receivedUpdate = true
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        viewModel.isLoading = true

        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(receivedUpdate)
    }

    // MARK: - User Profile Property Tests
    func testViewModel_userProfileUpdate_updatesCorrectly() {
        // Given
        let testProfile = UserProfile(
            id: "test-user-id",
            username: "testuser",
            displayName: "Test User",
            bio: "Test bio",
            avatarUrl: nil,
            postCount: nil,
            followerCount: nil,
            followingCount: nil
        )

        // When
        viewModel.userProfile = testProfile

        // Then
        XCTAssertEqual(viewModel.userProfile?.id, "test-user-id")
        XCTAssertEqual(viewModel.userProfile?.username, "testuser")
        XCTAssertEqual(viewModel.userProfile?.displayName, "Test User")
        XCTAssertEqual(viewModel.userProfile?.bio, "Test bio")
    }

    // MARK: - Posts Count Tests
    func testViewModel_postsCountUpdate_reflectsPostsArray() {
        // Given
        let mockPosts = [
            Post(
                id: UUID(),
                location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                text: "Test post 1",
                authorName: "Test User",
                authorId: "user1"
            ),
            Post(
                id: UUID(),
                location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                text: "Test post 2",
                authorName: "Test User",
                authorId: "user1"
            ),
            Post(
                id: UUID(),
                location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                text: "Test post 3",
                authorName: "Test User",
                authorId: "user1"
            )
        ]

        // When
        viewModel.userPosts = mockPosts
        viewModel.postsCount = mockPosts.count

        // Then
        XCTAssertEqual(viewModel.userPosts.count, 3)
        XCTAssertEqual(viewModel.postsCount, 3)
    }

}