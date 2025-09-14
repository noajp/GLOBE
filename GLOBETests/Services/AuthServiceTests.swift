//======================================================================
// MARK: - AuthServiceTests.swift
// Purpose: Unit tests for AuthService implementations
// Path: GLOBETests/Services/AuthServiceTests.swift
//======================================================================

import XCTest
import Combine
@testable import GLOBE

@MainActor
final class AuthServiceTests: XCTestCase {

    // MARK: - Test Properties

    var authService: MockAuthService!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()
        authService = MockAuthService()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        authService = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Sign In Tests

    func testSignInSuccess() async {
        // Arrange
        let email = "test@example.com"
        let password = "password123"

        // Act
        try! await authService.signIn(email: email, password: password)

        // Assert
        XCTAssertEqual(authService.signInCallCount, 1)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.email, email)
        XCTAssertEqual(authService.currentUser?.username, "test")
        XCTAssertFalse(authService.isLoading)
    }

    func testSignInWithLongDelay() async {
        // Arrange
        authService.mockDelay = 0.5
        let email = "test@example.com"
        let password = "password123"

        // Act
        let startTime = Date()
        try! await authService.signIn(email: email, password: password)
        let endTime = Date()

        // Assert
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(duration, 0.5)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertEqual(authService.signInCallCount, 1)
    }

    func testSignInFailure() async {
        // Arrange
        authService.simulateFailure(with: .invalidInput("Invalid credentials"))

        // Act & Assert
        do {
            try await authService.signIn(email: "test@example.com", password: "wrong")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(authService.signInCallCount, 1)
            XCTAssertFalse(authService.isAuthenticated)
            XCTAssertNil(authService.currentUser)
            XCTAssertFalse(authService.isLoading)
            XCTAssertTrue(error is AuthError)
        }
    }

    func testSignInIsLoadingState() {
        // Arrange
        authService.mockDelay = 0.2
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []

        authService.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 3 { // Initial false, true during loading, false after
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        Task {
            try! await authService.signIn(email: "test@example.com", password: "password")
        }

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates[0], false) // Initial state
        XCTAssertEqual(loadingStates[1], true)  // During loading
        XCTAssertEqual(loadingStates[2], false) // After completion
    }

    // MARK: - Sign Up Tests

    func testSignUpSuccess() async {
        // Arrange
        let email = "newuser@example.com"
        let password = "newpassword123"
        let username = "newuser"

        // Act
        try! await authService.signUp(email: email, password: password, username: username)

        // Assert
        XCTAssertEqual(authService.signUpCallCount, 1)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.email, email)
        XCTAssertEqual(authService.currentUser?.username, username)
        XCTAssertTrue(authService.currentUser?.id.hasPrefix("test_user_") ?? false)
        XCTAssertFalse(authService.isLoading)
    }

    func testSignUpFailure() async {
        // Arrange
        authService.simulateFailure(with: .invalidInput("Email already exists"))

        // Act & Assert
        do {
            try await authService.signUp(
                email: "existing@example.com",
                password: "password123",
                username: "testuser"
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(authService.signUpCallCount, 1)
            XCTAssertFalse(authService.isAuthenticated)
            XCTAssertNil(authService.currentUser)
            XCTAssertFalse(authService.isLoading)
            XCTAssertTrue(error is AuthError)
        }
    }

    // MARK: - Sign Out Tests

    func testSignOutSuccess() async {
        // Arrange - First sign in
        try! await authService.signIn(email: "test@example.com", password: "password")
        XCTAssertTrue(authService.isAuthenticated)

        // Act
        await authService.signOut()

        // Assert
        XCTAssertEqual(authService.signOutCallCount, 1)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(authService.isLoading)
    }

    func testSignOutWhenNotAuthenticated() async {
        // Arrange - Ensure not authenticated
        XCTAssertFalse(authService.isAuthenticated)

        // Act
        await authService.signOut()

        // Assert
        XCTAssertEqual(authService.signOutCallCount, 1)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }

    // MARK: - Check Current User Tests

    func testCheckCurrentUserWithValidUser() async {
        // Arrange
        authService.simulateAuthenticatedUser()

        // Act
        let hasUser = await authService.checkCurrentUser()

        // Assert
        XCTAssertTrue(hasUser)
        XCTAssertEqual(authService.checkCurrentUserCallCount, 1)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertNotNil(authService.currentUser)
    }

    func testCheckCurrentUserWithoutUser() async {
        // Arrange - No user set
        XCTAssertNil(authService.currentUser)

        // Act
        let hasUser = await authService.checkCurrentUser()

        // Assert
        XCTAssertFalse(hasUser)
        XCTAssertEqual(authService.checkCurrentUserCallCount, 1)
        XCTAssertFalse(authService.isAuthenticated)
    }

    func testCheckCurrentUserFailure() async {
        // Arrange
        authService.simulateAuthenticatedUser()
        authService.simulateFailure(with: .sessionExpired)

        // Act
        let hasUser = await authService.checkCurrentUser()

        // Assert
        XCTAssertFalse(hasUser)
        XCTAssertEqual(authService.checkCurrentUserCallCount, 1)
        XCTAssertFalse(authService.isAuthenticated)
    }

    // MARK: - Validate Session Tests

    func testValidateSessionSuccess() async {
        // Arrange
        authService.simulateAuthenticatedUser()

        // Act
        let isValid = try! await authService.validateSession()

        // Assert
        XCTAssertTrue(isValid)
    }

    func testValidateSessionWithoutUser() async {
        // Arrange - No user set
        XCTAssertNil(authService.currentUser)

        // Act & Assert
        do {
            _ = try await authService.validateSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }

    func testValidateSessionFailure() async {
        // Arrange
        authService.simulateAuthenticatedUser()
        authService.simulateFailure(with: .sessionExpired)

        // Act & Assert
        do {
            _ = try await authService.validateSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AuthError)
            if case .sessionExpired = error as? AuthError {
                // Expected error type
            } else {
                XCTFail("Expected sessionExpired error")
            }
        }
    }

    // MARK: - Password Reset Tests

    func testSendPasswordResetEmailSuccess() async {
        // Act
        try! await authService.sendPasswordResetEmail(email: "test@example.com")

        // Assert - No exception thrown means success
    }

    func testSendPasswordResetEmailFailure() async {
        // Arrange
        authService.simulateFailure(with: .invalidInput("Invalid email format"))

        // Act & Assert
        do {
            try await authService.sendPasswordResetEmail(email: "invalid-email")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AuthError)
            if case .invalidInput(let message) = error as? AuthError {
                XCTAssertEqual(message, "Invalid email format")
            }
        }
    }

    // MARK: - Rate Limiting Tests

    func testCheckRateLimitSuccess() {
        // Act
        let allowed = authService.checkRateLimit(for: "sign_in")

        // Assert
        XCTAssertTrue(allowed)
    }

    func testCheckRateLimitFailure() {
        // Arrange
        authService.simulateRateLimitExceeded()

        // Act
        let allowed = authService.checkRateLimit(for: "sign_in")

        // Assert
        XCTAssertFalse(allowed)
    }

    // MARK: - Mock Helper Tests

    func testSimulateAuthenticatedUserHelper() {
        // Act
        authService.simulateAuthenticatedUser()

        // Assert
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.id, "test_user_123")
        XCTAssertEqual(authService.currentUser?.email, "test@example.com")
        XCTAssertEqual(authService.currentUser?.username, "testuser")
    }

    func testSimulateFailureHelper() {
        // Arrange
        let customError = AuthError.rateLimitExceeded(120)

        // Act
        authService.simulateFailure(with: customError)

        // Assert
        XCTAssertFalse(authService.shouldSucceed)
        if case .rateLimitExceeded(let seconds) = authService.mockError {
            XCTAssertEqual(seconds, 120)
        } else {
            XCTFail("Expected rateLimitExceeded error")
        }
    }

    func testResetHelper() {
        // Arrange - Modify state
        authService.simulateAuthenticatedUser()
        authService.signInCallCount = 5
        authService.signUpCallCount = 3
        authService.simulateFailure()

        // Act
        authService.reset()

        // Assert
        XCTAssertTrue(authService.shouldSucceed)
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertFalse(authService.isLoading)
        XCTAssertEqual(authService.signInCallCount, 0)
        XCTAssertEqual(authService.signUpCallCount, 0)
        XCTAssertEqual(authService.signOutCallCount, 0)
        XCTAssertEqual(authService.checkCurrentUserCallCount, 0)
    }

    // MARK: - Published Properties Tests

    func testCurrentUserPublishedProperty() {
        // Arrange
        let expectation = XCTestExpectation(description: "Current user published")
        var userUpdates: [AppUser?] = []

        authService.$currentUser
            .sink { user in
                userUpdates.append(user)
                if userUpdates.count >= 2 { // Initial nil + authenticated user
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        authService.simulateAuthenticatedUser()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(userUpdates.count, 2)
        XCTAssertNil(userUpdates[0])
        XCTAssertNotNil(userUpdates[1])
        XCTAssertEqual(userUpdates[1]?.id, "test_user_123")
    }

    func testIsAuthenticatedPublishedProperty() {
        // Arrange
        let expectation = XCTestExpectation(description: "Authentication state published")
        var authStates: [Bool] = []

        authService.$isAuthenticated
            .sink { isAuth in
                authStates.append(isAuth)
                if authStates.count >= 2 { // Initial false + authenticated true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        authService.simulateAuthenticatedUser()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(authStates.count, 2)
        XCTAssertFalse(authStates[0])
        XCTAssertTrue(authStates[1])
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentSignInAttempts() async {
        // Arrange
        let emails = Array(0..<10).map { "user\($0)@example.com" }

        // Act
        await withTaskGroup(of: Bool.self) { group in
            for email in emails {
                group.addTask { [weak self] in
                    do {
                        try await self?.authService.signIn(email: email, password: "password")
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var successCount = 0
            for await success in group {
                if success { successCount += 1 }
            }

            // Assert
            XCTAssertEqual(successCount, emails.count)
            XCTAssertEqual(authService.signInCallCount, emails.count)
        }
    }

    // MARK: - Performance Tests

    func testPerformanceOfSignIn() {
        authService.mockDelay = 0.01 // Reduce delay for performance test

        measure {
            let expectation = XCTestExpectation(description: "Sign in performance")
            Task {
                try! await authService.signIn(email: "perf@example.com", password: "password")
                authService.reset() // Reset for next iteration
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }

    // MARK: - Edge Case Tests

    func testSignInWithEmptyCredentials() async {
        // Act & Assert
        do {
            try await authService.signIn(email: "", password: "")
            // Mock doesn't validate input, so this succeeds
            XCTAssertTrue(authService.isAuthenticated)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMultipleSignOutCalls() async {
        // Arrange
        authService.simulateAuthenticatedUser()

        // Act
        await authService.signOut()
        await authService.signOut()
        await authService.signOut()

        // Assert
        XCTAssertEqual(authService.signOutCallCount, 3)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }

    func testAuthStateAfterMultipleOperations() async {
        // Act - Perform multiple operations
        try! await authService.signUp(email: "test@example.com", password: "pass", username: "user")
        XCTAssertTrue(authService.isAuthenticated)

        await authService.signOut()
        XCTAssertFalse(authService.isAuthenticated)

        try! await authService.signIn(email: "test@example.com", password: "pass")
        XCTAssertTrue(authService.isAuthenticated)

        let hasUser = await authService.checkCurrentUser()
        XCTAssertTrue(hasUser)

        // Assert final state
        XCTAssertEqual(authService.signUpCallCount, 1)
        XCTAssertEqual(authService.signInCallCount, 1)
        XCTAssertEqual(authService.signOutCallCount, 1)
        XCTAssertEqual(authService.checkCurrentUserCallCount, 1)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertNotNil(authService.currentUser)
    }
}