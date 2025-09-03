# GLOBE App リファクタリング TODO リスト

## 📝 概要
GLOBEアプリのコードベース改善のためのリファクタリングタスク一覧

---

## 🔴 優先度: 高 (機能実装・バグ修正)

### データベース連携
- [ ] **SupabaseService.fetchUserPosts** メソッドの実装
  - ファイル: `GLOBE/Services/SupabaseService.swift:44`
  - 内容: ユーザーの投稿を取得する実際のSupabase SDKの実装

- [ ] **CommentService** のデータベース連携
  - ファイル: `GLOBE/Services/CommentService.swift:36`
  - 内容: コメントのロード・保存をSupabaseと連携

- [ ] **LikeService** のデータベース連携
  - ファイル: `GLOBE/Services/LikeService.swift:47`
  - 内容: いいね機能の実際のデータベース実装

- [ ] **Follow機能** の実装
  - ファイル: `GLOBE/Models/Follow.swift:68,77,83,89`
  - 内容: フォロー/アンフォロー機能のSupabase連携

### UI機能実装
- [ ] **プロフィール画像変更機能**
  - ファイル: `GLOBE/Views/ProfileView.swift:99`
  - 内容: プロフィール画像のアップロード・変更機能

- [ ] **投稿削除機能**
  - ファイル: `GLOBE/Views/PostDetailView.swift:197`
  - 内容: Supabaseから投稿を削除する機能

- [ ] **ユーザー検索機能**
  - ファイル: `GLOBE/Views/UserSearchView.swift:196`
  - 内容: 実際のSupabase検索の実装（モックデータの置き換え）

---

## 🟡 優先度: 中 (コード品質・保守性)

### コード重複の解消
- [ ] **PostPin/ScalablePostPin** の共通化
  - ファイル: `GLOBE/Views/Components/PostPin.swift`
  - 内容: 共通ロジックを基底クラスまたはプロトコルに抽出
  - 重複コード: プロフィールアイコン、いいねボタン、コメントボタン

### 定数管理
- [ ] **ハードコーディングされた値の設定ファイル化**
  - 対象:
    - フォントサイズ: 6, 7, 8, 9, 10
    - カードサイズ: 96, 72, 40, 28
    - 色の透明度: 0.3, 0.6, 0.8, 0.9
  - 移動先: `MinimalDesignSystem.swift`

### 非同期処理の統一
- [ ] **@MainActor と DispatchQueue.main の統一**
  - 対象ファイル: 
    - `SupabaseService.swift`
    - `PostManager.swift`
    - `PostPopupView.swift`
  - 方針: @MainActorに統一

### エラーハンドリング
- [ ] **共通エラーハンドリング機構の実装**
  - 新規作成: `GLOBE/Core/Services/ErrorHandler.swift`
  - 内容: 統一されたエラー処理とユーザーフィードバック

---

## 🟢 優先度: 低 (最適化・改善)

### デバッグとログ
- [ ] **print文のSecureLogger移行**
  - 対象: 全ファイル内のprint文
  - 方法: 
    ```swift
    // Before
    print("🔧 SupabaseService - Using URL: \(urlString)")
    
    // After
    secureLogger.debug("Using URL", metadata: ["url": urlString])
    ```

- [ ] **ログレベルの設定**
  - Debug環境: `.debug`
  - Release環境: `.warning`

### パフォーマンス最適化
- [ ] **文字数計算ロジックの改善**
  - ファイル: `PostPin.swift:estimatedTextLines`
  - 内容: TextKitを使用した正確な行数計算

- [ ] **画像キャッシュ戦略**
  - 新規実装: ImageCacheManager
  - 内容: メモリとディスクキャッシュの実装

### コード構造改善
- [ ] **PostPopupViewの分割**
  - 現状: 535行
  - 目標: 
    - PostCreationView.swift (150行)
    - PrivacySelectionView.swift (100行)
    - LocationPickerView.swift (80行)
    - PhotoPreviewView.swift (70行)

- [ ] **型安全性の向上**
  - AnyJSONの使用箇所を具体的な型に変更
  - ファイル: `SupabaseService.swift:144-153`

### UI/UX改善
- [ ] **アクセシビリティ対応**
  - VoiceOverサポート
  - Dynamic Type対応
  - アクセシビリティラベルの追加

- [ ] **ローカライゼーション準備**
  - ハードコーディングされた日本語文字列の外部化
  - Localizable.stringsファイルの作成

---

## 📊 進捗管理

### 完了基準
- [ ] 全てのTODOコメントが解決
- [ ] ユニットテストのカバレッジ80%以上
- [ ] SwiftLintの警告0件
- [ ] メモリリークなし（Instrumentsで確認）

### 推定工数
- 優先度高: 40時間
- 優先度中: 24時間
- 優先度低: 16時間
- **合計: 80時間**

---

## 🔍 技術的負債の削減効果
- コード重複率: 30% → 10%
- 平均ファイルサイズ: 300行 → 150行
- ビルド時間: 20% 短縮見込み
- バグ発生率: 50% 削減見込み

---

## 📌 注意事項
1. リファクタリング時は必ず既存の機能テストを実施
2. 大きな変更は段階的にリリース
3. パフォーマンス計測を実施して改善効果を確認
4. チーム内でコードレビューを実施