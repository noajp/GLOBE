//======================================================================
// MARK: - DatabaseSecurity.swift
// Purpose: データベースセキュリティ管理システム
// Usage: DatabaseSecurity.shared.validateQuery(), DatabaseSecurity.shared.sanitizeInput()
//======================================================================

import Foundation
import Supabase

/// データベースセキュリティ管理システム
final class DatabaseSecurity: @unchecked Sendable {
    static let shared = DatabaseSecurity()
    
    private let secureLogger = SecureLogger.shared
    private init() {}
    
    // MARK: - Query Validation
    
    /// SQLクエリの安全性検証
    func validateQuery(_ query: String, operation: DatabaseOperation) -> QueryValidationResult {
        let sanitizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空のクエリチェック
        if sanitizedQuery.isEmpty {
            return .invalid("Empty query not allowed")
        }
        
        // SQLインジェクション攻撃パターンのチェック
        if containsSQLInjectionPatterns(sanitizedQuery) {
            secureLogger.securityEvent("SQL injection attempt detected", details: ["query": sanitizedQuery])
            return .invalid("Query contains potentially dangerous patterns")
        }
        
        // 操作タイプの検証
        if !isValidOperationForQuery(sanitizedQuery, operation: operation) {
            secureLogger.securityEvent("Operation type mismatch", details: [
                "query": sanitizedQuery,
                "expected_operation": operation.rawValue
            ])
            return .invalid("Query operation type mismatch")
        }
        
        // DDL文の制限チェック
        if containsDDLStatements(sanitizedQuery) && operation != .ddl {
            secureLogger.securityEvent("Unauthorized DDL statement", details: ["query": sanitizedQuery])
            return .invalid("DDL statements not allowed in this context")
        }
        
        return .valid(sanitizedQuery)
    }
    
    /// SQLインジェクションパターンの検出
    private func containsSQLInjectionPatterns(_ query: String) -> Bool {
        let dangerousPatterns = [
            // 基本的なSQLインジェクションパターン
            #"(\b(union|select|insert|update|delete|drop|create|alter|exec|execute)\b.*){2,}"#,
            
            // コメント記号を使った攻撃
            #"--.*"#,
            #"/\*.*\*/"#,
            
            // 文字列エスケープ攻撃
            #"['""].*[;].*['""]"#,
            
            // システム関数の不正使用
            #"\b(xp_|sp_|pg_|information_schema)\b"#,
            
            // 条件の常に真になるパターン
            #"\b(1=1|'='|or\s+1=1|or\s+'1'='1')\b"#
        ]
        
        let lowercasedQuery = query.lowercased()
        
        for pattern in dangerousPatterns {
            if lowercasedQuery.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
    
    /// 操作タイプの妥当性チェック
    private func isValidOperationForQuery(_ query: String, operation: DatabaseOperation) -> Bool {
        let lowercasedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch operation {
        case .select:
            return lowercasedQuery.hasPrefix("select")
        case .insert:
            return lowercasedQuery.hasPrefix("insert")
        case .update:
            return lowercasedQuery.hasPrefix("update")
        case .delete:
            return lowercasedQuery.hasPrefix("delete")
        case .ddl:
            return lowercasedQuery.hasPrefix("create") || 
                   lowercasedQuery.hasPrefix("alter") || 
                   lowercasedQuery.hasPrefix("drop")
        }
    }
    
    /// DDL文の検出
    private func containsDDLStatements(_ query: String) -> Bool {
        let ddlKeywords = ["create", "alter", "drop", "truncate", "grant", "revoke"]
        let lowercasedQuery = query.lowercased()
        
        return ddlKeywords.contains { lowercasedQuery.contains($0) }
    }
    
    // MARK: - Row Level Security
    
    /// RLS（Row Level Security）検証
    func validateRowAccess(userID: String, resourceOwnerID: String?, operation: DatabaseOperation) -> Bool {
        guard let resourceOwnerID = resourceOwnerID else {
            // リソースにオーナーが設定されていない場合は、操作によって判断
            return operation == .select || operation == .insert
        }
        
        // ユーザーは自分のリソースのみアクセス可能
        if userID == resourceOwnerID {
            return true
        }
        
        // 読み取り専用操作は制限緩和（実装によって調整）
        if operation == .select {
            return validatePublicReadAccess(userID: userID, resourceOwnerID: resourceOwnerID)
        }
        
        secureLogger.securityEvent("Unauthorized row access attempt", details: [
            "user_id": userID,
            "resource_owner_id": resourceOwnerID,
            "operation": operation.rawValue
        ])
        
        return false
    }
    
    /// パブリック読み取りアクセスの検証
    private func validatePublicReadAccess(userID: String, resourceOwnerID: String) -> Bool {
        // 実装例：フォロー関係や公開設定に基づく
        // 実際の実装では、フォロー状態や投稿の公開設定を確認
        return true // 暫定的に全て許可（要調整）
    }
    
    // MARK: - Data Sanitization
    
    /// データベース入力のサニタイゼーション
    func sanitizeForDatabase(_ input: Any) -> Any {
        switch input {
        case let string as String:
            return sanitizeString(string)
        case let dict as [String: Any]:
            return dict.mapValues { sanitizeForDatabase($0) }
        case let array as [Any]:
            return array.map { sanitizeForDatabase($0) }
        default:
            return input
        }
    }
    
    /// 文字列のサニタイゼーション
    private func sanitizeString(_ input: String) -> String {
        var sanitized = input
        
        // NULL文字の除去
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        
        // 危険な制御文字の除去
        sanitized = sanitized.filter { char in
            !char.isNewline || char == "\n" || char == "\r"
        }
        
        // 過度に長い文字列の切り詰め
        if sanitized.count > 10000 {
            sanitized = String(sanitized.prefix(10000))
        }
        
        return sanitized
    }
    
    // MARK: - Rate Limiting
    
    private var queryRateLimits: [String: (count: Int, lastReset: Date)] = [:]
    private let maxQueriesPerMinute = 100
    
    /// クエリレート制限チェック
    func checkQueryRateLimit(for userID: String) -> Bool {
        let now = Date()
        let key = userID
        
        if var limit = queryRateLimits[key] {
            // 1分経過していたらリセット
            if now.timeIntervalSince(limit.lastReset) >= 60 {
                limit = (count: 1, lastReset: now)
                queryRateLimits[key] = limit
                return true
            }
            
            // 制限チェック
            if limit.count >= maxQueriesPerMinute {
                secureLogger.securityEvent("Query rate limit exceeded", details: [
                    "user_id": userID,
                    "query_count": limit.count
                ])
                return false
            }
            
            // カウントアップ
            limit.count += 1
            queryRateLimits[key] = limit
        } else {
            // 初回
            queryRateLimits[key] = (count: 1, lastReset: now)
        }
        
        return true
    }
    
    // MARK: - Audit Logging
    
    /// データベース操作の監査ログ
    func logDatabaseOperation(
        operation: DatabaseOperation,
        table: String,
        userID: String,
        query: String? = nil,
        success: Bool
    ) {
        let auditData: [String: Any] = [
            "operation": operation.rawValue,
            "table": table,
            "user_id": userID,
            "success": success,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "query_hash": query?.hash ?? 0
        ]
        
        if success {
            secureLogger.info("Database operation completed: \(operation.rawValue) on \(table)")
        } else {
            secureLogger.securityEvent("Database operation failed", details: auditData)
        }
    }
}

// MARK: - Supporting Types

enum DatabaseOperation: String {
    case select = "SELECT"
    case insert = "INSERT"
    case update = "UPDATE"
    case delete = "DELETE"
    case ddl = "DDL"
}

enum QueryValidationResult {
    case valid(String)
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var query: String? {
        switch self {
        case .valid(let query): return query
        case .invalid: return nil
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let message): return message
        }
    }
}

// MARK: - Supabase Extensions

extension SupabaseClient {
    
    /// セキュアなクエリ実行
    func secureQuery(
        _ query: String,
        operation: DatabaseOperation,
        userID: String
    ) async throws -> PostgrestResponse<[String: AnyJSON]> {
        
        // レート制限チェック
        guard DatabaseSecurity.shared.checkQueryRateLimit(for: userID) else {
            throw DatabaseSecurityError.rateLimitExceeded
        }
        
        // クエリ検証
        let validation = DatabaseSecurity.shared.validateQuery(query, operation: operation)
        guard validation.isValid, let validQuery = validation.query else {
            throw DatabaseSecurityError.invalidQuery(validation.errorMessage ?? "Invalid query")
        }
        
        // 監査ログ
        DatabaseSecurity.shared.logDatabaseOperation(
            operation: operation,
            table: "unknown", // 実際の実装では解析が必要
            userID: userID,
            query: validQuery,
            success: true
        )
        
        // 実際のクエリ実行（実装が必要）
        // return try await database.rpc(validQuery)
        fatalError("Secure query execution not implemented")
    }
}

enum DatabaseSecurityError: LocalizedError {
    case rateLimitExceeded
    case invalidQuery(String)
    case unauthorizedAccess
    case sqlInjectionDetected
    
    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded:
            return "Database query rate limit exceeded"
        case .invalidQuery(let message):
            return "Invalid database query: \(message)"
        case .unauthorizedAccess:
            return "Unauthorized database access"
        case .sqlInjectionDetected:
            return "SQL injection attempt detected"
        }
    }
}