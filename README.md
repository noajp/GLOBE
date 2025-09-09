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

### Directory Structure

```
GLOBE/
├── 📁 Application/          # App entry point & configuration
│   ├── GlobeApp.swift
│   └── AppDelegate.swift
├── 📁 Core/                 # Core components
│   ├── Auth/               # Authentication logic
│   ├── Managers/           # Business logic managers
│   ├── Security/           # Security utilities
│   └── Supabase/          # Database client
├── 📁 Models/               # Data models
│   ├── Post.swift
│   ├── User.swift
│   └── Comment.swift
├── 📁 Views/                # UI components
│   ├── MainTabView.swift
│   ├── CreatePostView.swift
│   └── Components/
├── 📁 Services/             # External services
│   ├── SupabaseService.swift
│   ├── LikeService.swift
│   └── CommentService.swift
├── 📁 Features/             # Feature modules
│   └── Profile/
└── 📁 Resources/            # Assets & configs
```

### Key Components

| Component | Description |
|-----------|------------|
| `AuthManager` | 認証状態の管理とセッション制御 |
| `PostManager` | 投稿の作成・取得・削除 |
| `MapLocationService` | 位置情報サービスの管理 |
| `InputValidator` | 入力値の検証とサニタイズ |
| `SecureLogger` | セキュアなロギングシステム |

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