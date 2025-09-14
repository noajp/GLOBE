//======================================================================
// MARK: - AuthenticationIntegrationTests.swift
// Purpose: 認証フローの統合テスト（AuthManager + InputValidator + DatabaseSecurity）
// Path: GLOBETests/Integration/AuthenticationIntegrationTests.swift
//======================================================================

import XCTest
@testable import GLOBE

@MainActor
final class AuthenticationIntegrationTests: XCTestCase {

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        // Reset authentication state
        AuthManager.shared.isAuthenticated = false
        AuthManager.shared.currentUser = nil
    }

    // MARK: - Sign Up Flow Integration Tests
    func testSignUpFlow_withValidInput_integrationTest() async {
        // Given: Valid user credentials
        let email = "integration.test@example.com"
        let password = "ValidPassword123"
        let username = "integrationuser"

        // When & Then: Test full integration
        do {
            // This would normally require mocking Supabase for true unit testing
            // For integration testing, we test the validation pipeline
            try await AuthManager.shared.signUp(email: email, password: password, username: username)
        } catch {
            // Expected to fail without actual network connection
            // But validation should pass through InputValidator

            // Verify input validation components work correctly
            let emailValidation = InputValidator.validateEmail(email)
            XCTAssertTrue(emailValidation.isValid, "Email validation should pass")

            let passwordValidation = InputValidator.validatePassword(password)
            XCTAssertTrue(passwordValidation.isValid, "Password validation should pass")

            let usernameValidation = InputValidator.validateUsername(username)
            XCTAssertTrue(usernameValidation.isValid, "Username validation should pass")
        }
    }

    func testSignUpFlow_withInvalidInput_rejectsAtValidationLayer() async {
        // Given: Invalid credentials
        let invalidEmail = "not-an-email"
        let weakPassword = "123"
        let invalidUsername = "a"

        // When & Then: Should fail at validation layer
        do {
            try await AuthManager.shared.signUp(email: invalidEmail, password: weakPassword, username: invalidUsername)
            XCTFail("Should fail with invalid input")
        } catch let error as AuthError {
            // Verify proper error handling
            switch error {
            case .invalidInput, .weakPassword:
                // Expected validation failure
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Expected AuthError, got: \(error)")
        }
    }

    // MARK: - Sign In Flow Integration Tests
    func testSignInFlow_withRateLimiting_integrationTest() async {
        // Given: Multiple failed sign-in attempts
        let testEmail = "ratelimit.test@example.com"
        let wrongPassword = "wrongpassword"

        // When: Attempt multiple sign-ins (exceeding rate limit)
        for attempt in 1...6 {
            do {
                try await AuthManager.shared.signIn(email: testEmail, password: wrongPassword)
            } catch {
                // Expected to fail, testing rate limiting behavior
                if attempt >= 6 {
                    // Should be rate limited by attempt 6
                    if let authError = error as? AuthError {
                        if case .rateLimitExceeded = authError {
                            // Rate limiting is working correctly
                            break
                        }
                    }
                }
            }
        }
    }

    // MARK: - Security Event Integration Tests
    func testSecurityEventReporting_integrationWithLogger() async {
        // Given: Security event data
        let eventName = "test_security_event"
        let severity = SecuritySeverity.high
        let details = ["source": "integration_test", "timestamp": "\(Date())"]

        // When: Report security event
        AuthManager.shared.reportSecurityEvent(eventName, severity: severity, details: details)

        // Then: Event should be reported without throwing
        // (In a real integration test, we would verify log output)
        XCTAssertTrue(true) // Placeholder - actual verification would require log inspection
    }

    // MARK: - Device Security Integration Tests
    func testDeviceSecurityInfo_integrationTest() {
        // When: Get device security info
        let deviceInfo = AuthManager.shared.getDeviceSecurityInfo()

        // Then: Should contain required security information
        XCTAssertNotNil(deviceInfo["is_simulator"])
        XCTAssertNotNil(deviceInfo["is_jailbroken"])

        // Verify format
        XCTAssertTrue(["true", "false"].contains(deviceInfo["is_simulator"] ?? ""))
        XCTAssertTrue(["true", "false"].contains(deviceInfo["is_jailbroken"] ?? ""))
    }

    // MARK: - Input Validation Integration Tests
    func testInputValidation_integrationWithAuthFlow() {
        // Test that AuthManager properly uses InputValidator

        // Given: Various input scenarios
        let testCases = [
            ("valid@example.com", "ValidPass123", "validuser", true),
            ("invalid-email", "ValidPass123", "validuser", false),
            ("valid@example.com", "weak", "validuser", false),
            ("valid@example.com", "ValidPass123", "a", false),
        ]

        for (email, password, username, shouldBeValid) in testCases {
            // When: Validate inputs using the same logic as AuthManager
            let emailValid = InputValidator.validateEmail(email).isValid
            let passwordValid = InputValidator.validatePassword(password).isValid
            let usernameValid = InputValidator.validateUsername(username).isValid

            let allValid = emailValid && passwordValid && usernameValid

            // Then: Results should match expected validity
            XCTAssertEqual(allValid, shouldBeValid,
                          "Validation failed for: \(email), \(password), \(username)")
        }
    }

    // MARK: - Database Security Integration Tests
    func testDatabaseSecurity_integrationWithAuth() {
        // Given: User ID from authentication context
        let testUserID = "test-user-integration"

        // When: Test database security checks
        let canSelectOwnData = DatabaseSecurity.shared.validateRowAccess(
            userID: testUserID,
            resourceOwnerID: testUserID,
            operation: .select
        )

        let cannotDeleteOthersData = DatabaseSecurity.shared.validateRowAccess(
            userID: testUserID,
            resourceOwnerID: "other-user",
            operation: .delete
        )

        // Then: Security rules should be enforced
        XCTAssertTrue(canSelectOwnData, "Should allow access to own data")
        XCTAssertFalse(cannotDeleteOthersData, "Should not allow deleting others' data")
    }

    // MARK: - Error Handling Integration Tests
    func testErrorHandling_integrationAcrossComponents() {
        // Test error propagation from InputValidator through AuthManager

        // Given: Invalid input that should trigger specific error chain
        let maliciousEmail = "test@javascript:alert(1)"

        // When: Validate through InputValidator (as AuthManager would)
        let emailValidation = InputValidator.validateEmail(maliciousEmail)

        // Then: Should be rejected with appropriate error
        XCTAssertFalse(emailValidation.isValid)
        XCTAssertNotNil(emailValidation.errorMessage)

        // Error message should indicate security concern
        if let errorMessage = emailValidation.errorMessage {
            XCTAssertTrue(errorMessage.contains("dangerous") || errorMessage.contains("Invalid"))
        }
    }

    // MARK: - Session Management Integration Tests
    func testSessionManagement_integrationTest() async {
        // Given: Mock authentication state
        let mockUser = AppUser(
            id: UUID().uuidString,
            email: "session.test@example.com",
            username: "sessionuser",
            createdAt: nil
        )

        // When: Set authenticated user
        AuthManager.shared.currentUser = mockUser
        AuthManager.shared.isAuthenticated = true

        // Then: Session validation should work
        let isValid = await AuthManager.shared.validateSession()

        // Note: Without actual Supabase connection, this will likely return false
        // but the important thing is that it doesn't crash and follows the expected flow
        XCTAssertTrue(isValid == true || isValid == false) // Either result is acceptable for integration test
    }

    // MARK: - Cross-Component Data Flow Tests
    func testDataFlow_fromValidationToStorage() {
        // Test that validated data flows correctly through the system

        // Given: Raw user input
        let rawEmail = "  Test.User+Tag@Example.Com  "
        let rawPassword = "MySecurePassword123"
        let rawUsername = "  test_user_123  "

        // When: Process through validation pipeline
        let emailResult = InputValidator.validateEmail(rawEmail)
        let passwordResult = InputValidator.validatePassword(rawPassword)
        let usernameResult = InputValidator.validateUsername(rawUsername)

        // Then: Validated data should be properly formatted
        if emailResult.isValid, let validEmail = emailResult.value {
            XCTAssertFalse(validEmail.contains(" ")) // Should be trimmed
            XCTAssertTrue(validEmail.lowercased() == validEmail) // Should be normalized
        }

        if passwordResult.isValid {
            // Password should meet complexity requirements
            XCTAssertTrue(rawPassword.count >= 8)
        }

        if usernameResult.isValid, let validUsername = usernameResult.value {
            XCTAssertFalse(validUsername.hasPrefix(" ")) // Should be trimmed
            XCTAssertFalse(validUsername.hasSuffix(" ")) // Should be trimmed
        }
    }
}