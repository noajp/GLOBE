# 🔐 GLOBE Development Setup

## ⚠️ Security Setup Required

このプロジェクトを実行する前に、Supabaseの認証情報を設定する必要があります。

### 1. Supabase Project Setup

1. [Supabase Dashboard](https://supabase.com/dashboard) でプロジェクトを作成
2. **Settings** > **API** から以下の情報を取得：
   - **Project URL** (例: `https://xxxxx.supabase.co`)
   - **anon/public key** (公開キー)

### 2. Local Configuration

以下のファイルに実際の値を設定してください：

#### A. GLOBE-Info.plist
```xml
<key>SupabaseURL</key>
<string>https://your-project-id.supabase.co</string>
<key>SupabaseAnonKey</key>
<string>your_anon_key_here</string>
```

#### B. GLOBE/Secrets.plist
```xml
<key>SUPABASE_URL</key>
<string>https://your-project-id.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>your_anon_key_here</string>
```

### 3. Database Setup

Supabase SQL Editor で以下のマイグレーションを順番に実行：
1. `Supabase/migrations/001_initial_setup.sql`
2. `Supabase/migrations/002_setup_avatars_bucket.sql`

### 4. Security Notes

🚨 **重要**: 
- `Secrets.plist` と認証情報は絶対にgitにコミットしない
- 本番環境では環境変数またはKeychainを使用
- サービスロールキーは使用しない（anonキーのみ）

### 5. Build and Run

```bash
open GLOBE.xcodeproj
# Xcode で Cmd+R で実行
```

問題が発生した場合は、[Issues](https://github.com/noajp/GLOBE/issues) で報告してください。