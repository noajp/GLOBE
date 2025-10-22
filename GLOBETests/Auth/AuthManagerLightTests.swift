//======================================================================
// MARK: - AuthManagerLightTests.swift
// Purpose: ネットワーク非依存のAuthManagerユーティリティの検証
// Path: GLOBETests/Auth/AuthManagerLightTests.swift
//======================================================================

import XCTest
@testable import GLOBE

@MainActor
final class AuthManagerLightTests: XCTestCase {

    // MARK: - Device Security Info Tests
    func testGetDeviceSecurityInfo_hasExpectedKeys() {
        let info = AuthManager.shared.getDeviceSecurityInfo()
        // 必須キーの存在
        XCTAssertNotNil(info["is_simulator"])
        XCTAssertNotNil(info["is_jailbroken"])
        // 値がBool型であることを確認
        if let v = info["is_simulator"] {
            XCTAssertTrue(v is Bool, "is_simulator should be Bool type")
        }
        if let v = info["is_jailbroken"] {
            XCTAssertTrue(v is Bool, "is_jailbroken should be Bool type")
        }
    }

    // MARK: - Security Event Reporting Tests
    func testReportSecurityEvent_doesNotThrow() {
        // セキュリティイベント報告は例外を投げないことを確認
        XCTAssertNoThrow {
            AuthManager.shared.reportSecurityEvent(
                "test_event",
                severity: .low,
                details: ["test": "value"]
            )
        }

        XCTAssertNoThrow {
            AuthManager.shared.reportSecurityEvent(
                "critical_event",
                severity: .critical,
                details: ["error": "test_critical_error"]
            )
        }
    }

    // MARK: - Input Validation Integration Tests
    func testSignUpInputValidation_rejectsInvalidData() async {
        // 無効なメール
        do {
            try await AuthManager.shared.signUp(email: "invalid-email", password: "ValidPass123", username: "testuser")
            XCTFail("Should throw error for invalid email")
        } catch {
            XCTAssertTrue(error is AuthError)
        }

        // 弱いパスワード
        do {
            try await AuthManager.shared.signUp(email: "test@example.com", password: "weak", username: "testuser")
            XCTFail("Should throw error for weak password")
        } catch {
            XCTAssertTrue(error is AuthError)
        }

        // 無効なユーザー名
        do {
            try await AuthManager.shared.signUp(email: "test@example.com", password: "ValidPass123", username: "ab")
            XCTFail("Should throw error for invalid username")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }

    // MARK: - Rate Limiting Tests
    func testSignInRateLimit_blocksExcessiveAttempts() async {
        let testEmail = "ratetest@example.com"

        // 複数回の失敗ログイン試行をシミュレート
        for _ in 0..<6 { // maxLoginAttempts (5) を超える
            do {
                try await AuthManager.shared.signIn(email: testEmail, password: "wrongpassword")
            } catch {
                // ログイン失敗は期待される
            }
        }

        // 6回目以降はレート制限によりブロックされることを確認
        do {
            try await AuthManager.shared.signIn(email: testEmail, password: "anypassword")
            XCTFail("Should be blocked by rate limit")
        } catch let error as AuthError {
            if case .rateLimitExceeded = error {
                // 期待される結果 (正しいケース名を使用)
            } else {
                XCTFail("Expected rate limit error, got: \(error)")
            }
        } catch {
            XCTFail("Expected AuthError.rateLimitExceeded, got: \(error)")
        }
    }
}

