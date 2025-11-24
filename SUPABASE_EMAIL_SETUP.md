# Supabase Email 設定ガイド（Proプラン）

## 目的
- 送信者名を "Supabase Auth" → "GLOBE" に変更
- カスタムドメインのメールアドレスから送信
- プロフェッショナルなメールテンプレートを設定

## 設定手順

### 1. カスタムSMTP設定

Supabase Dashboard → Project Settings → Auth → SMTP Settings

#### オプションA: Supabaseのデフォルト設定をカスタマイズ（簡単）

Proプランでは、Supabaseの送信インフラを使いながら送信者名をカスタマイズ可能:

```
Sender name: GLOBE
Sender email: noreply@supabase.co (Supabaseのデフォルト)
```

**メリット:**
- 設定が簡単
- Supabaseのインフラが安定している
- 追加のSMTPサービス不要

**デメリット:**
- 送信元ドメインは supabase.co のまま
- 完全なブランディングではない

#### オプションB: カスタムSMTPサービスを使用（推奨）

完全にカスタマイズしたい場合は、独自のSMTPサービスを設定:

**推奨プロバイダー:**

##### 1. SendGrid（推奨）
```
Enable Custom SMTP: ON
Sender name: GLOBE
Sender email: noreply@yourdomain.com
Host: smtp.sendgrid.net
Port: 587
Username: apikey
Password: [SendGrid API Key]
```

**SendGrid設定手順:**
1. SendGrid にサインアップ (https://sendgrid.com/)
2. Settings → API Keys → Create API Key
3. Permissions: "Full Access" または "Mail Send"
4. API Keyをコピー
5. Sender Authentication でドメインまたはメールアドレスを認証

##### 2. AWS SES
```
Enable Custom SMTP: ON
Sender name: GLOBE
Sender email: noreply@yourdomain.com
Host: email-smtp.ap-northeast-1.amazonaws.com
Port: 587
Username: [AWS SES SMTP Username]
Password: [AWS SES SMTP Password]
```

**AWS SES設定手順:**
1. AWS Console → SES
2. Verified identities → Create identity
3. ドメインまたはメールアドレスを認証
4. SMTP settings → Create SMTP credentials
5. Username/Passwordを取得

##### 3. Resend（最新、開発者フレンドリー）
```
Enable Custom SMTP: ON
Sender name: GLOBE
Sender email: noreply@yourdomain.com
Host: smtp.resend.com
Port: 587
Username: resend
Password: [Resend API Key]
```

**Resend設定手順:**
1. Resend にサインアップ (https://resend.com/)
2. API Keys → Create API Key
3. Domains → Add Domain（独自ドメイン使用の場合）

### 2. ドメイン認証（独自ドメイン使用時）

カスタムドメイン（例: `noreply@globe.app`）を使用する場合:

#### DNS設定が必要:
```
SPF レコード:
TXT @ "v=spf1 include:sendgrid.net ~all"

DKIM レコード:
CNAME s1._domainkey [SMTPプロバイダーから提供される値]
CNAME s2._domainkey [SMTPプロバイダーから提供される値]

DMARC レコード:
TXT _dmarc "v=DMARC1; p=none; rua=mailto:dmarc@yourdomain.com"
```

**重要:** DNSレコードの反映には最大48時間かかる場合があります。

### 3. メールテンプレートのカスタマイズ

Supabase Dashboard → Authentication → Email Templates

#### Confirm Signup（メール認証）

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; background-color: #f5f5f5; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 40px 0;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="background-color: #000000; padding: 40px 20px; text-align: center;">
                            <h1 style="color: white; margin: 0; font-size: 32px; font-weight: bold;">GLOBE</h1>
                        </td>
                    </tr>

                    <!-- Body -->
                    <tr>
                        <td style="padding: 40px 40px 20px 40px;">
                            <h2 style="color: #333; margin: 0 0 20px 0; font-size: 24px;">Welcome to GLOBE!</h2>
                            <p style="color: #666; font-size: 16px; line-height: 1.6; margin: 0 0 30px 0;">
                                Thanks for signing up! Click the button below to verify your email address and start sharing your location-based posts with the world.
                            </p>
                        </td>
                    </tr>

                    <!-- Button -->
                    <tr>
                        <td style="padding: 0 40px 40px 40px; text-align: center;">
                            <a href="{{ .ConfirmationURL }}"
                               style="display: inline-block; background-color: #008dc4; color: white;
                                      padding: 16px 40px; text-decoration: none; border-radius: 8px;
                                      font-size: 16px; font-weight: 600;">
                                Verify Email
                            </a>
                        </td>
                    </tr>

                    <!-- Alternative Link -->
                    <tr>
                        <td style="padding: 0 40px 40px 40px;">
                            <p style="color: #999; font-size: 13px; line-height: 1.6; margin: 0;">
                                If the button doesn't work, copy and paste this link into your browser:
                            </p>
                            <p style="color: #008dc4; font-size: 13px; word-break: break-all; margin: 10px 0 0 0;">
                                {{ .ConfirmationURL }}
                            </p>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f9f9f9; padding: 30px 40px; border-top: 1px solid #eee;">
                            <p style="color: #999; font-size: 12px; margin: 0; text-align: center;">
                                This email was sent by GLOBE. If you didn't sign up for GLOBE, you can safely ignore this email.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
```

#### Magic Link（パスワードレスログイン用）

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; background-color: #f5f5f5; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 40px 0;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="background-color: #000000; padding: 40px 20px; text-align: center;">
                            <h1 style="color: white; margin: 0; font-size: 32px; font-weight: bold;">GLOBE</h1>
                        </td>
                    </tr>

                    <!-- Body -->
                    <tr>
                        <td style="padding: 40px 40px 20px 40px;">
                            <h2 style="color: #333; margin: 0 0 20px 0; font-size: 24px;">Sign in to GLOBE</h2>
                            <p style="color: #666; font-size: 16px; line-height: 1.6; margin: 0 0 30px 0;">
                                Click the button below to sign in to your account. This link will expire in 1 hour.
                            </p>
                        </td>
                    </tr>

                    <!-- Button -->
                    <tr>
                        <td style="padding: 0 40px 40px 40px; text-align: center;">
                            <a href="{{ .ConfirmationURL }}"
                               style="display: inline-block; background-color: #008dc4; color: white;
                                      padding: 16px 40px; text-decoration: none; border-radius: 8px;
                                      font-size: 16px; font-weight: 600;">
                                Sign In
                            </a>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f9f9f9; padding: 30px 40px; border-top: 1px solid #eee;">
                            <p style="color: #999; font-size: 12px; margin: 0; text-align: center;">
                                If you didn't request this email, you can safely ignore it.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
```

#### Reset Password（パスワードリセット）

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; background-color: #f5f5f5; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 40px 0;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="background-color: #000000; padding: 40px 20px; text-align: center;">
                            <h1 style="color: white; margin: 0; font-size: 32px; font-weight: bold;">GLOBE</h1>
                        </td>
                    </tr>

                    <!-- Body -->
                    <tr>
                        <td style="padding: 40px 40px 20px 40px;">
                            <h2 style="color: #333; margin: 0 0 20px 0; font-size: 24px;">Reset Your Password</h2>
                            <p style="color: #666; font-size: 16px; line-height: 1.6; margin: 0 0 30px 0;">
                                You requested to reset your password. Click the button below to create a new password. This link will expire in 1 hour.
                            </p>
                        </td>
                    </tr>

                    <!-- Button -->
                    <tr>
                        <td style="padding: 0 40px 40px 40px; text-align: center;">
                            <a href="{{ .ConfirmationURL }}"
                               style="display: inline-block; background-color: #008dc4; color: white;
                                      padding: 16px 40px; text-decoration: none; border-radius: 8px;
                                      font-size: 16px; font-weight: 600;">
                                Reset Password
                            </a>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f9f9f9; padding: 30px 40px; border-top: 1px solid #eee;">
                            <p style="color: #999; font-size: 12px; margin: 0; text-align: center;">
                                If you didn't request a password reset, you can safely ignore this email. Your password will not be changed.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
```

#### Change Email（メールアドレス変更）

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; background-color: #f5f5f5; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 40px 0;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="background-color: #000000; padding: 40px 20px; text-align: center;">
                            <h1 style="color: white; margin: 0; font-size: 32px; font-weight: bold;">GLOBE</h1>
                        </td>
                    </tr>

                    <!-- Body -->
                    <tr>
                        <td style="padding: 40px 40px 20px 40px;">
                            <h2 style="color: #333; margin: 0 0 20px 0; font-size: 24px;">Confirm Email Change</h2>
                            <p style="color: #666; font-size: 16px; line-height: 1.6; margin: 0 0 30px 0;">
                                Click the button below to confirm your new email address.
                            </p>
                        </td>
                    </tr>

                    <!-- Button -->
                    <tr>
                        <td style="padding: 0 40px 40px 40px; text-align: center;">
                            <a href="{{ .ConfirmationURL }}"
                               style="display: inline-block; background-color: #008dc4; color: white;
                                      padding: 16px 40px; text-decoration: none; border-radius: 8px;
                                      font-size: 16px; font-weight: 600;">
                                Confirm Email Change
                            </a>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f9f9f9; padding: 30px 40px; border-top: 1px solid #eee;">
                            <p style="color: #999; font-size: 12px; margin: 0; text-align: center;">
                                If you didn't request this change, please contact support immediately.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
```

### 4. テスト

#### テスト用メール送信
Supabase Dashboard → Authentication → Users → Invite User

テストメールを自分のアドレスに送信して確認:
- [ ] 送信者名が "GLOBE" になっているか
- [ ] メールテンプレートが正しく表示されているか
- [ ] リンクをクリックしてアプリが開くか
- [ ] 認証が正常に完了するか

#### スパムチェック
- Gmail/Outlook等の主要メールサービスでテスト
- スパムフォルダに入らないか確認
- SPF/DKIM/DMARC設定が正しいか確認

## トラブルシューティング

### メールが届かない

**確認項目:**
- [ ] SMTP認証情報が正しいか
- [ ] 送信元メールアドレスが認証されているか
- [ ] DNS設定（SPF/DKIM）が正しいか
- [ ] Supabase Dashboard → Logs でエラーを確認

### スパムフォルダに入る

**対策:**
- SPF/DKIM/DMARC を正しく設定
- 送信元ドメインの評判を確認（Sender Score等）
- メール本文のスパムワードを避ける
- 画像とテキストのバランスを調整

### 認証リンクが動作しない

**確認項目:**
- [ ] Redirect URLs が正しく設定されているか
- [ ] URL Scheme が正しく設定されているか
- [ ] `.onOpenURL` ハンドラーが実装されているか

## まとめ

### 最小限の設定（すぐに使える）
1. Supabase Dashboard → Project Settings → Auth
2. Sender name を "GLOBE" に変更
3. メールテンプレートを更新

### 推奨設定（プロダクション向け）
1. SendGrid/AWS SESでカスタムSMTP設定
2. 独自ドメインのメールアドレス使用
3. SPF/DKIM/DMARC設定
4. プロフェッショナルなHTMLメールテンプレート

### コスト
- SendGrid: 無料枠 100通/日、$15/月〜
- AWS SES: $0.10 per 1,000 emails
- Resend: 無料枠 3,000通/月、$20/月〜

メール送信サービスのResendが日本でもまともに使えるようになったので紹介したい
2024/06/17に公開
2024/06/19
3件

React

email

Resend

tech
API経由でメール送信をするためのサービスといえば、SendGrid, Amazon SES, Postmarkのような名前が出てくるかと思います。

そんな中、弊社(トラストハブ)でも利用しているResendというサービスがとても使いやすいので紹介します。また、記事後半でResendを日本で使うにあたり重要なアップデートがあったので、どんな点が変わったかを紹介します。

そもそもResendとはどんなサービスか
Resendは後発サービスなだけあり、開発体験の良さに主眼が置かれて開発されています。テストでメールが送信できていることを確認する機能や、ログを確認する機能など、細かいところが使い勝手が良いなと感じています。

SDK・設定がシンプル
公式でたくさんの言語のSDKが用意されています。また、フレームワークごとに組み込むためのドキュメントも充実しています。

Knowledge Baseを見ると、メールに関する知識を学ぶことができる点も助かりました。例えば、Gmailのスパムフォルダ行きをなるべく回避するにはどうすれば良いか、など実践的な記事がまとまって掲載されています。



設定もシンプルで、メールの信頼性管理に必要な機能である専用IPアドレスがすぐに取得できるのも良い点です。

React Emailとの組み合わせが使いやすい
Resendが出している、ReactでメールテンプレートをかけるライブラリであるReact Emailが、Postmarkなどが提供しているメールのテンプレートライブラリと比較してとても使いやすいです。単にReactで書けるというだけでも便利なのですが、ビルド周りが現代的な構成になっているのが推せるポイントです。

Tailwind CSSでメールのスタイリングもすることができるので、メールのために生のCSSを書くなんていうこともしなくて良くなります。

Resendとも簡単に組み合わせて使うことができるのも良いポイントです。また、このライブラリはResend以外のメールサービスでも使うことができます。



マーケティング目的のメール送信もできる機能
最近になって、SendGridのように管理画面からメールを作成して一斉送信できる機能がリリースされました。



とはいえ、コンタクト数ごとの課金でちょっと料金は高いかもしれません。

自分たちは他のマーケティングサービス(HubSpot)を使っているため、今のところ使っていない機能です。

テスト的にメールマーケティングを始めてみたい、という状況ならフィットするのではないでしょうか。

日本で使うにあたっての課題と、アップデートで改善された点
ここからが本題になります。最近のアップデートで、日本でメールサービスを選ぶ上で重要なポイントが改善されました。

日本リージョンが追加された
これまで北アメリカ・南アメリカ・ヨーロッパのみにサーバーがあったのですが、新しくTokyoサーバーが追加されました。

サーバーとの距離がメールの到着遅延に影響しているようなので、なるべく近いサーバーを選んだ方が良いでしょう。



キャリアメールに送信できるようになった
Resendはメール送信時にTLS暗号化を強制というポリシーで運用されていました。しかし、これによって日本の環境だとキャリアメールへの送信がうまくいかないという問題がありました。

というのも、多くのキャリアメールは今でもTLS暗号が使えないという仕様のようなのです。

しかし、最近のリリースで投機的TLSというオプションが追加されました。これは、送信先サーバーがTLS暗号が使えない環境だと判断されると、自動的に平文でメールを送信するという機能になります。

日本のサービスでResendを採用する際に大きな障害となっていた箇所なので、大きな改善ですね。



まとめ
Resendは使いやすいメール送信サービス
日本の環境に合わせた機能追加が実施され、Resendを選ばない大きな理由が取り除かれた
新規でメール送信サービスを選ぶならResendがおすすめ！