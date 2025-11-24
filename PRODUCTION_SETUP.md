# GLOBE Production Setup Guide

本番環境への移行に向けた設定ガイド

## 1. Supabase Authentication Settings

Supabase Dashboard → Authentication → Providersで以下を設定:

### Email Provider
```
✅ Enable Email provider: ON
✅ Confirm email: ON
✅ Secure email change: ON
✅ Secure password change: ON
✅ Prevent use of leaked passwords: ON
```

### 設定の説明

#### Enable Email provider
メールアドレスとパスワードでのサインアップ・ログインを有効化

#### Confirm email
- サインアップ時にメール認証を必須にする
- ユーザーは登録したメールアドレスに送られる確認リンクをクリックする必要がある
- これにより、無効なメールアドレスでの登録を防止

#### Secure email change
- メールアドレス変更時に新旧両方のメールで確認を要求
- セキュリティを強化し、不正なメール変更を防止
- 無効化すると新しいメールアドレスのみで確認

#### Secure password change
- パスワード変更時に最近のログインを要求（24時間以内）
- セッションハイジャック攻撃からの保護
- 無効化すると、いつでもパスワード変更可能（非推奨）

#### Prevent use of leaked passwords
- HaveIBeenPwned.org APIを使用して、漏洩したパスワードをチェック
- 既知の脆弱なパスワードの使用を防止
- セキュリティを大幅に向上

## 2. Email Settings

### 送信者名の変更
Supabase Dashboard → Project Settings → Auth → SMTP Settings

デフォルトでは "Supabase Auth" から送信されますが、カスタマイズ可能:

**方法1: カスタムSMTP設定（推奨）**
```
Enable Custom SMTP: ON
Sender email: noreply@yourdomain.com
Sender name: GLOBE
Host: smtp.sendgrid.net (SendGridの例)
Port: 587
Username: apikey
Password: [Your SendGrid API Key]
```

**方法2: Supabaseのデフォルト設定**
- 無料プランの場合、送信者名は変更できません
- Pro プラン以上でカスタムSMTPが利用可能

### Email Templates

Supabase Dashboard → Authentication → Email Templatesで以下をカスタマイズ:

### Confirm signup
サインアップ時の確認メール
```html
<h2>Welcome to GLOBE!</h2>
<p>Click the link below to verify your email address:</p>
<p><a href="{{ .ConfirmationURL }}">Verify Email</a></p>
```

### Magic Link
マジックリンクログイン用（必要に応じて）
```html
<h2>GLOBE Login</h2>
<p>Click the link below to sign in:</p>
<p><a href="{{ .ConfirmationURL }}">Sign In</a></p>
```

### Change Email Address
メールアドレス変更時の確認メール
```html
<h2>Confirm Email Change</h2>
<p>Click the link below to confirm your new email address:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm Change</a></p>
```

### Reset Password
パスワードリセット用メール
```html
<h2>Reset Your Password</h2>
<p>Click the link below to reset your password:</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
```

## 3. App Configuration

### 開発環境と本番環境の違い

#### 開発環境（DEBUG）
```swift
#if DEBUG
// メール認証をスキップ
currentUser = AppUser(...)
isAuthenticated = true
#endif
```

#### 本番環境（RELEASE）
```swift
#else
// メール認証が必要
currentUser = nil
isAuthenticated = false
// ユーザーはメールを確認してログインする必要がある
#endif
```

## 4. Build Configuration

### Debug Build (開発)
```bash
# Xcodeで開発中のビルド
# メール認証スキップ、各種デバッグ機能有効
```

### Release Build (本番)
```bash
# App Store配布用ビルド
# メール認証必須、セキュリティ強化
```

Product → Scheme → Edit Scheme → Run → Build Configuration
- Debug: 開発用
- Release: 本番用

## 5. Supabase URL Configuration

本番環境用のURL設定:

### Redirect URLs
Supabase Dashboard → Authentication → URL Configuration

```
Site URL: https://yourdomain.com (本番環境のURL、開発中は仮のURLでOK)

Redirect URLs:
  - https://yourdomain.com/**
  - globe://auth/callback
  - globe://email-confirmation
  - globe://**
```

### Deep Link設定（重要）
メールのリンクをアプリで開くために必要:

#### 1. Info.plistにURL Typesを追加
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>globe</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.globe</string>
    </dict>
</array>
```

#### 2. Supabaseのメールテンプレートを確認
- Dashboard → Authentication → Email Templates
- Confirm signup のテンプレートを確認
- `{{ .ConfirmationURL }}` が正しく設定されているか確認

#### 3. アプリでDeep Linkを処理
GLOBEApp.swiftに以下を追加:

```swift
.onOpenURL { url in
    print("Received URL: \(url.absoluteString)")
    Task {
        do {
            try await supabase.auth.session(from: url)
            print("Successfully handled auth URL")
        } catch {
            print("Failed to handle auth URL: \(error)")
        }
    }
}
```

## 6. Testing Checklist

本番環境移行前のチェックリスト:

### Email認証フロー
- [ ] サインアップ時にメールが送信される
- [ ] メール内のリンクをクリックすると認証される
- [ ] 認証前はログインできない
- [ ] 認証後はログインできる

### Email変更フロー
- [ ] 旧メールアドレスに確認メールが送信される
- [ ] 新メールアドレスに確認メールが送信される
- [ ] 両方確認するとメールが変更される

### パスワード変更フロー
- [ ] 最近ログインしていない場合は再認証が必要
- [ ] 漏洩したパスワードは使用できない
- [ ] 強力なパスワードが必要

### User ID変更フロー
- [ ] データベースで重複チェック
- [ ] 一意性が保証される
- [ ] 変更が即座に反映される

## 7. Security Best Practices

### パスワードポリシー
- 最小8文字
- 英字と数字を含む
- 漏洩したパスワードは使用不可

### メールセキュリティ
- メール認証必須
- メール変更時は新旧両方で確認
- SMTP設定の確認

### User IDポリシー
- 3-30文字
- 小文字英数字とアンダースコアのみ
- 世界で一意

## 8. Migration Steps

開発環境から本番環境への移行手順:

1. **Supabase設定を有効化**
   - Email provider設定をすべてONに
   - Email templatesをカスタマイズ

2. **アプリのビルド設定を確認**
   - Release buildでテスト
   - メール認証フローを確認

3. **テストユーザーで検証**
   - 新規サインアップ
   - メール認証
   - ログイン
   - Email変更
   - User ID変更

4. **本番デプロイ**
   - App Store Review
   - 本番環境でモニタリング

## 9. Monitoring

### ログ確認項目
- サインアップ成功/失敗
- メール送信成功/失敗
- 認証成功/失敗
- Email変更成功/失敗
- User ID変更成功/失敗

### Supabase Dashboard
- Authentication → Users: ユーザー一覧
- Authentication → Logs: 認証ログ
- Database → Table Editor → profiles: プロフィールデータ

## 10. Troubleshooting

### メールが届かない
- SMTP設定を確認
- スパムフォルダを確認
- Supabase logsでエラー確認

### 認証リンクが動作しない
- Redirect URLsを確認
- URL schemeの設定を確認
- Deeplink handlerの実装を確認

### User IDが重複する
- データベースのunique制約を確認
- バリデーションロジックを確認
- 同時書き込みの制御を確認
