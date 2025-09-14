//======================================================================
// MARK: - UserRepositoryTests.swift
// Purpose: Unit tests for UserRepository implementations
// Path: GLOBETests/Repositories/UserRepositoryTests.swift
//======================================================================

import XCTest
@testable import GLOBE

@MainActor
final class UserRepositoryTests: XCTestCase {

    // MARK: - Test Properties

    var userRepository: MockUserRepository!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()
        userRepository = MockUserRepository()
    }

    override func tearDown() async throws {
        userRepository = nil
        try await super.tearDown()
    }

    // MARK: - Get User by ID Tests

    func testGetUserByIdSuccess() async {
        // Arrange
        let testUserId = "user123"

        // Act
        let user = try! await userRepository.getUser(by: testUserId)

        // Assert
        XCTAssertEqual(userRepository.getUserCallCount, 1)
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.id, "user123")
        XCTAssertEqual(user?.email, "test@example.com")
        XCTAssertEqual(user?.username, "testuser")
    }

    func testGetUserByIdWithCustomUser() async {
        // Arrange
        let customUser = AppUser(
            id: "custom_user",
            email: "custom@example.com",
            username: "customuser",
            createdAt: Date().ISO8601Format()
        )
        userRepository.mockUser = customUser

        // Act
        let user = try! await userRepository.getUser(by: "custom_user")

        // Assert
        XCTAssertEqual(userRepository.getUserCallCount, 1)
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.id, "custom_user")
        XCTAssertEqual(user?.email, "custom@example.com")
        XCTAssertEqual(user?.username, "customuser")
    }

    func testGetUserByIdFailure() async {
        // Arrange
        userRepository.simulateFailure(with: .networkError("User not found"))

        // Act & Assert
        do {
            _ = try await userRepository.getUser(by: "test_user")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(userRepository.getUserCallCount, 1)
            XCTAssertTrue(error is AppError)
            if case .networkError(let message) = error as? AppError {
                XCTAssertEqual(message, "User not found")
            }
        }
    }

    // MARK: - Get Current User Tests

    func testGetCurrentUserSuccess() async {
        // Act
        let user = try! await userRepository.getCurrentUser()

        // Assert
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.id, MockUserRepository.sampleUser.id)
        XCTAssertEqual(user?.email, MockUserRepository.sampleUser.email)
        XCTAssertEqual(user?.username, MockUserRepository.sampleUser.username)
    }

    func testGetCurrentUserWithCustomUser() async {
        // Arrange
        let customUser = AppUser(
            id: "current_user",
            email: "current@example.com",
            username: "currentuser",
            createdAt: Date().ISO8601Format()
        )
        userRepository.mockUser = customUser

        // Act
        let user = try! await userRepository.getCurrentUser()

        // Assert
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.id, "current_user")
        XCTAssertEqual(user?.email, "current@example.com")
        XCTAssertEqual(user?.username, "currentuser")
    }

    func testGetCurrentUserFailure() async {
        // Arrange
        userRepository.simulateFailure(with: .authenticationError("Session expired"))

        // Act & Assert
        do {
            _ = try await userRepository.getCurrentUser()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
            if case .authenticationError(let message) = error as? AppError {
                XCTAssertEqual(message, "Session expired")
            }
        }
    }

    // MARK: - Update User Profile Tests

    func testUpdateUserProfileSuccess() async {
        // Arrange
        let userToUpdate = AppUser(
            id: "test_user",
            email: "updated@example.com",
            username: "updateduser",
            createdAt: Date().ISO8601Format()
        )

        // Act
        let success = try! await userRepository.updateUserProfile(userToUpdate)

        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(userRepository.mockUser?.id, "test_user")
        XCTAssertEqual(userRepository.mockUser?.email, "updated@example.com")
        XCTAssertEqual(userRepository.mockUser?.username, "updateduser")
    }

    func testUpdateUserProfileFailure() async {
        // Arrange
        userRepository.simulateFailure(with: .validationError("Invalid email format"))
        let userToUpdate = AppUser(
            id: "test_user",
            email: "invalid-email",
            username: "testuser",
            createdAt: Date().ISO8601Format()
        )

        // Act & Assert
        do {
            _ = try await userRepository.updateUserProfile(userToUpdate)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
            if case .validationError(let message) = error as? AppError {
                XCTAssertEqual(message, "Invalid email format")
            }
        }
    }

    // MARK: - Delete User Tests

    func testDeleteUserSuccess() async {
        // Arrange
        let testUserId = "user_to_delete"
        userRepository.mockUser = AppUser(
            id: testUserId,
            email: "delete@example.com",
            username: "deleteuser",
            createdAt: Date().ISO8601Format()
        )

        // Act
        let success = try! await userRepository.deleteUser(testUserId)

        // Assert
        XCTAssertTrue(success)
        XCTAssertNil(userRepository.mockUser)
    }

    func testDeleteUserFailure() async {
        // Arrange
        userRepository.simulateFailure(with: .authorizationError("Insufficient permissions"))

        // Act & Assert
        do {
            _ = try await userRepository.deleteUser("test_user")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
            if case .authorizationError(let message) = error as? AppError {
                XCTAssertEqual(message, "Insufficient permissions")
            }
        }
    }

    // MARK: - Get User Profile Tests

    func testGetUserProfileSuccess() async {
        // Arrange
        let testUserId = "profile_user"

        // Act
        let profile = try! await userRepository.getUserProfile(by: testUserId)

        // Assert
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.id, MockUserRepository.sampleProfile.id)
        XCTAssertEqual(profile?.username, MockUserRepository.sampleProfile.username)
        XCTAssertEqual(profile?.displayName, MockUserRepository.sampleProfile.displayName)
        XCTAssertEqual(profile?.bio, MockUserRepository.sampleProfile.bio)
        XCTAssertEqual(profile?.postCount, MockUserRepository.sampleProfile.postCount)
        XCTAssertEqual(profile?.followerCount, MockUserRepository.sampleProfile.followerCount)
        XCTAssertEqual(profile?.followingCount, MockUserRepository.sampleProfile.followingCount)
    }

    func testGetUserProfileWithCustomProfile() async {
        // Arrange
        let customProfile = UserProfile(
            id: "custom_profile",
            username: "customprofile",
            displayName: "Custom Profile",
            bio: "Custom bio",
            avatarUrl: "https://example.com/custom-avatar.jpg",
            postCount: 25,
            followerCount: 150,
            followingCount: 75
        )
        userRepository.mockProfile = customProfile

        // Act
        let profile = try! await userRepository.getUserProfile(by: "custom_profile")

        // Assert
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.id, "custom_profile")
        XCTAssertEqual(profile?.displayName, "Custom Profile")
        XCTAssertEqual(profile?.postCount, 25)
        XCTAssertEqual(profile?.followerCount, 150)
        XCTAssertEqual(profile?.followingCount, 75)
    }

    func testGetUserProfileFailure() async {
        // Arrange
        userRepository.simulateFailure(with: .notFound("Profile not found"))

        // Act & Assert
        do {
            _ = try await userRepository.getUserProfile(by: "test_user")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
            if case .notFound(let message) = error as? AppError {
                XCTAssertEqual(message, "Profile not found")
            }
        }
    }

    // MARK: - Update User Profile (UserProfile) Tests

    func testUpdateUserProfileObjectSuccess() async {
        // Arrange
        let profileToUpdate = UserProfile(
            id: "updated_profile",
            username: "updatedprofile",
            displayName: "Updated Profile",
            bio: "Updated bio",
            avatarUrl: "https://example.com/updated-avatar.jpg",
            postCount: 30,
            followerCount: 200,
            followingCount: 100
        )

        // Act
        let success = try! await userRepository.updateUserProfile(profileToUpdate)

        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(userRepository.updateProfileCallCount, 1)
        XCTAssertEqual(userRepository.mockProfile?.id, "updated_profile")
        XCTAssertEqual(userRepository.mockProfile?.displayName, "Updated Profile")
        XCTAssertEqual(userRepository.mockProfile?.bio, "Updated bio")
        XCTAssertEqual(userRepository.mockProfile?.postCount, 30)
    }

    func testUpdateUserProfileObjectFailure() async {
        // Arrange
        userRepository.simulateFailure(with: .validationError("Display name too long"))
        let profileToUpdate = UserProfile(
            id: "test_profile",
            username: "testprofile",
            displayName: "This display name is way too long and exceeds the maximum allowed length",
            bio: "Test bio",
            avatarUrl: nil,
            postCount: 0,
            followerCount: 0,
            followingCount: 0
        )

        // Act & Assert
        do {
            _ = try await userRepository.updateUserProfile(profileToUpdate)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(userRepository.updateProfileCallCount, 1)
            XCTAssertTrue(error is AppError)
            if case .validationError(let message) = error as? AppError {
                XCTAssertEqual(message, "Display name too long")
            }
        }
    }

    // MARK: - Mock Repository Utility Tests

    func testRepositoryResetFunctionality() {
        // Arrange
        userRepository.mockUser = AppUser(
            id: "temp_user",
            email: "temp@example.com",
            username: "tempuser",
            createdAt: Date().ISO8601Format()
        )
        userRepository.mockProfile = UserProfile(
            id: "temp_profile",
            username: "tempprofile",
            displayName: "Temp Profile",
            bio: "Temp bio",
            avatarUrl: nil,
            postCount: 999,
            followerCount: 999,
            followingCount: 999
        )
        userRepository.simulateFailure()
        userRepository.getUserCallCount = 5
        userRepository.updateProfileCallCount = 3

        // Act
        userRepository.reset()

        // Assert
        XCTAssertTrue(userRepository.shouldSucceed)
        XCTAssertNil(userRepository.mockUser)
        XCTAssertNil(userRepository.mockProfile)
        XCTAssertEqual(userRepository.getUserCallCount, 0)
        XCTAssertEqual(userRepository.updateProfileCallCount, 0)
    }

    func testSimulateFailureFunctionality() {
        // Arrange
        let customError = AppError.storageError("Custom storage error")

        // Act
        userRepository.simulateFailure(with: customError)

        // Assert
        XCTAssertFalse(userRepository.shouldSucceed)
        if case .storageError(let message) = userRepository.mockError {
            XCTAssertEqual(message, "Custom storage error")
        } else {
            XCTFail("Expected storageError but got \(userRepository.mockError)")
        }
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentUserAccess() async {
        // Arrange
        let userIds = Array(0..<100).map { "user_\($0)" }

        // Act
        await withTaskGroup(of: AppUser?.self) { group in
            for userId in userIds {
                group.addTask { [weak self] in
                    return try? await self?.userRepository.getUser(by: userId)
                }
            }

            var results: [AppUser?] = []
            for await result in group {
                results.append(result)
            }

            // Assert
            XCTAssertEqual(results.count, userIds.count)
            XCTAssertEqual(userRepository.getUserCallCount, userIds.count)
        }
    }

    func testConcurrentProfileUpdates() async {
        // Arrange
        let profiles = Array(0..<50).map { index in
            UserProfile(
                id: "profile_\(index)",
                username: "user\(index)",
                displayName: "User \(index)",
                bio: "Bio for user \(index)",
                avatarUrl: nil,
                postCount: index,
                followerCount: index * 2,
                followingCount: index * 3
            )
        }

        // Act
        await withTaskGroup(of: Bool.self) { group in
            for profile in profiles {
                group.addTask { [weak self] in
                    return (try? await self?.userRepository.updateUserProfile(profile)) ?? false
                }
            }

            var successCount = 0
            for await success in group {
                if success { successCount += 1 }
            }

            // Assert
            XCTAssertEqual(successCount, profiles.count)
            XCTAssertEqual(userRepository.updateProfileCallCount, profiles.count)
        }
    }

    // MARK: - Performance Tests

    func testPerformanceOfGetUser() {
        measure {
            let expectation = XCTestExpectation(description: "Get user")
            Task {
                _ = try! await userRepository.getUser(by: "performance_test_user")
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }

    func testPerformanceOfUpdateProfile() {
        let profile = UserProfile(
            id: "performance_profile",
            username: "performanceuser",
            displayName: "Performance User",
            bio: "Performance testing bio",
            avatarUrl: "https://example.com/performance-avatar.jpg",
            postCount: 100,
            followerCount: 500,
            followingCount: 250
        )

        measure {
            let expectation = XCTestExpectation(description: "Update profile")
            Task {
                _ = try! await userRepository.updateUserProfile(profile)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }

    // MARK: - Edge Case Tests

    func testGetUserWithEmptyId() async {
        // Act
        let user = try! await userRepository.getUser(by: "")

        // Assert - Mock returns sample user for any ID when successful
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.id, MockUserRepository.sampleUser.id)
    }

    func testUpdateUserProfileWithNilValues() async {
        // Arrange
        let profileWithNils = UserProfile(
            id: "nil_test",
            username: "niluser",
            displayName: nil,
            bio: nil,
            avatarUrl: nil,
            postCount: 0,
            followerCount: 0,
            followingCount: 0
        )

        // Act
        let success = try! await userRepository.updateUserProfile(profileWithNils)

        // Assert
        XCTAssertTrue(success)
        XCTAssertNil(userRepository.mockProfile?.displayName)
        XCTAssertNil(userRepository.mockProfile?.bio)
        XCTAssertNil(userRepository.mockProfile?.avatarUrl)
    }
}