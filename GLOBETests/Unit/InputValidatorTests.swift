//======================================================================
// MARK: - InputValidatorTests.swift
// Purpose: InputValidator の検証（メール/パスワード/サニタイズ/投稿/位置情報）
// Path: GLOBETests/Unit/InputValidatorTests.swift
//======================================================================

import XCTest
@testable import GLOBE

final class InputValidatorTests: XCTestCase {
    
    // MARK: - Email
    func testValidateEmail_validAndInvalid() {
        // 有効
        XCTAssertTrue(InputValidator.validateEmail("user@example.com").isValid)
        XCTAssertTrue(InputValidator.validateEmail("test.user+tag@domain.co.jp").isValid)
        
        // 無効
        XCTAssertFalse(InputValidator.validateEmail("invalid.email").isValid)
        XCTAssertFalse(InputValidator.validateEmail("@domain.com").isValid)
        XCTAssertFalse(InputValidator.validateEmail("user@").isValid)
        
        // 危険パターン
        XCTAssertFalse(InputValidator.validateEmail("user@javascript:alert(1)").isValid)
    }
    
    // MARK: - Password
    func testValidatePassword_rules() {
        // 8文字未満 → 無効
        XCTAssertFalse(InputValidator.validatePassword("Abc123").isValid)
        // 英字+数字を含む8文字以上 → 有効
        XCTAssertTrue(InputValidator.validatePassword("Abcdef12").isValid)
        // 許可された記号を含んでもOK
        let symbolPassword = "Abc123!@#"
        let result = InputValidator.validatePassword(symbolPassword)
        print("🔍 パスワード '\(symbolPassword)' の検証結果: \(result)")
        XCTAssertTrue(result.isValid, "記号を含むパスワードが無効と判定されました: \(result)")
        // 数字のみ or 英字のみ → 無効
        XCTAssertFalse(InputValidator.validatePassword("12345678").isValid)
        XCTAssertFalse(InputValidator.validatePassword("abcdefgh").isValid)
    }
    
    // MARK: - Sanitize Text
    func testSanitizeText_removesHTMLAndEscapesSQL() {
        let input = "  <script>alert(1)</script>O'Reilly  "
        let sanitized = InputValidator.sanitizeText(input)
        
        // 危険なタグは除去
        XCTAssertFalse(sanitized.lowercased().contains("<script>"))
        XCTAssertFalse(sanitized.lowercased().contains("</script>"))
        
        // SQL特殊文字はエスケープ（' → ''）
        XCTAssertTrue(sanitized.contains("O''Reilly"))
        
        // 先頭末尾スペースはトリミング
        XCTAssertEqual(sanitized, sanitized.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    // MARK: - Post Content Validation
    func testValidatePostContent_basicRules() {
        // 空白のみ → 無効
        XCTAssertFalse(InputValidator.validatePostContent("   ").isValid)
        // スパムパターン → 無効
        XCTAssertFalse(InputValidator.validatePostContent("Buy now!!! Limited time").isValid)
        // 危険な短縮URL/HTTP → 無効
        XCTAssertFalse(InputValidator.validatePostContent("check http://example.com").isValid)
        XCTAssertFalse(InputValidator.validatePostContent("visit bit.ly/abc").isValid)
        
        // 正常テキスト → 有効
        let ok = InputValidator.validatePostContent("今日は渋谷で写真を撮った！")
        XCTAssertTrue(ok.isValid)
        XCTAssertEqual(ok.value, "今日は渋谷で写真を撮った！")
    }
    
    // MARK: - Location Safety
    func testValidateLocationSafety_boundsAndDangerZone() {
        // 範囲外
        XCTAssertFalse(InputValidator.validateLocationSafety(latitude: -100, longitude: 0).isValid)
        XCTAssertFalse(InputValidator.validateLocationSafety(latitude: 0, longitude: 200).isValid)
        
        // 危険エリア（皇居近傍: 35.685175, 139.752799）
        let nearImperial = InputValidator.validateLocationSafety(latitude: 35.6853, longitude: 139.7526)
        XCTAssertFalse(nearImperial.isValid)
        
        // 安全エリア（例えば大阪周辺）
        let osaka = InputValidator.validateLocationSafety(latitude: 34.6937, longitude: 135.5023)
        XCTAssertTrue(osaka.isValid)
    }
    
    // MARK: - Username
    func testValidateUsername_rules() {
        XCTAssertTrue(InputValidator.validateUsername("user_01").isValid)
        XCTAssertFalse(InputValidator.validateUsername("ab").isValid) // 3文字未満
        XCTAssertFalse(InputValidator.validateUsername("too-long-username-123").isValid)
        XCTAssertFalse(InputValidator.validateUsername("bad name").isValid)
        XCTAssertFalse(InputValidator.validateUsername("日本語").isValid)
    }
    
    // MARK: - URL
    func testValidateURL_basic() {
        XCTAssertTrue(InputValidator.validateURL("https://example.com").isValid)
        XCTAssertTrue(InputValidator.validateURL("https://example.com/path?x=1#y").isValid)
        XCTAssertFalse(InputValidator.validateURL("javascript:alert(1)").isValid)
        XCTAssertFalse(InputValidator.validateURL("data:text/html;base64,aaa").isValid)
        XCTAssertFalse(InputValidator.validateURL("ftp://example.com").isValid) // HTTPSのみ許可
        XCTAssertFalse(InputValidator.validateURL("http://example.com").isValid) // HTTPは不可、HTTPSのみ
        XCTAssertFalse(InputValidator.validateURL("https://bit.ly/abc").isValid) // 短縮URLは危険
    }
    
    // MARK: - Phone
    func testValidatePhoneNumber() {
        XCTAssertTrue(InputValidator.validatePhoneNumber("090-1234-5678").isValid)
        XCTAssertTrue(InputValidator.validatePhoneNumber("+81 90 1234 5678").isValid)
        XCTAssertFalse(InputValidator.validatePhoneNumber("abc-123").isValid)
    }
}
