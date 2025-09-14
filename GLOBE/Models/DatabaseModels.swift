import Foundation

// MARK: - Database Models

// ✅ 修正: @unchecked Sendableで強制的にSendable準拠させ、Main Actor isolation問題を回避
struct PostDB: Codable, @unchecked Sendable {
    let id: UUID
    let user_id: UUID
    let content: String?
    let image_url: String?
    let location_name: String?
    let latitude: Double
    let longitude: Double
    let is_public: Bool
    let like_count: Int
    let comment_count: Int
    let created_at: String
    let updated_at: String
    let profiles: ProfileDB?
}

// ✅ 修正: @unchecked Sendableで強制的にSendable準拠
struct ProfileDB: Codable, @unchecked Sendable {
    let username: String?
    let display_name: String?
    let avatar_url: String?
}

// データベースにデータを挿入（Insert）するためのモデル
struct PostInsert: Codable, @unchecked Sendable {
    let user_id: UUID
    let content: String
    let image_url: String?
    let location_name: String?
    let latitude: Double
    let longitude: Double
    let is_public: Bool
    let expires_at: Date
}

// Note: ProfileInsert moved to SharedModels.swift

struct Like: Codable, @unchecked Sendable {
    let user_id: UUID
    let post_id: UUID
}