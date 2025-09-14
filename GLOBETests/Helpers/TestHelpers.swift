//======================================================================
// MARK: - TestHelpers.swift
// Purpose: 共通テストユーティリティ（アサーション補助など）
// Path: GLOBETests/Helpers/TestHelpers.swift
//======================================================================

import XCTest
import Foundation
import CoreLocation

// MARK: - ValidationResult ヘルパ
@testable import GLOBE

extension ValidationResult {
    var unwrappedValue: String {
        switch self {
        case .valid(let v): return v
        case .invalid(let message):
            XCTFail("ValidationResult invalid: \(message)")
            return ""
        }
    }
}

// MARK: - Mock Data Helpers

extension Post {
    static func mockPost(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        locationName: String = "テスト場所",
        imageData: Data? = nil,
        imageUrl: String? = nil,
        text: String = "テスト投稿",
        authorName: String = "テストユーザー",
        authorId: String = "test-user-id",
        authorAvatarUrl: String? = nil,
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLikedByMe: Bool = false,
        isPublic: Bool = true,
        isAnonymous: Bool = false
    ) -> Post {
        return Post(
            id: id,
            createdAt: createdAt,
            location: location,
            locationName: locationName,
            imageData: imageData,
            imageUrl: imageUrl,
            text: text,
            authorName: authorName,
            authorId: authorId,
            authorAvatarUrl: authorAvatarUrl,
            likeCount: likeCount,
            commentCount: commentCount,
            isLikedByMe: isLikedByMe,
            isPublic: isPublic,
            isAnonymous: isAnonymous
        )
    }
}

extension UserProfile {
    static func mockUserProfile(
        id: String = "test-user-id",
        username: String = "testuser",
        displayName: String = "Test User",
        bio: String? = "Test bio",
        avatarUrl: String? = nil,
        postCount: Int? = 0,
        followerCount: Int? = 0,
        followingCount: Int? = 0
    ) -> UserProfile {
        return UserProfile(
            id: id,
            username: username,
            displayName: displayName,
            bio: bio,
            avatarUrl: avatarUrl,
            postCount: postCount,
            followerCount: followerCount,
            followingCount: followingCount
        )
    }
}

extension Story {
    static func mockStory(
        userId: String = "test-user-id",
        userName: String = "Test User",
        userAvatarData: Data? = nil,
        imageData: Data = Data(),
        text: String? = "Test story",
        createdAt: Date = Date()
    ) -> Story {
        return Story(
            userId: userId,
            userName: userName,
            userAvatarData: userAvatarData,
            imageData: imageData,
            text: text,
            createdAt: createdAt
        )
    }
}

