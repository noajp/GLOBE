//======================================================================
// MARK: - DatabaseSecurityTests.swift
// Purpose: DatabaseSecurity のクエリ検証、RLS、レート制限、サニタイゼーションのテスト
// Path: GLOBETests/Security/DatabaseSecurityTests.swift
//======================================================================

import XCTest
@testable import GLOBE

final class DatabaseSecurityTests: XCTestCase {
    
    // MARK: - Query Validation
    func testValidateQuery_detectsInjectionAndMismatch() {
        // SQL インジェクション的パターン
        let inj = "SELECT * FROM users; DROP TABLE users; --"
        let r1 = DatabaseSecurity.shared.validateQuery(inj, operation: .select)
        XCTAssertFalse(r1.isValid)
        
        // 操作の不一致（INSERT だが SELECT 文）
        let mismatch = DatabaseSecurity.shared.validateQuery("SELECT * FROM posts", operation: .insert)
        XCTAssertFalse(mismatch.isValid)
        
        // DDL を DDL 以外の操作で実行 → 無効
        let ddlInWrongContext = DatabaseSecurity.shared.validateQuery("DROP TABLE posts", operation: .select)
        XCTAssertFalse(ddlInWrongContext.isValid)
        
        // 正常なクエリ
        let ok = DatabaseSecurity.shared.validateQuery("SELECT id FROM posts WHERE is_public = true", operation: .select)
        XCTAssertTrue(ok.isValid)
        XCTAssertNotNil(ok.query)
    }
    
    // MARK: - Rate Limiting
    func testCheckQueryRateLimit_enforcesLimit() {
        let userID = "user-123"
        // 100回までは許可（実装上は初期化後カウント蓄積）
        var allowedCount = 0
        for _ in 0..<110 {
            if DatabaseSecurity.shared.checkQueryRateLimit(for: userID) {
                allowedCount += 1
            }
        }
        XCTAssertLessThan(allowedCount, 110)
        XCTAssertGreaterThanOrEqual(allowedCount, 100)
    }
    
    // MARK: - Sanitize For Database
    func testSanitizeForDatabase_stringAndCollections() {
        // 文字列
        let s = "hello\u{0000}world\n\t"
        let sanitized = DatabaseSecurity.shared.sanitizeForDatabase(s) as! String
        XCTAssertFalse(sanitized.contains("\u{0000}"))
        
        // 配列
        let arr: [Any] = ["a\u{0000}", 1]
        let sArr = DatabaseSecurity.shared.sanitizeForDatabase(arr) as! [Any]
        XCTAssertEqual((sArr[0] as! String).contains("\u{0000}"), false)
        
        // 辞書
        let dict: [String: Any] = ["k": "v\u{0000}"]
        let sDict = DatabaseSecurity.shared.sanitizeForDatabase(dict) as! [String: Any]
        XCTAssertEqual((sDict["k"] as! String).contains("\u{0000}"), false)
    }
    
    // MARK: - RLS
    func testValidateRowAccess_ownerAndPublicRead() {
        // 自分のリソース → 常に許可
        XCTAssertTrue(DatabaseSecurity.shared.validateRowAccess(userID: "u1", resourceOwnerID: "u1", operation: .update))
        
        // 他人のリソースの読み取り（実装では public 読み取りは true で暫定）
        XCTAssertTrue(DatabaseSecurity.shared.validateRowAccess(userID: "u1", resourceOwnerID: "u2", operation: .select))
        
        // 他人のリソースの書き込み → 禁止
        XCTAssertFalse(DatabaseSecurity.shared.validateRowAccess(userID: "u1", resourceOwnerID: "u2", operation: .delete))
    }
}

