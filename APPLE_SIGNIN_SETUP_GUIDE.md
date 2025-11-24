# Apple Sign In セットアップガイド（Xcode 15/16対応）

## ✅ 実装状況確認

以下のコードは**既に実装済み**です：
- ✅ `AuthManager.swift` - Apple Sign Inロジック
- ✅ `AppleSignInCoordinator.swift` - 認証フロー管理
- ✅ `SignInView.swift` - Apple Sign Inボタン
- ✅ `AppleSignUpProfileSetupView.swift` - 初回サインイン時のプロフィール設定

**Bundle ID**: `com.takanorinakano.GLOBE`

---

## 📋 セットアップ手順（3つのステップ）

### ステップ1️⃣: Xcodeでの設定

#### 1-1. Signing & Capabilitiesの設定

1. **Xcodeでプロジェクトを開く**
   ```bash
   cd /Users/nakanotakanori/Dev/GLOBE
   open GLOBE.xcodeproj
   ```

2. **プロジェクトナビゲーターでGLOBEターゲットを選択**
   - 左側のプロジェクトナビゲーターで`GLOBE.xcodeproj`をクリック
   - 中央のターゲットリストで`GLOBE`を選択

3. **Signing & Capabilitiesタブを開く**
   - 上部のタブから`Signing & Capabilities`をクリック

4. **Sign in with Apple Capabilityを追加**
   - `+ Capability`ボタン（左上）をクリック
   - 検索ボックスに「Sign in with Apple」と入力
   - 表示された`Sign in with Apple`をダブルクリック

5. **確認**
   - Capabilitiesリストに以下が表示されることを確認：
     ```
     ☑ Sign in with Apple
     ```

#### 1-2. Entitlementsファイルの確認

Capabilityを追加すると、Xcodeが自動的に`GLOBE.entitlements`ファイルを作成します。

**確認方法：**
```bash
# プロジェクト内でentitlementsファイルを探す
find /Users/nakanotakanori/Dev/GLOBE -name "*.entitlements"
```

**ファイル内容例：**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
</dict>
</plist>
```

---

### ステップ2️⃣: Apple Developer Consoleでの設定

#### 2-1. App IDの設定

1. **Apple Developer Consoleにアクセス**
   - https://developer.apple.com/account にログイン
   - `Certificates, Identifiers & Profiles`をクリック

2. **Identifiersページへ移動**
   - 左サイドバーから`Identifiers`を選択

3. **既存のApp IDを編集**
   - リストから`com.takanorinakano.GLOBE`を探してクリック
   - （新規作成の場合は`+`ボタンをクリックして作成）

4. **Sign In with Apple Capabilityを有効化**
   - Capabilitiesリストをスクロール
   - ☑️ `Sign In with Apple`にチェックを入れる
   - `Edit`ボタンをクリック（オプション設定）
     - `Enable as a primary App ID`を選択（推奨）
   - `Save`→`Continue`→`Register`をクリック

#### 2-2. Services IDの作成（重要！）

**これがSupabaseで必要な`Client ID`になります**

1. **新しいIdentifierを作成**
   - `Identifiers`ページで`+`ボタンをクリック

2. **Services IDsを選択**
   ```
   □ App IDs
   ☑️ Services IDs  ← これを選択
   □ Pass Type IDs
   ```
   - `Continue`をクリック

3. **Services IDの詳細を入力**
   ```
   Description: GLOBE Web Auth
   Identifier: com.takanorinakano.GLOBE.web
   ```
   ⚠️ **重要**: IdentifierにはBundle IDとは異なる値を使用してください

   - `Continue`→`Register`をクリック

4. **Sign In with Appleを設定**
   - 作成した`com.takanorinakano.GLOBE.web`をクリック
   - ☑️ `Sign In with Apple`にチェック
   - `Configure`ボタンをクリック

5. **Web Authenticationの設定**
   ```
   Primary App ID: com.takanorinakano.GLOBE

   Website URLs:
     Domains and Subdomains: kkznkqshpdzlhtuawasm.supabase.co
     Return URLs: https://kkznkqshpdzlhtuawasm.supabase.co/auth/v1/callback
   ```
   - `Next`→`Done`→`Continue`→`Save`をクリック

#### 2-3. Keyの作成

1. **Keysページへ移動**
   - 左サイドバーから`Keys`を選択
   - `+`ボタンをクリック

2. **Keyの情報を入力**
   ```
   Key Name: GLOBE Sign in with Apple Key
   ```
   - ☑️ `Sign In with Apple`にチェック
   - `Configure`ボタンをクリック

3. **Primary App IDを選択**
   ```
   Primary App ID: com.takanorinakano.GLOBE
   ```
   - `Save`をクリック

4. **Keyを登録してダウンロード**
   - `Continue`→`Register`をクリック
   - ⚠️ **重要**: 表示される以下の情報を**必ずメモ**してください：
     - `Key ID`: 例）`ABCD123456`（10文字の英数字）
     - ダウンロードボタンをクリックして`AuthKey_XXXXXXXXXX.p8`ファイルを保存

   ⚠️ **警告**: このKeyは一度しかダウンロードできません！

5. **Team IDを取得**
   - Apple Developer Console右上のアカウント名をクリック
   - `Membership`を選択
   - `Team ID`をメモ（例：`ABC1234567`）

---

### ステップ3️⃣: Supabase Dashboardでの設定

#### 3-1. Apple Providerを有効化

1. **Supabase Dashboardにアクセス**
   - https://supabase.com/dashboard/project/kkznkqshpdzlhtuawasm
   - `Authentication`→`Providers`をクリック

2. **Appleプロバイダーを探す**
   - プロバイダーリストから`Apple`を見つけてクリック

3. **設定を入力**

   **Enable Sign in with Apple**: ☑️ ON

   **Client IDs**:
   ```
   com.takanorinakano.GLOBE.web
   ```
   ⚠️ これは**Services ID**です（App IDではありません！）

   **Secret Key (for OAuth)**:
   ```
   -----BEGIN PRIVATE KEY-----
   [ここにAuthKey_XXXXXXXXXX.p8ファイルの中身を全て貼り付け]
   -----END PRIVATE KEY-----
   ```

   **手順:**
   - ダウンロードした`AuthKey_XXXXXXXXXX.p8`をテキストエディタで開く
   - ファイル全体をコピー（`-----BEGIN PRIVATE KEY-----`から`-----END PRIVATE KEY-----`まで）
   - Supabaseの`Secret Key`欄に貼り付け

   **Allow users without an email**: ☐ OFF
   （メールなしのユーザーを許可しない - 推奨）

   **Callback URL (for OAuth)**:
   ```
   https://kkznkqshpdzlhtuawasm.supabase.co/auth/v1/callback
   ```
   （自動入力済み、変更不要）

4. **保存**
   - `Save`ボタンをクリック

---

## 🧪 テスト手順

### Xcodeでビルド・実行

```bash
# プロジェクトディレクトリへ移動
cd /Users/nakanotakanori/Dev/GLOBE

# シミュレーターでビルド（Xcode 15/16）
xcodebuild -project GLOBE.xcodeproj -scheme GLOBE -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# または、Xcodeから直接実行
# Cmd + R でビルド＆実行
```

### Apple Sign Inのテスト

1. **アプリを起動**
   - Sign Inページへ移動

2. **「Sign in with Apple」ボタンをタップ**
   - 白いAppleロゴのボタンが表示されているはず

3. **Apple IDで認証**
   - Face ID / Touch ID / パスワードで認証
   - 初回サインイン時は名前・メールの共有許可を求められます

4. **プロフィール設定画面**
   - 新規ユーザーの場合、`AppleSignUpProfileSetupView`が表示されます
   - User IDとDisplay Nameを入力
   - `Complete`ボタンをタップ

5. **確認**
   - メイン画面へ遷移すれば成功！

---

## ❌ トラブルシューティング

### エラー: "Invalid client"

**原因**: Services IDの設定が正しくない

**解決策**:
1. Apple Developer Consoleで`com.takanorinakano.GLOBE.web`を確認
2. Return URLsに`https://kkznkqshpdzlhtuawasm.supabase.co/auth/v1/callback`が正しく設定されているか確認
3. Primary App IDが`com.takanorinakano.GLOBE`になっているか確認

### エラー: "Invalid grant"

**原因**: Secret Keyが正しくない、またはKey IDが間違っている

**解決策**:
1. `.p8`ファイルの内容を再度コピー＆ペースト
2. `-----BEGIN PRIVATE KEY-----`と`-----END PRIVATE KEY-----`が含まれているか確認
3. 余分な空白や改行が入っていないか確認

### ビルドエラー: "Code signing error"

**原因**: Signing設定が正しくない

**解決策**:
1. Xcode → `Signing & Capabilities`タブ
2. `Automatically manage signing`にチェック
3. Teamが選択されているか確認
4. Provisioning ProfileをRefresh

### Apple Sign Inボタンが表示されない

**原因**: Capabilityが追加されていない、またはentitlementsが正しくない

**解決策**:
1. `Signing & Capabilities`で`Sign in with Apple`が追加されているか確認
2. `.entitlements`ファイルが存在するか確認
3. Clean Build Folder（Cmd + Shift + K）して再ビルド

---

## 📝 チェックリスト

### Xcode設定
- [ ] `Sign in with Apple` Capabilityを追加
- [ ] `.entitlements`ファイルが自動生成されている
- [ ] Bundle IDが`com.takanorinakano.GLOBE`

### Apple Developer Console
- [ ] App ID（`com.takanorinakano.GLOBE`）に`Sign In with Apple`を有効化
- [ ] Services ID（`com.takanorinakano.GLOBE.web`）を作成
- [ ] Services IDのSign In with Appleを設定（Return URLs含む）
- [ ] Keyを作成してダウンロード（`.p8`ファイル）
- [ ] Key IDとTeam IDをメモ

### Supabase Dashboard
- [ ] `Enable Sign in with Apple`をON
- [ ] Client IDsに`com.takanorinakano.GLOBE.web`を入力
- [ ] Secret Keyに`.p8`ファイルの内容を貼り付け
- [ ] 設定を保存

---

## 🎯 まとめ

必要な値の整理：

| 項目 | 値 |
|------|-----|
| **Bundle ID** | `com.takanorinakano.GLOBE` |
| **Services ID** | `com.takanorinakano.GLOBE.web` |
| **Supabase Client ID** | `com.takanorinakano.GLOBE.web`（Services IDと同じ） |
| **Supabase Secret Key** | `.p8`ファイルの内容全体 |
| **Return URL** | `https://kkznkqshpdzlhtuawasm.supabase.co/auth/v1/callback` |

この手順に従えば、Apple Sign Inが正常に動作します！🎉
