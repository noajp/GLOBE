//======================================================================
// MARK: - GLOBETestUtilities.swift
// Purpose: Advanced test utilities inspired by STILL project patterns
// Path: GLOBETests/Utilities/GLOBETestUtilities.swift
//======================================================================

import XCTest
import SwiftUI
import Combine
import CoreLocation
@testable import GLOBE

/// Advanced test utilities for GLOBE app testing
final class GLOBETestUtilities {

    // MARK: - Data Factories

    /// Creates a comprehensive test Post with all optional parameters
    static func createAdvancedTestPost(
        id: UUID = UUID(),
        text: String = "Test post content 🌍",
        createdAt: Date = Date(),
        location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        locationName: String = "Tokyo, Japan",
        authorName: String = "testuser",
        authorId: String = "test-user-id",
        isPublic: Bool = true,
        imageUrl: String? = "https://example.com/test.jpg",
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLikedByMe: Bool = false,
        authorAvatarUrl: String? = nil
    ) -> Post {
        var post = Post(
            id: id,
            createdAt: createdAt,
            location: location,
            locationName: locationName,
            imageData: nil,
            imageUrl: imageUrl,
            text: text,
            authorName: authorName,
            authorId: authorId,
            likeCount: likeCount,
            commentCount: commentCount,
            isPublic: isPublic,
            isAnonymous: false,
            authorAvatarUrl: authorAvatarUrl
        )
        post.isLikedByMe = isLikedByMe
        return post
    }

    /// Creates a test UserProfile with comprehensive data
    static func createAdvancedTestUserProfile(
        id: String = "test-user-id",
        username: String = "testuser",
        displayName: String? = "Test User",
        bio: String? = "Test user bio",
        avatarUrl: String? = "https://example.com/avatar.jpg",
        postCount: Int? = 25,
        followerCount: Int? = 100,
        followingCount: Int? = 50
    ) -> UserProfile {
        UserProfile(
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

    /// Creates a test Story with realistic data
    static func createAdvancedTestStory(
        userId: String = "test-user-id",
        userName: String = "testuser",
        userAvatarData: Data? = nil,
        imageData: Data = Data(),
        text: String? = "Test story content",
        createdAt: Date = Date()
    ) -> Story {
        Story(
            userId: userId,
            userName: userName,
            userAvatarData: userAvatarData,
            imageData: imageData,
            text: text,
            createdAt: createdAt
        )
    }

    /// Creates multiple test posts with varied data
    static func createVariedTestPosts(count: Int = 5) -> [Post] {
        var posts: [Post] = []

        for index in 0..<count {
            let location = CLLocationCoordinate2D(
                latitude: 35.0 + Double(index) * 0.1,
                longitude: 139.0 + Double(index) * 0.1
            )

            let post = createAdvancedTestPost(
                id: UUID(),
                text: "Test post \(index) with different content 📱",
                location: location,
                locationName: "Location \(index)",
                authorName: "user\(index)",
                authorId: "user-\(index)",
                likeCount: index * 5,
                commentCount: index * 2,
                isLikedByMe: index % 2 == 0
            )

            posts.append(post)
        }

        return posts
    }

    // MARK: - Async Testing Utilities

    /// Waits for async operation with timeout
    static func waitForAsync(timeout: TimeInterval = 2.0) async {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }

    /// Creates realistic network delays for testing
    static func simulateNetworkDelay(_ delay: TimeInterval = 0.1) async {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    // MARK: - Error Generation

    /// Creates test AuthError
    static func createAuthError(_ type: AuthError = .invalidInput("Invalid credentials")) -> AuthError {
        return type
    }

    /// Creates test ValidationError
    static func createValidationError(message: String) -> ValidationResult {
        return ValidationResult.invalid(message)
    }

    // MARK: - Location Testing

    /// Creates test CLLocation objects
    static func createTestLocation(
        latitude: Double = 35.6762,
        longitude: Double = 139.6503,
        accuracy: Double = 5.0
    ) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: accuracy,
            timestamp: Date()
        )
    }

    /// Creates an array of test locations for route testing
    static func createTestLocationRoute(count: Int = 10) -> [CLLocation] {
        (0..<count).map { index in
            createTestLocation(
                latitude: 35.6762 + Double(index) * 0.001,
                longitude: 139.6503 + Double(index) * 0.001
            )
        }
    }
}

/// Observable object observer for testing reactive properties
@MainActor
class ReactivePropertyObserver<T: ObservableObject> {
    private var cancellables = Set<AnyCancellable>()
    private let object: T

    init(_ object: T) {
        self.object = object
    }

    /// Wait for a boolean property to reach a specific value
    func wait(
        for keyPath: KeyPath<T, Bool>,
        toBe expectedValue: Bool,
        timeout: TimeInterval = 2.0
    ) async -> Bool {
        return await withCheckedContinuation { continuation in
            var hasCompleted = false

            // Check initial value
            if object[keyPath: keyPath] == expectedValue {
                continuation.resume(returning: true)
                return
            }

            // Set up timeout
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if !hasCompleted {
                    hasCompleted = true
                    continuation.resume(returning: false)
                }
            }

            // Observe changes
            object.objectWillChange
                .sink { _ in
                    Task { @MainActor in
                        if !hasCompleted && self.object[keyPath: keyPath] == expectedValue {
                            hasCompleted = true
                            continuation.resume(returning: true)
                        }
                    }
                }
                .store(in: &cancellables)
        }
    }

    /// Wait for an array property to reach a specific count
    func wait<U>(
        for keyPath: KeyPath<T, [U]>,
        toHaveCount expectedCount: Int,
        timeout: TimeInterval = 2.0
    ) async -> Bool {
        return await withCheckedContinuation { continuation in
            var hasCompleted = false

            // Check initial value
            if object[keyPath: keyPath].count == expectedCount {
                continuation.resume(returning: true)
                return
            }

            // Set up timeout
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if !hasCompleted {
                    hasCompleted = true
                    continuation.resume(returning: false)
                }
            }

            // Observe changes
            object.objectWillChange
                .sink { _ in
                    Task { @MainActor in
                        if !hasCompleted && self.object[keyPath: keyPath].count == expectedCount {
                            hasCompleted = true
                            continuation.resume(returning: true)
                        }
                    }
                }
                .store(in: &cancellables)
        }
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - Enhanced XCTest Extensions

extension XCTestCase {

    /// Enhanced async assertion with timeout and custom error messages
    func assertAsync<T>(
        _ expression: @escaping () async throws -> T,
        timeout: TimeInterval = 2.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await expression()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw XCTSkip("Async operation timed out after \(timeout) seconds")
            }

            guard let result = try await group.next() else {
                throw XCTSkip("No result from async operation")
            }

            group.cancelAll()
            return result
        }
    }

    /// Assert that a ValidationResult has expected validity
    func assertValidation(
        _ result: ValidationResult,
        isValid: Bool,
        expectedMessage: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            result.isValid,
            isValid,
            "Expected validation to be \(isValid ? "valid" : "invalid")",
            file: file,
            line: line
        )

        if let expectedMessage = expectedMessage {
            XCTAssertEqual(
                result.errorMessage,
                expectedMessage,
                "Validation error message mismatch",
                file: file,
                line: line
            )
        }
    }

    /// Assert that an AuthError has the expected type
    func assertAuthError(
        _ error: Error,
        expectedType: AuthError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let authError = error as? AuthError else {
            XCTFail(
                "Expected AuthError but got \(type(of: error))",
                file: file,
                line: line
            )
            return
        }

        switch (authError, expectedType) {
        case (.invalidInput, .invalidInput),
             (.rateLimitExceeded, .rateLimitExceeded),
             (.accountLocked, .accountLocked),
             (.weakPassword, .weakPassword),
             (.unknown, .unknown),
             (.userNotAuthenticated, .userNotAuthenticated):
            break // Success
        default:
            XCTFail(
                "Expected \(expectedType) but got \(authError)",
                file: file,
                line: line
            )
        }
    }

    /// Assert that two CLLocationCoordinate2D are approximately equal
    func assertLocationEqual(
        _ location1: CLLocationCoordinate2D,
        _ location2: CLLocationCoordinate2D,
        accuracy: Double = 0.001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let latitudeDiff = abs(location1.latitude - location2.latitude)
        let longitudeDiff = abs(location1.longitude - location2.longitude)

        XCTAssertLessThan(
            latitudeDiff,
            accuracy,
            "Latitude difference \(latitudeDiff) exceeds accuracy \(accuracy)",
            file: file,
            line: line
        )

        XCTAssertLessThan(
            longitudeDiff,
            accuracy,
            "Longitude difference \(longitudeDiff) exceeds accuracy \(accuracy)",
            file: file,
            line: line
        )
    }

    /// Performance measurement helper
    func measureAsync<T>(
        _ operation: () async throws -> T,
        expectedTime: TimeInterval? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        if let expectedTime = expectedTime {
            XCTAssertLessThan(
                timeElapsed,
                expectedTime,
                "Operation took \(timeElapsed)s, expected < \(expectedTime)s",
                file: file,
                line: line
            )
        }

        print("⏱️ Operation completed in \(String(format: "%.3f", timeElapsed))s")
        return result
    }
}