//======================================================================
// MARK: - AppError.swift
// Purpose: Unified error handling system for GLOBE
// Path: GLOBE/Core/Error/AppError.swift
//======================================================================

import Foundation

// MARK: - Unified App Error

enum AppError: LocalizedError, Equatable {
    // MARK: - Authentication Errors
    case authenticationFailed(String)
    case invalidCredentials
    case userNotFound
    case accountLocked
    case sessionExpired
    case rateLimitExceeded(TimeInterval)

    // MARK: - Network Errors
    case networkUnavailable
    case requestTimeout
    case serverError(Int, String)
    case invalidResponse
    case connectionFailed

    // MARK: - Data Errors
    case invalidData(String)
    case corruptedData
    case notFound(String)
    case permissionDenied
    case storageError(String)

    // MARK: - Validation Errors
    case validationFailed(String, field: String)
    case invalidInput(String)
    case contentTooLong(Int, maxLength: Int)
    case securityViolation(String)

    // MARK: - Location Errors
    case locationPermissionDenied
    case locationUnavailable
    case geocodingFailed

    // MARK: - General Errors
    case unknown(String)
    case operationCancelled

    // MARK: - Error Descriptions
    var errorDescription: String? {
        switch self {
        // Authentication
        case .authenticationFailed(let message):
            return "認証エラー: \(message)"
        case .invalidCredentials:
            return "メールアドレスまたはパスワードが正しくありません"
        case .userNotFound:
            return "ユーザーが見つかりません"
        case .accountLocked:
            return "アカウントがロックされています。しばらくしてから再試行してください"
        case .sessionExpired:
            return "セッションの有効期限が切れました。再度ログインしてください"
        case .rateLimitExceeded(let timeInterval):
            return "試行回数が上限に達しました。\(Int(timeInterval))秒後に再試行してください"

        // Network
        case .networkUnavailable:
            return "インターネット接続を確認してください"
        case .requestTimeout:
            return "リクエストがタイムアウトしました"
        case .serverError(let code, let message):
            return "サーバーエラー(\(code)): \(message)"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .connectionFailed:
            return "接続に失敗しました"

        // Data
        case .invalidData(let message):
            return "無効なデータ: \(message)"
        case .corruptedData:
            return "データが破損しています"
        case .notFound(let resource):
            return "\(resource)が見つかりません"
        case .permissionDenied:
            return "アクセス権限がありません"
        case .storageError(let message):
            return "ストレージエラー: \(message)"

        // Validation
        case .validationFailed(let message, let field):
            return "\(field)の検証エラー: \(message)"
        case .invalidInput(let message):
            return "入力エラー: \(message)"
        case .contentTooLong(let length, let maxLength):
            return "内容が長すぎます(\(length)/\(maxLength)文字)"
        case .securityViolation(let message):
            return "セキュリティ違反: \(message)"

        // Location
        case .locationPermissionDenied:
            return "位置情報の使用が許可されていません"
        case .locationUnavailable:
            return "位置情報を取得できません"
        case .geocodingFailed:
            return "住所の取得に失敗しました"

        // General
        case .unknown(let message):
            return "予期しないエラー: \(message)"
        case .operationCancelled:
            return "操作がキャンセルされました"
        }
    }

    // MARK: - Recovery Suggestions
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable, .connectionFailed:
            return "インターネット接続を確認し、再試行してください"
        case .rateLimitExceeded:
            return "しばらく待ってから再試行してください"
        case .sessionExpired:
            return "再度ログインしてください"
        case .locationPermissionDenied:
            return "設定アプリで位置情報の使用を許可してください"
        default:
            return "問題が解決しない場合は、アプリを再起動してください"
        }
    }

    // MARK: - Severity Level
    var severity: SecuritySeverity {
        switch self {
        case .securityViolation:
            return .critical
        case .accountLocked, .permissionDenied:
            return .high
        case .authenticationFailed, .invalidCredentials, .rateLimitExceeded:
            return .medium
        default:
            return .low
        }
    }
}

// MARK: - Error Conversion Utilities

extension AppError {
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let authError = error as? AuthError {
            switch authError {
            case .invalidInput(let message):
                return .invalidInput(message)
            case .rateLimitExceeded(let time):
                return .rateLimitExceeded(time)
            case .accountLocked:
                return .accountLocked
            case .weakPassword:
                return .validationFailed("パスワードが弱すぎます", field: "password")
            case .unknown(let message):
                return .unknown(message)
            case .userNotAuthenticated:
                return .sessionExpired
            }
        }

        // URLError handling
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .requestTimeout
            case .cancelled:
                return .operationCancelled
            default:
                return .connectionFailed
            }
        }

        return .unknown(error.localizedDescription)
    }
}

// MARK: - Result Type Extension

extension Result where Failure == AppError {
    var appError: AppError? {
        switch self {
        case .failure(let error):
            return error
        case .success:
            return nil
        }
    }
}