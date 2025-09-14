import Foundation
import CoreLocation
import SwiftUI

struct Post: Identifiable, Equatable, Codable {
    let id: UUID
    let createdAt: Date
    let location: CLLocationCoordinate2D
    let locationName: String?
    let imageData: Data?
    let imageUrl: String?
    let text: String
    let authorName: String
    let authorId: String
    let authorAvatarUrl: String?
    var likeCount: Int = 0
    var commentCount: Int = 0
    var isLikedByMe: Bool = false
    var isPublic: Bool = true
    var isAnonymous: Bool = false
    
    var latitude: Double { location.latitude }
    var longitude: Double { location.longitude }
    var userId: String { authorId } // Alias for compatibility
    
    // 1時間後に期限切れかチェック
    var isExpired: Bool {
        let oneHourLater = createdAt.addingTimeInterval(1 * 60 * 60)
        return Date() > oneHourLater
    }

    // 残り時間を取得
    var timeRemaining: TimeInterval {
        let oneHourLater = createdAt.addingTimeInterval(1 * 60 * 60)
        return max(0, oneHourLater.timeIntervalSince(Date()))
    }
    
    // 残り時間の文字列表示
    var timeRemainingText: String {
        let remaining = timeRemaining
        if remaining <= 0 { return "期限切れ" }
        
        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    init(id: UUID = UUID(), createdAt: Date = Date(), location: CLLocationCoordinate2D, locationName: String? = nil, imageData: Data? = nil, imageUrl: String? = nil, text: String, authorName: String, authorId: String, likeCount: Int = 0, commentCount: Int = 0, isPublic: Bool = true, isAnonymous: Bool = false, authorAvatarUrl: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.location = location
        self.locationName = locationName
        self.imageData = imageData
        self.imageUrl = imageUrl
        self.text = text
        self.authorName = authorName
        self.authorId = authorId
        self.authorAvatarUrl = authorAvatarUrl
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isPublic = isPublic
        self.isAnonymous = isAnonymous
    }
    
    // Codable準拠のため
    enum CodingKeys: String, CodingKey {
        case id, createdAt = "created_at", locationName = "location_name", imageUrl = "image_url", text = "content", authorId = "user_id", likeCount = "like_count", commentCount = "comment_count", isPublic = "is_public", isAnonymous = "is_anonymous", latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        text = try container.decode(String.self, forKey: .text)
        authorId = try container.decode(String.self, forKey: .authorId)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? true
        isAnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnonymous) ?? false
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // imageDataとauthorNameはローカルでのみ使用
        imageData = nil
        authorName = "Unknown" // プロフィールから取得する必要がある
        authorAvatarUrl = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(locationName, forKey: .locationName)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(text, forKey: .text)
        try container.encode(authorId, forKey: .authorId)
        try container.encode(likeCount, forKey: .likeCount)
        try container.encode(commentCount, forKey: .commentCount)
        try container.encode(isPublic, forKey: .isPublic)
        try container.encode(isAnonymous, forKey: .isAnonymous)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    // Equatable準拠のためのカスタム実装
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id &&
               lhs.createdAt == rhs.createdAt &&
               lhs.location.latitude == rhs.location.latitude &&
               lhs.location.longitude == rhs.location.longitude &&
               lhs.locationName == rhs.locationName &&
               lhs.imageData == rhs.imageData &&
               lhs.text == rhs.text &&
               lhs.authorName == rhs.authorName &&
               lhs.authorId == rhs.authorId &&
               lhs.authorAvatarUrl == rhs.authorAvatarUrl &&
               lhs.likeCount == rhs.likeCount &&
               lhs.isLikedByMe == rhs.isLikedByMe &&
               lhs.isAnonymous == rhs.isAnonymous
    }
}

extension Post {
    // モックデータは削除済み - 実際のSupabaseからデータを取得
}
