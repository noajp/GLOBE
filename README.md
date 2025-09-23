# 🌍 GLOBE - Location-Based Social Media App

<div align="center">

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)
![Supabase](https://img.shields.io/badge/Supabase-2.0-black.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

**Share your moments on the map, discover stories around you**

[Features](#✨-features) • [Tech Stack](#🛠️-tech-stack) • [Getting Started](#🚀-getting-started) • [Architecture](#📐-architecture) • [Contributing](#🤝-contributing)

</div>

---

## 📱 Overview

GLOBEは、位置情報に基づいて投稿を地図上に表示する革新的なソーシャルメディアアプリです。ユーザーは現在地や任意の場所に写真やテキストを投稿し、他のユーザーの投稿を地図上で探索できます。投稿は24時間後に自動的に消去され、常に新鮮なコンテンツが表示されます。

### ✨ Features

- 🗺️ **Map-Based Posts** - 投稿を地図上にピン留め
- 💬 **Speech Bubble UI** - 投稿が吹き出しとして表示
- 📍 **Location Privacy** - エリア名のみ表示（詳細住所は非公開）
- ⏰ **24-Hour Expiration** - 投稿は24時間後に自動削除
- 🔍 **Zoom-Based Filtering** - ズームレベルに応じた投稿表示
- 📸 **Photo Sharing** - 写真付き投稿のサポート
- 👤 **Profile Customization** - アバター画像のアップロード
- 🔒 **Secure Authentication** - Supabase認証による安全なログイン

## 🛠️ Tech Stack

### Frontend
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Maps**: MapKit
- **Location**: CoreLocation
- **Concurrency**: Swift Concurrency (async/await)

### Backend
- **BaaS**: Supabase
- **Database**: PostgreSQL
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage
- **Real-time**: Supabase Realtime (予定)

### Security
- **Input Validation**: カスタムバリデーター実装
- **RLS**: Row Level Security on all tables
- **Logging**: セキュアロギングシステム
- **Encryption**: エンドツーエンド暗号化（DM実装時）

## 📋 Requirements

- **Xcode**: 15.0+
- **iOS**: 17.0+
- **macOS**: 13.0+ (for development)
- **Supabase Account**: [Sign up here](https://supabase.com)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/GLOBE.git
cd GLOBE
```

### 2. Install Dependencies

```bash
# SwiftPMの依存関係は自動的に解決されます
open GLOBE.xcodeproj
```

### 3. Environment Setup

1. **Supabase Project Setup**:
   - [Supabase](https://supabase.com)でプロジェクトを作成
   - プロジェクトURLとAnon Keyを取得

2. **Configure Info.plist**:
   ```xml
   <key>SupabaseURL</key>
   <string>YOUR_SUPABASE_URL</string>
   <key>SupabaseAnonKey</key>
   <string>YOUR_SUPABASE_ANON_KEY</string>
   ```

3. **Database Migration**:
   ```sql
   -- Supabase SQL Editorで実行
   -- /Supabase/migrations/内のSQLファイルを順番に実行
   ```

### 4. Build and Run

```bash
# Command Line
xcodebuild -project GLOBE.xcodeproj -scheme GLOBE build

# または Xcode で
# 1. GLOBE.xcodeproj を開く
# 2. Target device を選択
# 3. Cmd+R で実行
```

## 📐 Architecture

GLOBEは**MVVM (Model-View-ViewModel)** パターンを採用しています。SwiftUIの`@StateObject`/`@ObservableObject`と相性が良く、シンプルで保守しやすい構成です。

### 🎯 アーキテクチャの意図

**なぜMVVMを選んだか？**
1. **SwiftUI親和性**: `@StateObject`/`@ObservableObject`と自然に統合
2. **関心の分離**: View、ViewModel、Modelの責任が明確
3. **テスタビリティ**: ViewModelを独立してテスト可能
4. **標準的**: iOSアプリ開発でよく使われる一般的なパターン

### 📂 ディレクトリ構造と責任

```
GLOBE/
├── 📱 Views/                # View層 - UIの表示とユーザー操作
│   ├── Main/               • メインタブビュー
│   ├── Auth/               • ログイン・サインアップ画面
│   ├── Profile/            • プロフィール関連画面
│   ├── Posts/              • 投稿作成・詳細画面
│   └── Components/         • 再利用可能UIコンポーネント
│       ├── Advanced/       • 高度なUI要素（ガラスエフェクトなど）
│       └── Shared/         • 基本UI要素
│
├── 🏗️ ViewModels/           # ViewModel層 - 状態管理とビジネスロジック
│   ├── AuthManager.swift   • 認証ViewModel（状態 + ログイン処理）
│   ├── PostManager.swift   • 投稿ViewModel（状態 + CRUD操作）
│   ├── MapManager.swift    • 地図ViewModel（状態 + 位置情報処理）
│   ├── AppSettings.swift   • アプリ設定ViewModel
│   └── MyPageViewModel.swift• プロフィール画面ViewModel
│
├── 📦 Models/               # Model層 - データ構造定義
│   ├── Post.swift          • 投稿データモデル
│   ├── Comment.swift       • コメントデータモデル
│   └── DatabaseModels.swift• DB関連モデル
│
├── 🌐 Repositories/         # Repository層 - データアクセス抽象化
│   └── SupabaseService.swift• Supabaseリポジトリ実装
│
├── 🔧 Shared/               # 共通機能・ユーティリティ
│   ├── Security/           • セキュリティユーティリティ
│   ├── Design/             • デザインシステム
│   ├── Logging/            • ログ機能
│   ├── Protocols/          • 共通インターフェース
│   ├── Supabase/           • データベースクライアント
│   └── UIImage+Extensions.swift • Swift拡張機能
│
├── 🚀 App/                  # アプリケーション層
│   ├── GlobeApp.swift      • アプリケーション起動点
│   └── ContentView.swift   • ルートビュー
│
└── 🗄️ Database/             # インフラ層
    └── migrations/         • データベースマイグレーション
```

### 🔄 データフローと責任

```
👆 User Action
    ⬇️
📱 View (SwiftUI)           ← UI表示・ユーザー操作受付
    ⬇️
🏗️ ViewModel (ObservableObject) ← 状態管理・ビジネスロジック実行
    ⬇️
🌐 Repository               ← データアクセス抽象化
    ⬇️
📦 Model                    ← データ構造・ビジネスルール
    ⬇️
🗄️ Database/API             ← データ永続化・外部サービス
```

### 🎭 各層の具体的な役割

#### 📱 Views層 - 「UI表示とユーザー操作」
**MVVMにおけるView層の責任**:
- UI表示とレイアウト
- ユーザー操作の受け取り
- ViewModelの監視（`@StateObject`, `@ObservedObject`）
- ローカルUI状態の管理（`@State`でモーダル表示など）

**やらないこと**:
- ビジネスロジックの実装
- データの永続化
- 複雑な状態計算

```swift
// ✅ Good - UIロジックのみ
struct PostListView: View {
    @StateObject private var postManager = PostManager.shared
    @State private var showCreatePost = false

    var body: some View {
        List(postManager.posts) { post in
            PostRowView(post: post)
        }
        .onAppear {
            Task { await postManager.fetchPosts() }
        }
    }
}
```

#### 🏗️ ViewModels層 - 「状態管理とビジネスロジック」
**MVVMにおけるViewModel層の責任**:
- アプリケーション状態の管理（`@Published`）
- ビジネスルールとロジックの実装
- 入力値の検証と変換
- Repository/Serviceとの連携
- ViewとModelの仲介

**やらないこと**:
- UIの直接操作や参照
- データ構造の定義（それはModel層）

```swift
// ✅ Good - ビジネスロジックと状態管理
@MainActor
class PostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = SupabaseService.shared

    func createPost(content: String, location: CLLocationCoordinate2D) async {
        // 1. 入力検証
        guard !content.isEmpty else { return }

        // 2. ビジネスルール適用
        let post = Post(content: content, location: location, expiresAt: Date().addingTimeInterval(86400))

        // 3. Service呼び出し
        isLoading = true
        do {
            try await service.createPost(post)
            await fetchPosts() // 状態更新
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
```

#### 📦 Models層 - 「データ構造とビジネスルール」
**MVVMにおけるModel層の責任**:
- データ構造の定義（struct, class）
- ビジネスルールの実装（計算プロパティなど）
- データの永続化インターフェース（Codable準拠）
- ドメインロジック（`isExpired`など）

**やらないこと**:
- UI状態の管理（それはViewModel層）
- ネットワーク通信（それはRepository層）

```swift
// ✅ Good - 純粋なデータ構造
struct Post: Identifiable, Codable {
    let id: UUID
    let content: String
    let createdAt: Date
    let expiresAt: Date
    let location: CLLocationCoordinate2D

    // 計算プロパティは可
    var isExpired: Bool {
        Date() > expiresAt
    }
}
```

#### 🌐 Repositories層 - 「データアクセス抽象化」
**MVVMにおけるRepository層の責任**:
- 外部データソースとの通信（API、データベース）
- データの変換（DTO ↔ Model）
- データアクセスの抽象化（Protocolベース）
- エラーハンドリングとリトライ処理

**やらないこと**:
- ビジネスロジックの実装（それはViewModel層）
- UI状態の管理（それはViewModel層）

```swift
// ✅ Good - 外部通信に特化
@MainActor
class SupabaseService: ObservableObject {
    @Published var posts: [Post] = []

    func fetchPosts() async throws {
        let response = try await supabase
            .from("posts")
            .select()
            .execute()

        let decoder = JSONDecoder()
        self.posts = try decoder.decode([Post].self, from: response.data)
    }
}
```

### 🎯 MVVMパターンの利点

| 利点 | 説明 |
|-----|-----|
| 🧩 **関心の分離** | View、ViewModel、Modelの責任が明確に分離 |
| 🔄 **SwiftUI親和性** | `@StateObject`でViewModelを監視し自然なUI更新 |
| 🧪 **テスタビリティ** | ViewModelを独立してユニットテスト可能 |
| 📈 **再利用性** | ViewModelは複数のViewで再利用可能 |
| 🌍 **業界標準** | iOS開発で広く採用されている一般的なパターン |

### ⚠️ 避けるべきアンチパターン

```swift
// ❌ Bad - ViewにAPI呼び出し
struct BadPostView: View {
    func createPost() {
        // ViewでSupabaseを直接呼び出すのはNG
        supabase.from("posts").insert(post)
    }
}

// ❌ Bad - Modelに状態管理
struct BadPost: ObservableObject {
    @Published var isLoading = false
    func save() { /* ModelでAPI呼び出しはNG */ }
}

// ❌ Bad - Managerで複雑な継承
class BadBaseManager: ObservableObject { /* 複雑な継承はNG */ }
class BadPostManager: BadBaseManager { }
```

### 🔧 実装時のガイドライン

1. **ViewModel作成時**: `@MainActor`付与 + `ObservableObject`準拠
2. **View作成時**: `@StateObject`でViewModel監視
3. **Model設計時**: `struct`でイミュータブルなデータ構造
4. **Repository設計時**: Protocolベースで抽象化

## 🔧 Development

### Useful Commands

```bash
# テスト実行
xcodebuild test -scheme GLOBE -destination "platform=iOS Simulator,name=iPhone 16 Pro"

# ビルドクリーン
xcodebuild clean -project GLOBE.xcodeproj -scheme GLOBE

# シミュレータ起動
open -a Simulator
xcrun simctl boot "iPhone 16 Pro"

# ログ確認
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.yourcompany.GLOBE"'
```

### Debug Features

デバッグビルドでは以下の機能が利用可能:

- 🔍 Debug Logs View (`#if DEBUG`)
- 📍 Force Permission Request
- 🗄️ Database Inspector
- 📊 Performance Metrics

## 🐛 Troubleshooting

### Common Issues

<details>
<summary>📍 位置情報が取得できない</summary>

1. **シミュレータの場合**:
   - Features > Location > Custom Location を設定
   - または Apple Park などのプリセットを選択

2. **実機の場合**:
   - 設定 > プライバシー > 位置情報サービス を確認
   - GLOBEアプリの権限が「使用中のみ」になっているか確認
</details>

<details>
<summary>🔐 ログインできない</summary>

1. **Supabase設定を確認**:
   - Info.plist の SupabaseURL と SupabaseAnonKey を確認
   - Supabase Dashboard で Authentication が有効か確認

2. **ネットワーク接続**:
   - インターネット接続を確認
   - VPN使用時は無効化して再試行
</details>

<details>
<summary>📸 画像アップロードが失敗する</summary>

1. **Storage Bucket確認**:
   - Supabase Dashboard で `avatars` と `posts` バケットが存在するか確認
   - RLS ポリシーが正しく設定されているか確認

2. **権限確認**:
   - Info.plist に `NSPhotoLibraryUsageDescription` が設定されているか確認
</details>

## 🤝 Contributing

### Development Flow

1. **Feature Branch作成**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **コミット規約**:
   ```
   feat: 新機能追加
   fix: バグ修正
   docs: ドキュメント更新
   style: コードスタイル変更
   refactor: リファクタリング
   test: テスト追加・修正
   chore: ビルドプロセスやツールの変更
   ```

3. **Pull Request**:
   - テストが全て通ることを確認
   - コードレビューを受ける
   - main ブランチにマージ

### Code Style

- SwiftLint の規約に従う
- ファイルヘッダーを必ず追加:
  ```swift
  //======================================================================
  // MARK: - FileName.swift
  // Purpose: Brief description
  // Path: relative/path/to/file.swift
  //======================================================================
  ```

## 📚 Documentation

- [AGENTS.md](./AGENTS.md) - AI開発者向けガイドライン
- [CLAUDE.md](./CLAUDE.md) - Claude AI向け詳細仕様
- [refactoring.md](./refactoring.md) - リファクタリングTODOリスト
- [test-strategy.md](./test-strategy.md) - テスト戦略計画

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Developer**: [@yourusername](https://github.com/yourusername)
- **Design**: Minimal Design System
- **Backend**: Supabase Team

## 🙏 Acknowledgments

- [Supabase](https://supabase.com) - Backend as a Service
- [Apple MapKit](https://developer.apple.com/maps/) - Map Services
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - UI Framework

---

<div align="center">

**Made with ❤️ and SwiftUI**

[Report Bug](https://github.com/yourusername/GLOBE/issues) • [Request Feature](https://github.com/yourusername/GLOBE/issues)

</div>