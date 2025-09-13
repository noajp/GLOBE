# 🔧 GLOBE アプリの設定方法

## 🚨 認証エラーの修正

現在、アプリで以下のエラーが発生しています：
```
A server with the specified hostname could not be found.
```

これは、Supabaseの設定がプレースホルダー値のままになっているためです。

## ⚙️ 設定手順

### 方法1: Secrets.plist を編集（推奨）

`GLOBE/Secrets.plist` ファイルを開いて、以下のプレースホルダーを実際の値に置き換えてください：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://kkznkqshpdzlhtuawasm.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtrem5rcXNocGR6bGh0dWF3YXNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjM3Njc3NjgsImV4cCI6MjAzOTM0Mzc2OH0.lOCtGLCzXaIBQUWE9VzRUOV8nLQgz9YqVm6lrpQBEAE</string>
</dict>
</plist>
```

### 方法2: Info.plist を編集

`GLOBE-Info.plist` ファイルで同様の設定を行うこともできます。

### 方法3: プログラムで設定

アプリ起動時に以下のコードで設定することも可能：

```swift
SecureConfig.shared.setSupabaseConfig(
    url: "https://kkznkqshpdzlhtuawasm.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtrem5rcXNocGR6bGh0dWF3YXNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjM3Njc3NjgsImV4cCI6MjAzOTM0Mzc2OH0.lOCtGLCzXaIBQUWE9VzRUOV8nLQgz9YqVm6lrpQBEAE"
)
```

## 🔍 デバッグ情報

設定が正しく読み込まれているかを確認するため、アプリ起動時に以下のようなログが表示されます：

```
🔍 Config: Loading Supabase URL...
🔍 Config: Found URL in Secrets.plist: 'https://...'
🔵 Supabase URL from Secrets.plist: https://...
```

## ⚠️ セキュリティ注意

- 実際の認証情報を設定後、**絶対にgitにコミットしないでください**
- `Secrets.plist` は既に `.gitignore` で除外されています
- テスト後は値をプレースホルダーに戻すことを推奨します