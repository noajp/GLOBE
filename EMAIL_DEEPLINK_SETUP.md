# メールリンクが開かない問題の解決方法

## 問題
サインアップ時にSupabaseからメールは届くが、メール内の「ログイン」リンクをクリックしてもアプリが開かない。

## 原因
1. アプリにURL Scheme（Deep Link）が設定されていない
2. Supabase DashboardでRedirect URLsが正しく設定されていない
3. アプリ側でDeep Linkを処理するコードがない

## 解決手順

### 1. Xcode でURL Schemeを設定

1. Xcodeで `GLOBE.xcodeproj` を開く
2. プロジェクトナビゲータで `GLOBE` プロジェクトを選択
3. `TARGETS` → `GLOBE` を選択
4. `Info` タブを選択
5. `URL Types` セクションを展開（なければ `+` で追加）
6. 以下の設定を追加:
   ```
   Identifier: com.globe.app.auth
   URL Schemes: globe
   Role: Editor
   ```

**設定イメージ:**
```
URL Types
  Item 0
    ├─ Identifier: com.globe.app.auth
    ├─ URL Schemes: globe
    └─ Role: Editor
```

### 2. Supabase Dashboard で Redirect URLs を設定

1. Supabase Dashboard にログイン
2. プロジェクト `GROBE` を選択
3. `Authentication` → `URL Configuration` に移動
4. 以下のURLを追加:

```
Site URL:
  https://yourdomain.com (本番環境のURL、開発中は仮でOK)

Redirect URLs:
  globe://**
  globe://auth/callback
  globe://email-confirmation
  https://yourdomain.com/**
```

**重要:**
- `globe://` は Xcode で設定した URL Scheme と一致させる
- 開発中は `http://localhost:3000/**` も追加すると便利

### 3. メールテンプレートを確認

Supabase Dashboard → Authentication → Email Templates → Confirm signup

デフォルトのテンプレートを確認:
```html
<h2>Confirm your signup</h2>

<p>Follow this link to confirm your user:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm your mail</a></p>
```

必要に応じてカスタマイズ:
```html
<h2>Welcome to GLOBE!</h2>

<p>Click the button below to verify your email address and complete your registration:</p>
<p><a href="{{ .ConfirmationURL }}" style="background-color: #008dc4; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">Verify Email</a></p>

<p style="color: #666; font-size: 12px; margin-top: 20px;">
If the button doesn't work, copy and paste this link into your browser:<br>
{{ .ConfirmationURL }}
</p>
```

### 4. アプリコードの確認（既に実装済み）

`GlobeApp.swift` で `.onOpenURL` ハンドラーが実装されています:

```swift
.onOpenURL { url in
    SecureLogger.shared.info("Received Deep Link URL: \(url.absoluteString)")
    Task {
        do {
            try await supabase.auth.session(from: url)
            SecureLogger.shared.info("Successfully handled auth URL")
            await authManager.validateSession()
        } catch {
            SecureLogger.shared.error("Failed to handle auth URL: \(error.localizedDescription)")
        }
    }
}
```

## テスト手順

### デバイス/シミュレータでテスト

1. アプリをビルドして実行
2. サインアップフローを実行
3. メールが届くのを確認
4. メール内のリンクをクリック
5. 以下のいずれかが起こるはず:
   - アプリが開く（シミュレータの場合）
   - "Open in GLOBE?" の確認ダイアログが表示される（実機の場合）

### コンソールログで確認

Xcodeのコンソールで以下のログを確認:
```
[SecureLogger] Received Deep Link URL: globe://auth/callback?...
[SecureLogger] Successfully handled auth URL
[AuthManager] Session validated successfully
```

### Deep Linkの動作確認（手動テスト）

シミュレータまたは実機でアプリ起動中に、Safariで以下のURLを開く:
```
globe://auth/callback
```

アプリが開けば、URL Schemeの設定は正しい。

## トラブルシューティング

### 問題: メールのリンクをクリックしてもアプリが開かない

**確認項目:**
- [ ] Xcode の URL Types に `globe` が設定されているか
- [ ] Supabase Dashboard の Redirect URLs に `globe://**` が追加されているか
- [ ] アプリを再ビルドしたか（Info.plist の変更後は再ビルドが必要）

**デバッグ方法:**
1. Xcodeのコンソールを開いておく
2. メールのリンクを長押しして、URLをコピー
3. URLの形式を確認: `https://...supabase.co/auth/v1/verify?token=...&type=signup&redirect_to=...`
4. `redirect_to` パラメータに `globe://` が含まれているか確認

### 問題: "Invalid Redirect URL" エラー

**原因:** Supabase Dashboard の Redirect URLs に設定されていないURLにリダイレクトしようとしている

**解決方法:**
1. Supabase Dashboard → Authentication → URL Configuration
2. エラーメッセージに表示されているURLを Redirect URLs に追加
3. ワイルドカード `globe://**` を使用

### 問題: アプリは開くが認証が完了しない

**確認項目:**
- [ ] `GlobeApp.swift` の `.onOpenURL` が実装されているか
- [ ] `supabase.auth.session(from: url)` が呼ばれているか
- [ ] コンソールにエラーログが出ていないか

**デバッグ方法:**
```swift
.onOpenURL { url in
    print("DEBUG: Received URL: \(url.absoluteString)")
    print("DEBUG: URL Host: \(url.host ?? "none")")
    print("DEBUG: URL Path: \(url.path)")
    print("DEBUG: URL Query: \(url.query ?? "none")")
    // ... 既存のコード
}
```

## 送信者名の変更

### 問題
メールの送信者名が "Supabase Auth" と表示される

### 解決方法

#### 方法1: カスタムSMTP設定（推奨）

Supabase Dashboard → Project Settings → Auth → SMTP Settings

```
Enable Custom SMTP: ON
Sender email: noreply@yourdomain.com
Sender name: GLOBE
Host: smtp.sendgrid.net (SendGrid/AWS SES/Gmail等)
Port: 587 (または 465)
Username: [SMTPサービスのユーザー名]
Password: [SMTPサービスのパスワード/APIキー]
```

**推奨SMTPプロバイダー:**
- **SendGrid** (無料枠: 100通/日)
- **AWS SES** (無料枠: 62,000通/月)
- **Resend** (無料枠: 3,000通/月)

#### 方法2: Supabase Pro プラン

- 無料プランでは送信者名のカスタマイズ不可
- Proプラン ($25/月) 以上でカスタムSMTP設定が可能

#### 暫定対応: メールテンプレートの最適化

送信者名は変更できなくても、メール本文でブランドを強調:

```html
<div style="max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif;">
  <div style="background-color: #000; padding: 20px; text-align: center;">
    <h1 style="color: white; margin: 0;">GLOBE</h1>
  </div>

  <div style="padding: 40px 20px;">
    <h2>Welcome to GLOBE!</h2>
    <p>Click the button below to verify your email address:</p>
    <p style="text-align: center;">
      <a href="{{ .ConfirmationURL }}"
         style="background-color: #008dc4; color: white; padding: 12px 24px;
                text-decoration: none; border-radius: 6px; display: inline-block;">
        Verify Email
      </a>
    </p>
  </div>

  <div style="background-color: #f5f5f5; padding: 20px; text-align: center; font-size: 12px; color: #666;">
    <p>This email was sent by GLOBE</p>
  </div>
</div>
```

## まとめ

### 必須設定
1. ✅ Xcode で URL Scheme `globe` を設定
2. ✅ Supabase Dashboard で `globe://**` を Redirect URLs に追加
3. ✅ GlobeApp.swift で `.onOpenURL` を実装（既に完了）

### オプション設定
1. メールテンプレートのカスタマイズ
2. カスタムSMTP設定（送信者名変更）

### テスト
1. アプリを再ビルド
2. サインアップを実行
3. メールのリンクをクリック
4. アプリが開いて認証が完了することを確認
