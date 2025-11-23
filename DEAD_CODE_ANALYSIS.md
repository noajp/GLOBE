# GLOBE プロジェクト ファイル使用状況分析レポート

**分析日**: 2025-11-23
**プロジェクト**: GLOBE (iOS Map-Based Social Media App)
**分析方法**: グローバルグレップによる型参照追跡、プレビューのみ使用の検出

---

## 📊 統計サマリー

- **総Swift ファイル数**: 86
- **エントリーポイント（除外）**: 2 (GlobeApp.swift, ContentView.swift)
- **分析対象ファイル数**: 84
- **確実に未使用**: 1
- **プレビューのみで使用**: 7
- **使用中のファイル**: 76

---

## ⚠️ 未使用ファイル

### 確実に未使用 (優先度: 最高)

#### 1. **STILLEditProfileView.swift** (0行)
- **パス**: `/Users/nakanotakanori/Dev/GLOBE/GLOBE/Views/Profile/STILLEditProfileView.swift`
- **状態**: 完全に空のファイル
- **内容**: 単なたコメント「// This file has been replaced by EditProfileView.swift」のみ
- **参照**: どのファイルからも参照されていない
- **推奨**: **削除**

---

### プレビューのみで使用 (優先度: 中)

これらのコンポーネントは `#Preview` ブロック内でのみ使用されており、実際のアプリケーション内では使用されていません。

#### 1. **AuthenticationView.swift** (237行)
- **パス**: `/Users/nakanotakanori/Dev/GLOBE/GLOBE/Views/Auth/AuthenticationView.swift`
- **定義型**: `AuthenticationView`
- **参照**: Preview内のみ（3件）
- **用途**: 認証UI（SignUpFlow の方が実際に使われている）
- **推奨**: 削除検討 - SignUpView / SignInView の方が実運用

#### 2. **PostTypeSelector.swift** (160行)
- **パス**: `/Users/nakanotakanori/Dev/GLOBE/GLOBE/Views/Components/PostTypeSelector.swift`
- **定義型**: `PostTypeSelector`
- **参照**: Preview内のみ
- **用途**: 投稿タイプ選択UI（未実装？）
- **推奨**: 削除検討 - CreatePostView で別の方法で実装されている

#### 3. **CommentsSheet.swift** (243行)
- **パス**: `/Users/nakanotakanori/Dev/GLOBE/GLOBE/Views/Components/CommentsSheet.swift`
- **定義型**: `CommentsSheet`
- **副型**: `CommentRow` (同じく未使用)
- **参照**: Preview内のみ
- **用途**: コメント表示シート（未実装）
- **推奨**: 削除検討 - PostPin が別方法で実装

#### 4. **ProfileImageView.swift** (118行)
- **パス**: `/Users/nakanotakanori/Dev/GLOBE/GLOBE/Views/Components/ProfileImageView.swift`
- **定義型**: `ProfileImageView`
- **参照**: Preview内のみ
- **用途**: プロフィール画像表示UI
- **推奨**: 削除検討 - 別の実装で代替

#### 5. **LiquidGlassBackground.swift** (59行)
- **パス**: `/Users/nakanotakanori/Dev/GLOBE/GLOBE/Views/Components/LiquidGlassBackground.swift`
- **定義型**: `LiquidGlassBackground`
- **副型**: `FloatingGlassButtonStyle`, `LiquidGlassEffectModifier`
- **参照**: Preview内のみ
- **用途**: グラスモルフィズムデザイン背景（廃止？）
- **推奨**: 削除検討 - LiquidGlassBottomTabBar で別実装

#### 6. **HeaderView.swift** (71行)
- **パス**: `/Users/nakanotakanori/Dev/GLOBE/GLOBE/Views/Components/HeaderView.swift`
- **定義型**: `HeaderView`
- **参照**: Preview内のみ
- **用途**: ヘッダーUI（ScrollableHeader で代替）
- **推奨**: 削除検討 - ScrollableHeader が主に使用

#### 7. **LiquidGlassTabBar.swift** (117行)
- **パス**: `/Users/nakanotakanori/Dev/GLOBE/GLOBE/Views/Components/LiquidGlassTabBar.swift`
- **定義型**: `LiquidGlassTabBar`
- **副型**: `LiquidGlassButtonStyle`
- **参照**: Preview内のみ（4件の参照だが、すべてPreview関連）
- **用途**: グラスモルフィズムタブバー（廃止？）
- **推奨**: 削除検討 - LiquidGlassBottomTabBar で代替

---

## ✅ 確認済み - 実際に使用中のファイル（例示）

以下のファイルは、たとえ一見参照が少なく見えても、実際には重要な役割を果たしています：

### 安全に使用中
- `PostPin.swift` (773行) - PostCardBubbleShape を定義、PostPin.swift内で使用
- `CreatePostView.swift` (696行) - PostPrivacyType を定義、CreatePostView内で使用
- `SupabaseService.swift` (1010行) - PostManager, MapManager, MyPageViewModel から参照
- `MapManager.swift` (513行) - MainTabView から使用
- `PostManager.swift` - MapManager から参照
- `ProfileImageCacheManager.swift` - GlobeApp で使用
- `SecureLogger.swift`, `InputValidator.swift`, `DatabaseSecurity.swift` - セキュリティコア機能
- `MapContentView.swift` - MainTabView で使用

### 安全に使用中（ローカルに閉じた参照）
- `TabBarProfileView.swift` - MainTabView から直接使用
- `CreatePostView.swift` - MainTabView から直接使用
- `SearchPopupView.swift` - MainTabView から直接使用
- `EditProfileView.swift` - TabBarProfileView から使用
- `FollowListView.swift` - TabBarProfileView から使用
- すべての Auth ビュー (SignUpView, SignInView, DisplayNameStepView など)

---

## 💡 推奨アクション

### 優先度1: 削除推奨
1. **STILLEditProfileView.swift** - 空のファイル、即座に削除

### 優先度2: 削除検討（要確認後）
以下のファイルは、Preview以外で参照されていません。削除前に確認してください：

| ファイル名 | 行数 | 理由 |
|-----------|------|------|
| AuthenticationView.swift | 237 | SignUpFlow/SignInView で代替実装 |
| PostTypeSelector.swift | 160 | 投稿タイプ選択が別実装 |
| CommentsSheet.swift | 243 | コメント機能が別実装 |
| ProfileImageView.swift | 118 | プロフィール画像表示が別実装 |
| LiquidGlassBackground.swift | 59 | グラスUI廃止予定？ |
| HeaderView.swift | 71 | ScrollableHeader で代替 |
| LiquidGlassTabBar.swift | 117 | LiquidGlassBottomTabBar で代替 |

**合計削除可能行数**: ~1,004行

---

## 🔍 デザインシステムとユーティリティ（安全）

以下のファイルは型定義がローカルスコープ内で完全に使用されており、削除すべきではありません：

### セキュリティ・検証関連（重要）
- `InputValidator.swift` - ValidationResult, ValidationError 等を定義
- `SecureLogger.swift` - ログシステムの核
- `DatabaseSecurity.swift` - QueryValidationResult, DatabaseSecurityError を定義
- `SecureKeychain.swift` - KeychainError, AccessControl を定義
- `APIResponseValidator.swift` - ValidationError を定義
- `RLSVerification.swift` - RLS検証ロジック

### モデル関連（必須）
- `Post.swift` - Post 型定義
- `Comment.swift` - Comment 型定義
- `DatabaseModels.swift` - PostDB, ProfileDB, PostInsert 等（内部使用）
- `SharedModels.swift` - AppUser, UserProfile, AuthError（複数箇所で使用）

### ViewModels（必須）
- `MyPageViewModel.swift` - ProfileView/TabBarProfileView で使用
- `SearchViewModel.swift` - SearchPopupView で使用
- `MapLocationService.swift` - MainTabView で使用

---

## 📋 チェックリスト

削除前に以下を確認してください：

- [ ] STILLEditProfileView.swift は確実に削除可能（完全に空）
- [ ] AuthenticationView は本当に SignInView/SignUpView で代替されているか確認
- [ ] PostTypeSelector が使われていないことを確認
- [ ] CommentsSheet の機能が別処理で実装されているか確認
- [ ] 削除前に git で変更を記録
- [ ] 各ファイル削除後、プロジェクトをビルドして動作確認

---

## 🎯 総括

**削除推奨ファイル**: 1個（STILLEditProfileView.swift）
**削除検討ファイル**: 7個（合計 ~1,004行）
**総削除候補行数**: ~1,004行（プロジェクト全体 ~18,488行の約5.4%）

**実装時の留意点**:
- Preview-only コンポーネントは UI 開発時の試験的実装の可能性あり
- 削除前に必ずプロジェクトをビルド・テストしてください
- git diff で変更内容を確認してから commit してください

