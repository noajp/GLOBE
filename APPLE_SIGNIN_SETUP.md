# Apple Sign In 設定ガイド

## Supabaseで必要な情報

Supabase Dashboard → Authentication → Providers → Apple で以下を入力：

```
Client IDs: com.takanorinakano.GLOBE
Secret Key (for OAuth): [Apple Developer Consoleで生成]
Callback URL: https://kkznkqshpdzlhtuawasm.supabase.co/auth/v1/callback
```

## Apple Developer Consoleでの設定手順

### 前提条件
- Apple Developer Programに登録済み ($99/年)
- https://developer.apple.com にログイン

---

## ステップ1: App IDの確認

1. https://developer.apple.com にログイン
2. **Certificates, Identifiers & Profiles** をクリック
3. 左メニュー → **Identifiers**
4. `com.takanorinakano.GLOBE` を探す

**もし見つからない場合:**
- 「+」ボタンをクリック
- **App IDs** を選択 → Continue
- **App** を選択 → Continue
- Description: `GLOBE`
- Bundle ID: `com.takanorinakano.GLOBE` (Explicit)
- Capabilities: **Sign In with Apple** にチェック
- Continue → Register

**既に存在する場合:**
- `com.takanorinakano.GLOBE` をクリック
- **Sign In with Apple** がチェックされているか確認
- チェックされていなければチェックを入れて Save

---

## ステップ2: Services IDの作成（重要）

これがSupabaseの「Client IDs」に入力する値です。

1. 左メニュー → **Identifiers**
2. 右上の「+」ボタンをクリック
3. **Services IDs** を選択 → Continue
4. 以下を入力:
   ```
   Description: GLOBE Web Auth
   Identifier: com.takanorinakano.GLOBE.web
   ```
5. Continue → Register
6. 作成した `com.takanorinakano.GLOBE.web` をクリック
7. **Sign In with Apple** にチェックを入れる
8. **Configure** ボタンをクリック

**Sign In with Apple: Web Authentication Configurationで:**
```
Primary App ID: com.takanorinakano.GLOBE

Website URLs:
  Domains and Subdomains: kkznkqshpdzlhtuawasm.supabase.co
  Return URLs: https://kkznkqshpdzlhtuawasm.supabase.co/auth/v1/callback
```

9. Next → Done → Continue → Save

**重要:** Services IDの `com.takanorinakano.GLOBE.web` がSupabaseの「Client IDs」に入力する値です。

---

## ステップ3: Keyの作成（Secret Key用）

1. 左メニュー → **Keys**
2. 右上の「+」ボタンをクリック
3. Key Name: `GLOBE Sign in with Apple Key`
4. **Sign In with Apple** にチェック
5. **Configure** ボタンをクリック
6. Primary App ID: `com.takanorinakano.GLOBE` を選択
7. Save → Continue → Register
8. **Download Your Key** 画面が表示される
   - **Download** ボタンをクリック
   - `AuthKey_XXXXXXXXXX.p8` ファイルがダウンロードされる
   - **Key ID** をメモ（例: ABCD123456）
   - ⚠️ この画面は二度と表示されないので、必ずダウンロードすること

9. Team IDをメモ:
   - 右上のアカウント名をクリック
   - **Membership** タブ
   - **Team ID** をメモ（例: ABC1234567）

---

## ステップ4: Secret Keyの生成

Appleの.p8ファイルからSupabaseが必要とするSecret Keyを生成します。

### 方法1: オンラインツールを使用（簡単）

1. https://jwt.io にアクセス
2. 左側の **Decoded** セクションに以下を入力:

**HEADER:**
```json
{
  "alg": "ES256",
  "kid": "ABCD123456"
}
```
※ `kid` は Step 3 でメモした Key ID

**PAYLOAD:**
```json
{
  "iss": "ABC1234567",
  "iat": 1234567890,
  "exp": 1234567890,
  "aud": "https://appleid.apple.com",
  "sub": "com.takanorinakano.GLOBE.web"
}
```
※ `iss` は Team ID
※ `sub` は Services ID
※ `iat` と `exp` は適当な Unix timestamp

**VERIFY SIGNATURE:**
```
ECDSASHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  [ダウンロードした.p8ファイルの中身をコピペ]
)
```

3. 左下の **Encoded** に表示された長い文字列をコピー
   → これが Secret Key

### 方法2: Supabaseの推奨方法（推奨）

実は、Supabaseは **.p8ファイルの中身をそのまま** Secret Keyとして受け付けます。

1. ダウンロードした `AuthKey_XXXXXXXXXX.p8` をテキストエディタで開く
2. 全文をコピー（以下のような形式）:
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
（複数行続く）
...==
-----END PRIVATE KEY-----
```
3. これをそのままSupabaseの Secret Key に貼り付け

---

## ステップ5: Supabaseに設定

Supabase Dashboard → Authentication → Providers → Apple

```
✅ Enable Sign in with Apple: ON

Client IDs:
com.takanorinakano.GLOBE.web
(Services IDを入力)

Secret Key (for OAuth):
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
-----END PRIVATE KEY-----
(.p8ファイルの内容全体を貼り付け)

☐ Allow users without an email: OFF
(メールアドレスなしのユーザーを許可しない)

Callback URL (for OAuth):
https://kkznkqshpdzlhtuawasm.supabase.co/auth/v1/callback
(自動入力済み、変更不要)
```

**Save** をクリック

---

## ステップ6: Info.plistの設定（Xcodeで）

iOSアプリでApple Sign Inを使うには、URL Schemeの設定が必要です。

### Xcodeで設定:

1. Xcodeで `GLOBE.xcodeproj` を開く
2. プロジェクトナビゲータで **GLOBE** プロジェクトを選択
3. **TARGETS** → **GLOBE** を選択
4. **Signing & Capabilities** タブ
5. 「+ Capability」をクリック
6. **Sign in with Apple** を追加

これでiOS側の設定も完了です。

---

## 動作確認

### テスト手順:

1. Xcodeでアプリをビルド（実機推奨）
2. SignIn画面を開く
3. **Sign up with Apple** ボタンをタップ
4. Face ID / Touch ID で認証
5. 初回サインアップの場合:
   - AppleSignUpProfileSetupView が表示される
   - User ID と Display Name を入力
   - Complete をタップ
6. ログイン成功 → MainTabView に遷移

### トラブルシューティング:

**エラー: "Invalid client"**
- Services ID (`com.takanorinakano.GLOBE.web`) が正しいか確認
- Apple Developer Consoleで Services ID を有効化したか確認

**エラー: "Invalid redirect URI"**
- Return URLs に `https://kkznkqshpdzlhtuawasm.supabase.co/auth/v1/callback` が登録されているか確認

**エラー: "Invalid client secret"**
- Secret Key (.p8ファイルの内容) が正しくコピーされているか確認
- Key ID と Team ID が正しいか確認

**シミュレータでApple Sign Inが動作しない**
- シミュレータでは制限がある場合があります
- 実機でテストしてください

---

## まとめ

### Supabaseに入力する値:

```
Client IDs: com.takanorinakano.GLOBE.web
Secret Key: -----BEGIN PRIVATE KEY-----
            [.p8ファイルの全内容]
            -----END PRIVATE KEY-----
```

### Apple Developer Consoleで作成したもの:

1. ✅ App ID: `com.takanorinakano.GLOBE`
2. ✅ Services ID: `com.takanorinakano.GLOBE.web`
3. ✅ Key: `AuthKey_XXXXXXXXXX.p8`

### Xcodeで設定したもの:

1. ✅ Sign in with Apple Capability

これで完了です！
