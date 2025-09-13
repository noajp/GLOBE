# 🏗️ **GLOBE リファクタリング計画書**

## 📋 **コードベース分析結果**

### **現在のアーキテクチャ概要:**
- **設計パターン**: MVVM + ObservableObject
- **UI フレームワーク**: SwiftUI
- **バックエンド**: Supabase
- **認証システム**: カスタム AuthManager (シングルトン)
- **状態管理**: Combine + @Published

---

## 🎯 **包括的リファクタリング計画**

### **Phase 1: アーキテクチャ基盤の強化** ⏰ 推定: 3-4日

#### **1.1 依存性注入システムの実装**
- [ ] DependencyContainer プロトコルの作成
- [ ] ServiceLocator パターンの実装
- [ ] AuthManager の シングルトン依存を削除
- [ ] PostManager の依存性注入対応
- [ ] ProfileImageCacheManager の依存性注入対応

#### **1.2 プロトコル指向設計への移行**
- [ ] AuthServiceProtocol の定義
- [ ] PostServiceProtocol の定義
- [ ] CacheServiceProtocol の定義
- [ ] LocationServiceProtocol の定義
- [ ] 各Manager クラスのプロトコル準拠

#### **1.3 エラーハンドリングの統一**
- [ ] AppError enum の作成
- [ ] Result<Success, AppError> パターンの導入
- [ ] 全 async/await メソッドのエラーハンドリング統一
- [ ] ユーザー向けエラーメッセージの国際化準備

### **Phase 2: ビューアーキテクチャの改善** ⏰ 推定: 2-3日

#### **2.1 ViewModels の分離と責任明確化**
- [ ] MainTabViewModelの作成 (現在View内にロジックが混在)
- [ ] PostCreationViewModel の作成
- [ ] MapViewModel の分離
- [ ] UserProfileViewModel の最適化

#### **2.2 View の責任分離**
- [ ] MainTabView の巨大化解消 (現在500行超)
- [ ] MapContentView の独立したコンポーネント化
- [ ] PostPopupView のロジック分離
- [ ] 再利用可能コンポーネントの抽出

#### **2.3 ナビゲーション管理の改善**
- [ ] NavigationManager の作成
- [ ] Deep Link 対応の準備
- [ ] Sheet/FullScreenCover 管理の統一

### **Phase 3: データレイヤーの最適化** ⏰ 推定: 2-3日

#### **3.1 Repository パターンの実装**
- [ ] UserRepository の作成
- [ ] PostRepository の作成
- [ ] CacheRepository の作成
- [ ] Supabase アクセスの Repository 経由化

#### **3.2 ローカルデータ管理の強化**
- [ ] CoreData / SQLite 導入検討
- [ ] オフライン対応の基盤作成
- [ ] データ同期戦略の実装
- [ ] キャッシュ戦略の最適化

#### **3.3 API レイヤーの抽象化**
- [ ] APIClient プロトコルの作成
- [ ] SupabaseClient の抽象化
- [ ] ネットワークエラーハンドリングの改善
- [ ] リトライ機構の実装

### **Phase 4: 状態管理の改善** ⏰ 推定: 2日

#### **4.1 Redux-like パターンの導入検討**
- [ ] AppState の定義
- [ ] Action/Reducer パターンの実装
- [ ] 状態の一元管理
- [ ] 状態変更の追跡可能性向上

#### **4.2 Combine の最適化**
- [ ] Publisher チェーンの最適化
- [ ] メモリリーク防止の強化
- [ ] 非同期処理の統一

### **Phase 5: パフォーマンス最適化** ⏰ 推定: 2日

#### **5.1 レンダリング最適化**
- [ ] @ViewBuilder の適切な使用
- [ ] LazyVStack/LazyHStack の活用
- [ ] Image キャッシュ戦略の改善
- [ ] メモリ使用量の最適化

#### **5.2 ネットワーク最適化**
- [ ] バッチリクエストの実装
- [ ] プリフェッチ戦略の改善
- [ ] 画像圧縮の最適化
- [ ] CDN 活用の検討

### **Phase 6: テスタビリティの向上** ⏰ 推定: 2-3日

#### **6.1 ユニットテストの強化**
- [ ] ViewModels のテスト追加
- [ ] Repository のテスト追加
- [ ] Service クラスのテスト追加
- [ ] モック/スタブの整備

#### **6.2 UIテストの改善**
- [ ] 画面遷移テストの追加
- [ ] ユーザーフローテストの作成
- [ ] アクセシビリティテストの追加

### **Phase 7: セキュリティ強化** ⏰ 推定: 1-2日

#### **7.1 データ保護の強化**
- [ ] Keychain 使用の最適化
- [ ] 機密データの暗号化
- [ ] メモリ上での機密情報管理

#### **7.2 通信セキュリティ**
- [ ] Certificate Pinning の実装
- [ ] API レスポンス検証の強化

### **Phase 8: 開発者エクスペリエンスの改善** ⏰ 推定: 1日

#### **8.1 ツールチェーンの改善**
- [ ] SwiftLint ルールの最適化
- [ ] CI/CD パイプラインの改善
- [ ] ドキュメンテーションの充実

#### **8.2 デバッグ機能の強化**
- [ ] ログシステムの改善
- [ ] デバッグ情報の可視化
- [ ] パフォーマンス監視の追加

---

## 🚨 **優先度別タスク分類**

### **🔴 高優先度 (即座に対応)**
- [ ] MainTabView の巨大化解消
- [ ] AuthManager のシングルトン依存削除
- [ ] エラーハンドリングの統一
- [ ] メモリリーク防止の強化

### **🟡 中優先度 (Phase 2-3で対応)**
- [ ] Repository パターンの実装
- [ ] ViewModel の分離
- [ ] キャッシュ戦略の改善

### **🟢 低優先度 (Phase 4以降)**
- [ ] Redux-like パターンの導入
- [ ] オフライン対応
- [ ] パフォーマンス最適化

---

## 📏 **実装ガイドライン**

### **コーディング規約**
- [ ] Swift API Design Guidelines の厳守
- [ ] SOLID 原則の適用
- [ ] DRY 原則の徹底
- [ ] 命名規約の統一

### **アーキテクチャ原則**
- [ ] 単一責任原則の適用
- [ ] 依存性逆転原則の実装
- [ ] 関心の分離
- [ ] テスタビリティの確保

---

## 🎯 **成功指標**

### **品質指標**
- [ ] コードカバレッジ 80% 以上
- [ ] 循環的複雑度 10 以下
- [ ] ファイルサイズ 300行以下
- [ ] 依存関係の深さ 3階層以下

### **パフォーマンス指標**
- [ ] アプリ起動時間 2秒以下
- [ ] 画面遷移時間 0.5秒以下
- [ ] メモリ使用量 50MB以下
- [ ] クラッシュ率 0.1% 以下

---

## 📈 **実装進捗管理**

### **完了済みタスク**
各タスク完了時に以下のように更新してください：
```
- [X] 完了したタスク名
```

### **進行中タスク**
現在作業中のタスクは以下のようにマークしてください：
```
- [🔄] 進行中のタスク名
```

---

## 🔧 **技術的考慮事項**

### **互換性**
- iOS 15.0+ 対応維持
- SwiftUI 3.0+ 機能活用
- Supabase Swift SDK 最新版対応

### **パフォーマンス**
- メモリリーク防止
- CPU使用率最適化
- バッテリー消費削減
- ネットワーク効率化

### **メンテナンス性**
- コード可読性向上
- ドキュメント整備
- テストカバレッジ拡充
- 依存関係最小化

---

## 🧪 **包括的テスト戦略**

### **テスト目標と原則**

#### **主要目標**
- [ ] **コードカバレッジ**: 80%以上
- [ ] **クリティカルパスカバレッジ**: 100%
- [ ] **回帰バグ削減率**: 90%
- [ ] **デプロイ失敗率**: 5%以下

#### **テスト原則**
- [ ] **テストピラミッド構造**: Unit(70%) → Integration(20%) → E2E(10%)
- [ ] **TDD/BDD アプローチ**: 新機能開発時にテストファースト
- [ ] **継続的テスト**: CI/CDパイプラインでの自動実行
- [ ] **独立性**: 各テストは独立して実行可能

### **テストフレームワーク選定**
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

### **テスト実装計画 (Phase 6との統合)**

#### **Phase 6.1: テスト基盤構築** ⏰ 推定: 1-2週
- [ ] XCTestプロジェクト設定
- [ ] テストヘルパーとユーティリティの作成
- [ ] Mockフレームワークの導入と設定
- [ ] CI/CDパイプラインへのテスト統合

#### **Phase 6.2: コアビジネスロジックテスト** ⏰ 推定: 1-2週
- [ ] AuthManager（認証フロー）のテスト
- [ ] SupabaseService（データベース操作）のテスト
- [ ] PostManager（投稿管理）のテスト
- [ ] Security モジュール全般のテスト

#### **Phase 6.3: ViewModelテスト** ⏰ 推定: 1-2週
- [ ] MyPageViewModel テスト
- [ ] PostCreationViewModel テスト
- [ ] MapViewModel テスト
- [ ] UserProfileViewModel テスト

#### **Phase 6.4: 統合テスト** ⏰ 推定: 1週
- [ ] 認証フロー統合テスト
- [ ] データベース統合テスト
- [ ] 位置情報サービス統合テスト

#### **Phase 6.5: UIテスト** ⏰ 推定: 1-2週
- [ ] メイン画面フローのE2Eテスト
- [ ] 投稿作成フローテスト
- [ ] プロフィール画面ナビゲーションテスト
- [ ] アクセシビリティテスト

#### **Phase 6.6: Snapshotテスト** ⏰ 推定: 3日
- [ ] コンポーネントの視覚的回帰テスト
- [ ] ダークモード対応テスト
- [ ] 各画面のスナップショットテスト

#### **Phase 6.7: パフォーマンステスト** ⏰ 推定: 3日
- [ ] マップパフォーマンステスト
- [ ] 画像ロードパフォーマンステスト
- [ ] メモリ使用量テスト
- [ ] CPU使用率テスト

### **テストディレクトリ構造**
```
GLOBETests/
├── Unit/
│   ├── Core/
│   │   ├── Auth/
│   │   │   ├── [ ] AuthManagerTests.swift
│   │   │   └── [ ] AuthValidationTests.swift
│   │   ├── Security/
│   │   │   ├── [ ] InputValidatorTests.swift
│   │   │   ├── [ ] SecureLoggerTests.swift
│   │   │   └── [ ] DatabaseSecurityTests.swift
│   │   └── Services/
│   │       └── [ ] CoreServicesTests.swift
│   ├── Features/
│   │   ├── Profile/
│   │   │   └── [ ] MyPageViewModelTests.swift
│   │   └── Posts/
│   │       └── [ ] PostManagerTests.swift
│   ├── Models/
│   │   ├── [ ] PostTests.swift
│   │   ├── [ ] CommentTests.swift
│   │   └── [ ] UserTests.swift
│   └── Services/
│       ├── [ ] SupabaseServiceTests.swift
│       ├── [ ] CommentServiceTests.swift
│       └── [ ] LikeServiceTests.swift
├── Integration/
│   ├── Auth/
│   │   └── [ ] AuthFlowTests.swift
│   ├── Database/
│   │   └── [ ] SupabaseIntegrationTests.swift
│   └── Map/
│       └── [ ] LocationServicesTests.swift
├── UI/
│   ├── Screens/
│   │   ├── [ ] MainTabViewUITests.swift
│   │   ├── [ ] ProfileViewUITests.swift
│   │   └── [ ] PostCreationUITests.swift
│   └── Components/
│       ├── [ ] PostPinUITests.swift
│       └── [ ] PostPopupUITests.swift
├── Snapshot/
│   ├── [ ] ComponentSnapshotTests.swift
│   └── [ ] ScreenSnapshotTests.swift
├── Performance/
│   ├── [ ] MapPerformanceTests.swift
│   └── [ ] ImageLoadingTests.swift
└── Helpers/
    ├── [ ] TestHelpers.swift
    ├── [ ] MockFactory.swift
    └── [ ] TestData.swift
```

### **カバレッジ目標**
| モジュール | 目標カバレッジ | 優先度 |
|---------|------------|-------|
| Security | [ ] 95% | 🔴 High |
| Auth | [ ] 90% | 🔴 High |
| Services | [ ] 85% | 🔴 High |
| ViewModels | [ ] 80% | 🟡 Medium |
| Views | [ ] 60% | 🟢 Low |
| UI Components | [ ] 70% | 🟡 Medium |

### **CI/CD テスト統合**
- [ ] GitHub Actions でのテスト自動実行
- [ ] Pull Request でのテスト必須化
- [ ] カバレッジレポート自動生成
- [ ] パフォーマンス回帰の自動検出

### **テスト実装例**

#### **ユニットテスト例:**
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
        // Rate limiting test implementation
        for _ in 0..<6 {
            _ = try? await authManager.signIn(email: "test@example.com", password: "wrong")
        }

        do {
            _ = try await authManager.signIn(email: "test@example.com", password: "correct")
            XCTFail("Should have been rate limited")
        } catch AuthError.rateLimitExceeded {
            // Expected
        }
    }
}
```

#### **UIテスト例:**
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
}
```

### **テストユーティリティ**
- [ ] MockFactory クラスの作成
- [ ] TestHelpers の実装
- [ ] 共通テストデータの準備
- [ ] 非同期テスト用ヘルパー

### **パフォーマンス基準**
- [ ] 単体テスト実行時間: < 10秒
- [ ] 統合テスト実行時間: < 1分
- [ ] E2Eテスト実行時間: < 5分
- [ ] CI/CDパイプライン全体: < 15分

---

**📅 作成日**: 2024年12月
**📝 作成者**: Claude with Serena MCP
**🔄 最終更新**: 初版

---

この計画は段階的に実行し、各フェーズ完了時に品質確認とテストを行うことを推奨します。各タスクの完了時に `[ ]` を `[X]` に変更して進捗を追跡してください。