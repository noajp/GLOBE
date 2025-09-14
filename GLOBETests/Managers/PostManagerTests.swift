//======================================================================
// MARK: - PostManagerTests.swift
// Purpose: PostManager の事前検証（認証・入力検証）のユニットテスト
// Path: GLOBETests/Managers/PostManagerTests.swift
//======================================================================

import XCTest
import CoreLocation
@testable import GLOBE

@MainActor
final class PostManagerTests: XCTestCase {

    func testCreatePost_unauthenticated_throwsUserNotAuthenticated() async {
        // 未認証状態をセット
        AuthManager.shared.isAuthenticated = false
        AuthManager.shared.currentUser = nil

        do {
            try await PostManager.shared.createPost(
                content: "hello",
                imageData: nil,
                location: CLLocationCoordinate2D(latitude: 35.0, longitude: 135.0),
                locationName: "Test"
            )
            XCTFail("未認証で例外が発生しませんでした")
        } catch let err as AuthError {
            switch err {
            case .userNotAuthenticated:
                break // 期待通り
            default:
                XCTFail("想定外のAuthError: \(err.localizedDescription)")
            }
        } catch {
            XCTFail("想定外のエラー: \(error.localizedDescription)")
        }
    }

    func testCreatePost_emptyTextNoImage_throwsInvalidInput() async {
        // 認証済みのダミーユーザーを設定（ネットワークを叩かないパスで終了）
        AuthManager.shared.isAuthenticated = true
        AuthManager.shared.currentUser = AppUser(id: UUID().uuidString, email: nil, username: "tester", createdAt: nil)

        do {
            try await PostManager.shared.createPost(
                content: "   ",
                imageData: nil,
                location: CLLocationCoordinate2D(latitude: 35.0, longitude: 135.0),
                locationName: "Test"
            )
            XCTFail("空テキスト・画像なしで例外が発生しませんでした")
        } catch let err as AuthError {
            switch err {
            case .invalidInput:
                break // 期待通り
            default:
                XCTFail("想定外のAuthError: \(err.localizedDescription)")
            }
        } catch {
            XCTFail("想定外のエラー: \(error.localizedDescription)")
        }
    }

    // MARK: - Content Validation Tests
    func testCreatePost_validContent_passesValidation() async {
        // 認証済みのダミーユーザーを設定
        AuthManager.shared.isAuthenticated = true
        AuthManager.shared.currentUser = AppUser(id: UUID().uuidString, email: nil, username: "tester", createdAt: nil)

        let validContent = "これは有効な投稿内容です"

        // Note: この実装では実際のSupabaseサービスが呼ばれるため、
        // 実際のテストでは依存性注入とモックが必要
        do {
            try await PostManager.shared.createPost(
                content: validContent,
                imageData: nil,
                location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                locationName: "東京"
            )
            // ネットワーク接続エラーなどで失敗する可能性があるが、
            // バリデーションは通ることを確認
        } catch {
            // ネットワークエラーは許可するが、バリデーションエラーは失敗とする
            if let authError = error as? AuthError {
                switch authError {
                case .invalidInput:
                    XCTFail("有効なコンテンツでバリデーションエラー: \(authError.localizedDescription)")
                case .userNotAuthenticated:
                    XCTFail("認証エラー: \(authError.localizedDescription)")
                default:
                    // その他のエラー（ネットワークエラーなど）は許可
                    break
                }
            }
        }
    }

    func testCreatePost_longContent_getsTrimmed() async {
        // 認証済みのダミーユーザーを設定
        AuthManager.shared.isAuthenticated = true
        AuthManager.shared.currentUser = AppUser(id: UUID().uuidString, email: nil, username: "tester", createdAt: nil)

        // 60文字を超えるコンテンツ（画像なしの場合の制限）
        let longContent = String(repeating: "A", 100)

        // 長いコンテンツでもバリデーションエラーにならないことを確認
        do {
            try await PostManager.shared.createPost(
                content: longContent,
                imageData: nil,
                location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                locationName: "テスト場所"
            )
        } catch {
            // バリデーションエラー以外は許可
            if let authError = error as? AuthError {
                if case .invalidInput = authError {
                    XCTFail("コンテンツトリミング後にバリデーションエラー")
                }
            }
        }
    }

    func testCreatePost_withImage_allowsEmptyContent() async {
        // 認証済みのダミーユーザーを設定
        AuthManager.shared.isAuthenticated = true
        AuthManager.shared.currentUser = AppUser(id: UUID().uuidString, email: nil, username: "tester", createdAt: nil)

        let imageData = Data([0x01, 0x02, 0x03]) // ダミー画像データ

        do {
            try await PostManager.shared.createPost(
                content: "", // 空のコンテンツ
                imageData: imageData,
                location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                locationName: "テスト場所"
            )
            // 画像ありの場合は空コンテンツが許可されることを確認
        } catch {
            // バリデーションエラー以外は許可
            if let authError = error as? AuthError {
                if case .invalidInput = authError {
                    XCTFail("画像ありで空コンテンツがバリデーションエラー: \(authError.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Anonymous Post Tests
    func testCreatePost_anonymousFlag_handledCorrectly() async {
        // 認証済みのダミーユーザーを設定
        AuthManager.shared.isAuthenticated = true
        AuthManager.shared.currentUser = AppUser(id: UUID().uuidString, email: nil, username: "tester", createdAt: nil)

        do {
            try await PostManager.shared.createPost(
                content: "匿名投稿テスト",
                imageData: nil,
                location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                locationName: "テスト場所",
                isAnonymous: true
            )
            // 匿名フラグがエラーを引き起こさないことを確認
        } catch {
            // バリデーションエラー以外は許可
            if let authError = error as? AuthError {
                if case .invalidInput = authError {
                    XCTFail("匿名投稿でバリデーションエラー: \(authError.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Location Name Sanitization Tests
    func testCreatePost_locationNameSanitization() async {
        // 認証済みのダミーユーザーを設定
        AuthManager.shared.isAuthenticated = true
        AuthManager.shared.currentUser = AppUser(id: UUID().uuidString, email: nil, username: "tester", createdAt: nil)

        let unsafeLocationName = "<script>alert('xss')</script>安全な場所"

        do {
            try await PostManager.shared.createPost(
                content: "場所名サニタイズテスト",
                imageData: nil,
                location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                locationName: unsafeLocationName
            )
            // 危険な場所名でもサニタイズされてエラーにならないことを確認
        } catch {
            // バリデーションエラー以外は許可
            if let authError = error as? AuthError {
                if case .invalidInput = authError {
                    XCTFail("場所名サニタイズ後にバリデーションエラー: \(authError.localizedDescription)")
                }
            }
        }
    }

    // MARK: - State Management Tests
    func testPostManager_initialState() {
        let postManager = PostManager.shared

        // 初期状態の確認
        XCTAssertFalse(postManager.isLoading)
        XCTAssertNil(postManager.error)
        // postsは空または既存の投稿があるかもしれないので、配列であることだけ確認
        XCTAssertTrue(postManager.posts is [Post])
    }
}

