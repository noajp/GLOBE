import Foundation
import SwiftUI

struct Story: Identifiable, Equatable {
    let id = UUID()
    let userId: String
    let userName: String
    let userAvatarData: Data?
    let imageData: Data
    let text: String?
    let createdAt: Date
    
    // 24時間後に期限切れかチェック
    var isExpired: Bool {
        let twentyFourHoursLater = createdAt.addingTimeInterval(24 * 60 * 60)
        return Date() > twentyFourHoursLater
    }
    
    // 残り時間を取得
    var timeRemaining: TimeInterval {
        let twentyFourHoursLater = createdAt.addingTimeInterval(24 * 60 * 60)
        return max(0, twentyFourHoursLater.timeIntervalSince(Date()))
    }
    
    static func == (lhs: Story, rhs: Story) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Story {
    static var mockStories: [Story] = [
        Story(
            userId: "user1",
            userName: "田中太郎",
            userAvatarData: nil,
            imageData: Data(), // モックデータ
            text: "東京の夕日が綺麗！",
            createdAt: Date().addingTimeInterval(-3600) // 1時間前
        ),
        Story(
            userId: "user2",
            userName: "John Doe",
            userAvatarData: nil,
            imageData: Data(), // モックデータ
            text: "NYC skyline view",
            createdAt: Date().addingTimeInterval(-7200) // 2時間前
        ),
        Story(
            userId: "user3",
            userName: "Marie Dupont",
            userAvatarData: nil,
            imageData: Data(), // モックデータ
            text: "Café à Paris ☕",
            createdAt: Date().addingTimeInterval(-10800) // 3時間前
        )
    ]
}