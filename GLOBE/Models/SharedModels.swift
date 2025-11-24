import Foundation
import SwiftUI

// MARK: - User Profile Models

struct UserProfile: Identifiable, Codable, Equatable, @unchecked Sendable {
    let id: String
    let userid: String?
    let displayName: String?
    let bio: String?
    let avatarUrl: String?
    let homeCountry: String?
    let postCount: Int?
    let followerCount: Int?
    let followingCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userid
        case displayName = "display_name"
        case bio
        case avatarUrl = "avatar_url"
        case homeCountry = "home_country"
        case postCount = "post_count"
        case followerCount = "follower_count"
        case followingCount = "following_count"
    }
}

struct ProfileInsert: Codable, @unchecked Sendable {
    let id: UUID
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

// MARK: - App User

struct AppUser: Codable, Equatable, @unchecked Sendable {
    let id: String
    let email: String?
    let createdAt: String?
    let homeCountry: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case homeCountry = "home_country"
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidInput(String)
    case rateLimitExceeded(TimeInterval)
    case accountLocked
    case weakPassword([String])
    case unknown(String)
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .rateLimitExceeded(let duration):
            return "ログイン試行回数が上限に達しました。\(Int(duration/60))分後に再試行してください。"
        case .accountLocked:
            return "アカウントが一時的にロックされています。複数回のログイン失敗が原因です。"
        case .weakPassword(let errors):
            return "パスワード要件が満たされていません: \(errors.joined(separator: ", "))"
        case .unknown(let message):
            return "認証エラー: \(message)"
        case .userNotAuthenticated:
            return "ユーザーが認証されていません"
        }
    }
}