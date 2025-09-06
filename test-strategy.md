# GLOBE App テスト戦略計画書

## 📋 エグゼクティブサマリー
GLOBEアプリケーションの品質保証とバグ削減を目的とした、包括的なテスト戦略の実装計画です。現在テストカバレッジ0%から80%を目指します。

---

## 🎯 テスト目標と原則

### 主要目標
1. **コードカバレッジ**: 80%以上
2. **クリティカルパスカバレッジ**: 100%
3. **回帰バグ削減率**: 90%
4. **デプロイ失敗率**: 5%以下

### テスト原則
- **テストピラミッド構造**: Unit(70%) → Integration(20%) → E2E(10%)
- **TDD/BDD アプローチ**: 新機能開発時にテストファースト
- **継続的テスト**: CI/CDパイプラインでの自動実行
- **独立性**: 各テストは独立して実行可能

---

## 🏗️ テストアーキテクチャ

### テストフレームワーク選定
```swift
// Unit Testing
import XCTest

// UI Testing  
import XCTest

// Mocking
import Mockingbird // or Swift自作Mock

// Snapshot Testing
import SnapshotTesting

// Performance Testing
import XCTest
```

### テストディレクトリ構造
```
GLOBETests/
├── Unit/
│   ├── Core/
│   │   ├── Auth/
│   │   │   ├── AuthManagerTests.swift
│   │   │   └── AuthValidationTests.swift
│   │   ├── Security/
│   │   │   ├── InputValidatorTests.swift
│   │   │   ├── SecureLoggerTests.swift
│   │   │   └── DatabaseSecurityTests.swift
│   │   └── Services/
│   │       └── CoreServicesTests.swift
│   ├── Features/
│   │   ├── Profile/
│   │   │   └── MyPageViewModelTests.swift
│   │   └── Posts/
│   │       └── PostManagerTests.swift
│   ├── Models/
│   │   ├── PostTests.swift
│   │   ├── CommentTests.swift
│   │   └── UserTests.swift
│   └── Services/
│       ├── SupabaseServiceTests.swift
│       ├── CommentServiceTests.swift
│       └── LikeServiceTests.swift
├── Integration/
│   ├── Auth/
│   │   └── AuthFlowTests.swift
│   ├── Database/
│   │   └── SupabaseIntegrationTests.swift
│   └── Map/
│       └── LocationServicesTests.swift
├── UI/
│   ├── Screens/
│   │   ├── MainTabViewUITests.swift
│   │   ├── ProfileViewUITests.swift
│   │   └── PostCreationUITests.swift
│   └── Components/
│       ├── PostPinUITests.swift
│       └── PostPopupUITests.swift
├── Snapshot/
│   ├── ComponentSnapshotTests.swift
│   └── ScreenSnapshotTests.swift
├── Performance/
│   ├── MapPerformanceTests.swift
│   └── ImageLoadingTests.swift
└── Helpers/
    ├── TestHelpers.swift
    ├── MockFactory.swift
    └── TestData.swift
```

---

## 📝 テスト実装計画

### Phase 1: 基盤構築（週1-2）
#### 目標: テスト環境のセットアップと基本的なテストの作成

**タスク:**
1. [ ] XCTestプロジェクト設定
2. [ ] テストヘルパーとユーティリティの作成
3. [ ] Mockフレームワークの導入と設定
4. [ ] CI/CDパイプラインへのテスト統合

**対象テスト:**
```swift
// InputValidatorTests.swift
class InputValidatorTests: XCTestCase {
    func testEmailValidation() {
        // Valid emails
        XCTAssertTrue(InputValidator.isValidEmail("user@example.com"))
        XCTAssertTrue(InputValidator.isValidEmail("test.user+tag@domain.co.jp"))
        
        // Invalid emails
        XCTAssertFalse(InputValidator.isValidEmail("invalid.email"))
        XCTAssertFalse(InputValidator.isValidEmail("@domain.com"))
        XCTAssertFalse(InputValidator.isValidEmail("user@"))
    }
    
    func testPasswordStrength() {
        XCTAssertEqual(InputValidator.passwordStrength("abc"), .weak)
        XCTAssertEqual(InputValidator.passwordStrength("Abc123"), .medium)
        XCTAssertEqual(InputValidator.passwordStrength("Abc123!@#"), .strong)
    }
    
    func testSQLInjectionPrevention() {
        let maliciousInput = "'; DROP TABLE users; --"
        let sanitized = InputValidator.sanitizeSQL(maliciousInput)
        XCTAssertFalse(sanitized.contains("DROP"))
    }
}
```

### Phase 2: コアビジネスロジック（週3-4）
#### 目標: 重要なビジネスロジックの完全なテストカバレッジ

**対象モジュール:**
- AuthManager（認証フロー）
- SupabaseService（データベース操作）
- PostManager（投稿管理）
- Security モジュール全般

**テスト例:**
```swift
// AuthManagerTests.swift
class AuthManagerTests: XCTestCase {
    var authManager: AuthManager!
    var mockSupabase: MockSupabaseClient!
    
    override func setUp() {
        super.setUp()
        mockSupabase = MockSupabaseClient()
        authManager = AuthManager(client: mockSupabase)
    }
    
    func testSuccessfulSignIn() async throws {
        // Arrange
        mockSupabase.mockUser = MockUser(id: "123", email: "test@example.com")
        
        // Act
        let result = try await authManager.signIn(email: "test@example.com", password: "password123")
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result.email, "test@example.com")
    }
    
    func testRateLimiting() async {
        // Attempt multiple failed logins
        for _ in 0..<6 {
            _ = try? await authManager.signIn(email: "test@example.com", password: "wrong")
        }
        
        // Should be rate limited
        do {
            _ = try await authManager.signIn(email: "test@example.com", password: "correct")
            XCTFail("Should have been rate limited")
        } catch AuthError.rateLimitExceeded {
            // Expected
        }
    }
}
```

### Phase 3: ViewModelテスト（週5-6）
#### 目標: すべてのViewModelのテスト実装

**対象:**
- MyPageViewModel
- 新規作成するViewModel（PostDetailViewModel, UserSearchViewModel等）

**テスト例:**
```swift
// MyPageViewModelTests.swift
class MyPageViewModelTests: XCTestCase {
    var viewModel: MyPageViewModel!
    var mockService: MockSupabaseService!
    
    override func setUp() {
        super.setUp()
        mockService = MockSupabaseService()
        viewModel = MyPageViewModel(supabaseService: mockService)
    }
    
    func testLoadUserData() async {
        // Arrange
        let expectedUser = AppUser(
            id: "123",
            username: "testuser",
            profileImageUrl: "https://example.com/image.jpg"
        )
        mockService.mockUser = expectedUser
        
        // Act
        await viewModel.loadUserData()
        
        // Assert
        XCTAssertEqual(viewModel.username, "testuser")
        XCTAssertEqual(viewModel.profileImageUrl, "https://example.com/image.jpg")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testPostCreation() async {
        // Arrange
        let postContent = "Test post"
        let location = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        
        // Act
        let success = await viewModel.createPost(content: postContent, location: location)
        
        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(mockService.lastCreatedPost?.content, postContent)
    }
}
```

### Phase 4: Integration テスト（週7-8）
#### 目標: コンポーネント間の連携テスト

**重点領域:**
```swift
// AuthFlowIntegrationTests.swift
class AuthFlowIntegrationTests: XCTestCase {
    func testCompleteSignUpFlow() async throws {
        // 1. Sign up
        let authManager = AuthManager.shared
        let newUser = try await authManager.signUp(
            email: "newuser@example.com",
            password: "SecurePass123!",
            username: "newuser"
        )
        
        // 2. Verify profile creation
        let profile = try await SupabaseService.shared.getUserProfile(userId: newUser.id)
        XCTAssertEqual(profile.username, "newuser")
        
        // 3. Test auto-login
        XCTAssertNotNil(authManager.currentUser)
        
        // 4. Create first post
        let post = try await PostManager.shared.createPost(
            content: "My first post",
            userId: newUser.id
        )
        XCTAssertNotNil(post.id)
    }
}
```

### Phase 5: UI テスト（週9-10）
#### 目標: 主要な画面フローのE2Eテスト

**テストシナリオ:**
```swift
// MainFlowUITests.swift
class MainFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    func testCreatePostFlow() {
        // Navigate to create post
        app.tabBars.buttons["Create"].tap()
        
        // Enter post content
        let textView = app.textViews["postContentTextView"]
        textView.tap()
        textView.typeText("This is a UI test post")
        
        // Select privacy
        app.buttons["privacyButton"].tap()
        app.buttons["publicOption"].tap()
        
        // Post
        app.buttons["postButton"].tap()
        
        // Verify post appears
        XCTAssertTrue(app.staticTexts["This is a UI test post"].waitForExistence(timeout: 5))
    }
    
    func testProfileNavigation() {
        // Go to profile
        app.tabBars.buttons["Profile"].tap()
        
        // Verify profile elements
        XCTAssertTrue(app.images["profileImage"].exists)
        XCTAssertTrue(app.staticTexts["username"].exists)
        
        // Open settings
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }
}
```

### Phase 6: Snapshot テスト（週11）
#### 目標: UIの視覚的回帰テスト

```swift
// ComponentSnapshotTests.swift
class ComponentSnapshotTests: XCTestCase {
    func testPostPinVariations() {
        let sizes: [CGFloat] = [40, 72, 96]
        let post = MockData.samplePost()
        
        for size in sizes {
            let view = PostPin(post: post, size: size)
            assertSnapshot(matching: view, as: .image(size: CGSize(width: size, height: size)))
        }
    }
    
    func testDarkModeSupport() {
        let view = MainTabView()
        
        // Light mode
        assertSnapshot(matching: view, as: .image(traits: .init(userInterfaceStyle: .light)))
        
        // Dark mode
        assertSnapshot(matching: view, as: .image(traits: .init(userInterfaceStyle: .dark)))
    }
}
```

### Phase 7: Performance テスト（週12）
#### 目標: パフォーマンスボトルネックの特定と改善

```swift
// MapPerformanceTests.swift
class MapPerformanceTests: XCTestCase {
    func testLargeNumberOfPins() {
        let posts = (0..<1000).map { _ in MockData.randomPost() }
        
        measure {
            let mapView = MapView(posts: posts)
            _ = mapView.body
        }
    }
    
    func testImageCaching() {
        let imageURLs = (0..<100).map { "https://example.com/image\($0).jpg" }
        
        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
            for url in imageURLs {
                ImageCache.shared.loadImage(from: url)
            }
        }
    }
}
```

---

## 🔧 テストツールとユーティリティ

### Mock Factory
```swift
// MockFactory.swift
class MockFactory {
    static func createMockUser(
        id: String = UUID().uuidString,
        username: String = "testuser",
        email: String = "test@example.com"
    ) -> AppUser {
        return AppUser(
            id: id,
            username: username,
            email: email,
            profileImageUrl: nil,
            bio: nil,
            createdAt: Date()
        )
    }
    
    static func createMockPost(
        author: AppUser? = nil,
        content: String = "Test post content",
        location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    ) -> Post {
        let user = author ?? createMockUser()
        return Post(
            id: UUID().uuidString,
            content: content,
            authorId: user.id,
            location: location,
            createdAt: Date(),
            likes: 0,
            comments: []
        )
    }
}
```

### Test Helpers
```swift
// TestHelpers.swift
extension XCTestCase {
    func waitForAsync(
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        line: UInt = #line,
        _ block: @escaping () async throws -> Void
    ) {
        let expectation = expectation(description: "Async operation")
        
        Task {
            do {
                try await block()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)", file: file, line: line)
            }
        }
        
        wait(for: [expectation], timeout: timeout)
    }
}
```

---

## 📊 メトリクスと成功指標

### カバレッジ目標
| モジュール | 目標カバレッジ | 優先度 |
|---------|------------|-------|
| Security | 95% | 🔴 High |
| Auth | 90% | 🔴 High |
| Services | 85% | 🔴 High |
| ViewModels | 80% | 🟡 Medium |
| Views | 60% | 🟢 Low |
| UI Components | 70% | 🟡 Medium |

### パフォーマンス基準
- 単体テスト実行時間: < 10秒
- 統合テスト実行時間: < 1分
- E2Eテスト実行時間: < 5分
- CI/CDパイプライン全体: < 15分

---

## 🚀 CI/CD 統合

### GitHub Actions 設定
```yaml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  unit-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_14.3.app
      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -scheme GLOBE \
            -destination 'platform=iOS Simulator,name=iPhone 14' \
            -only-testing:GLOBETests/Unit
      - name: Upload Coverage
        uses: codecov/codecov-action@v3

  integration-tests:
    runs-on: macos-latest
    needs: unit-tests
    steps:
      - name: Run Integration Tests
        run: |
          xcodebuild test \
            -scheme GLOBE \
            -destination 'platform=iOS Simulator,name=iPhone 14' \
            -only-testing:GLOBETests/Integration

  ui-tests:
    runs-on: macos-latest
    needs: integration-tests
    steps:
      - name: Run UI Tests
        run: |
          xcodebuild test \
            -scheme GLOBE \
            -destination 'platform=iOS Simulator,name=iPhone 14' \
            -only-testing:GLOBETests/UI
```

---

## 📅 実装スケジュール

### マイルストーン
| 週 | フェーズ | 成果物 | カバレッジ目標 |
|----|---------|--------|--------------|
| 1-2 | Phase 1 | テスト基盤 | 10% |
| 3-4 | Phase 2 | コアロジックテスト | 30% |
| 5-6 | Phase 3 | ViewModelテスト | 50% |
| 7-8 | Phase 4 | 統合テスト | 65% |
| 9-10 | Phase 5 | UIテスト | 75% |
| 11 | Phase 6 | Snapshotテスト | 78% |
| 12 | Phase 7 | Performanceテスト | 80% |

---

## 🎓 チーム教育計画

### トレーニング項目
1. **TDD/BDD 基礎** (4時間)
   - Red-Green-Refactorサイクル
   - テストファースト開発

2. **Mock/Stub パターン** (2時間)
   - Dependency Injection
   - Protocol-oriented testing

3. **XCTest Advanced** (3時間)
   - Async/Await testing
   - Performance testing
   - Memory leak detection

4. **CI/CD ベストプラクティス** (2時間)
   - テストの並列実行
   - Flaky test の対処

---

## 📝 ベストプラクティス

### テスト命名規則
```swift
// Format: test_[状況]_[期待される結果]
func test_whenEmailIsInvalid_shouldReturnFalse()
func test_givenUserIsLoggedIn_whenSignOutCalled_shouldClearSession()
```

### AAA パターン
```swift
func testExample() {
    // Arrange (準備)
    let input = "test data"
    
    // Act (実行)
    let result = functionUnderTest(input)
    
    // Assert (検証)
    XCTAssertEqual(result, expectedValue)
}
```

### テストの独立性
- 各テストは他のテストに依存しない
- テスト順序に関係なく実行可能
- テスト後のクリーンアップを確実に実行

---

## ⚠️ リスクと対策

### リスク
1. **テスト実装の遅延**
   - 対策: 段階的実装とクリティカルパス優先

2. **Flaky Tests**
   - 対策: 非同期処理の適切な待機、モックの活用

3. **メンテナンスコスト増大**
   - 対策: Page Object Pattern、共通ヘルパーの活用

4. **パフォーマンス劣化**
   - 対策: 並列実行、テストの最適化

---

## 📚 参考資料

### ドキュメント
- [Apple: Testing in Xcode](https://developer.apple.com/documentation/xcode/testing-in-xcode)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing Best Practices](https://www.swiftbysundell.com/articles/unit-testing-best-practices/)

### 推奨ツール
- [Mockingbird](https://github.com/birdrides/mockingbird) - Mocking framework
- [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) - Snapshot tests
- [XCTestHTMLReport](https://github.com/XCTestHTMLReport/XCTestHTMLReport) - Test reporting

---

## ✅ 完了チェックリスト

- [ ] 全モジュールのユニットテスト実装
- [ ] 統合テストカバレッジ80%達成
- [ ] CI/CDパイプライン統合完了
- [ ] パフォーマンステスト基準クリア
- [ ] テストドキュメント整備
- [ ] チームトレーニング完了
- [ ] コードレビュープロセス確立
- [ ] テスト自動化の定期実行設定