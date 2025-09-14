# 🛠️ Xcode Setup Guide for GLOBE Test Execution

## 現在の状況
Command Line Toolsのみがインストールされており、Xcodeが必要です。

## セットアップ手順

### 1. Xcodeのインストール
```bash
# Mac App Store から Xcode をインストール
open -a "App Store"
# または直接リンク
open "macappstores://apps.apple.com/app/xcode/id497799835"
```

### 2. Developer Directory の設定
```bash
# 現在の設定を確認
xcode-select --print-path
# 出力: /Library/Developer/CommandLineTools (現在)

# Xcodeに変更
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# 設定確認
xcode-select --print-path
# 出力: /Applications/Xcode.app/Contents/Developer (変更後)
```

### 3. Xcodeライセンスの同意
```bash
sudo xcodebuild -license accept
```

### 4. シミュレーターの準備
```bash
# 利用可能なシミュレーターを確認
xcrun simctl list devices

# iPhone 16 Pro シミュレーターを起動
xcrun simctl boot "iPhone 16 Pro"
```

## テスト実行コマンド

### 全テスト実行
```bash
cd /Users/nakanotakanori/Dev/GLOBE
xcodebuild test -scheme GLOBE -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### 特定のテストスイート実行
```bash
# Unit + Integration Tests のみ
xcodebuild test -scheme GLOBE -only-testing:GLOBETests

# UI Tests のみ
xcodebuild test -scheme GLOBE -only-testing:GLOBEUITests

# 特定のテストクラス
xcodebuild test -scheme GLOBE -only-testing:GLOBETests/InputValidatorTests

# 特定のテストメソッド
xcodebuild test -scheme GLOBE -only-testing:GLOBETests/InputValidatorTests/testValidateEmail_validAndInvalid
```

### テスト結果の出力設定
```bash
# 詳細な出力
xcodebuild test -scheme GLOBE -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -verbose

# JSON形式での結果出力
xcodebuild test -scheme GLOBE -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -resultBundlePath TestResults.xcresult
```

## Xcode IDE での実行

### 1. プロジェクトを開く
```bash
open GLOBE.xcodeproj
```

### 2. テスト実行方法
- **全テスト実行**: `Cmd + U`
- **特定テスト実行**: テストナビゲーターで個別選択して実行
- **テストデバッグ**: テストメソッドの横の▷ボタンをクリック

### 3. テスト結果の確認
- Test Navigator (Cmd + 6) でテスト結果確認
- Issue Navigator (Cmd + 7) で失敗したテストの詳細確認
- Report Navigator (Cmd + 9) で詳細レポート確認

## 想定されるテスト結果

### ✅ 成功が期待されるテスト
- **InputValidatorTests**: 全8メソッド PASS
- **DatabaseSecurityTests**: 全4メソッド PASS
- **TestHelpers**: 基本機能 PASS

### 🟡 部分的成功が期待されるテスト
- **AuthManagerLightTests**: 一部ネットワーク依存でSKIP可能
- **MyPageViewModelTests**: モック不足で一部FAIL可能
- **PostManagerTests**: Supabase接続で一部FAIL可能

### 📱 環境依存テスト
- **GLOBEUITests**: シミュレーター環境に依存
- **IntegrationTests**: 実際のネットワーク接続が必要

## トラブルシューティング

### シミュレーターエラー
```bash
# シミュレーターをリセット
xcrun simctl shutdown all
xcrun simctl erase all
xcrun simctl boot "iPhone 16 Pro"
```

### ビルドエラー
```bash
# プロジェクトクリーン
xcodebuild clean -scheme GLOBE

# Derived Data削除
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### 依存関係エラー
```bash
# Package依存関係の更新
xcodebuild -resolvePackageDependencies
```

## 継続的インテグレーション

### GitHub Actions 設定例
```yaml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    - name: Run Tests
      run: |
        xcodebuild test \
          -scheme GLOBE \
          -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
          -resultBundlePath TestResults.xcresult
```

## 完了後の確認項目

- [ ] Xcodeが正常にインストールされている
- [ ] `xcode-select --print-path` が正しいパスを返す
- [ ] `xcodebuild -version` でバージョン情報が表示される
- [ ] シミュレーターが起動できる
- [ ] テストが実行できる（一部失敗は許容）
- [ ] テスト結果がレポートされる

## 期待される成功率

- **Unit Tests**: 90-100% 成功
- **Integration Tests**: 70-90% 成功（ネットワーク依存）
- **UI Tests**: 80-95% 成功（環境依存）
- **Overall**: 80%+ の成功率でテスト戦略の有効性を確認

---

**📝 メモ**: Command Line Toolsのみでは iOS アプリのテストは実行できません。Xcodeのフルインストールが必要です。