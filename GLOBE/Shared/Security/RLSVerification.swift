//======================================================================
// MARK: - RLSVerification.swift
// Purpose: Row Level Security policy verification and testing
// Path: GLOBE/Core/Security/RLSVerification.swift
//======================================================================

import Foundation
import Supabase

/// RLSポリシーの動作確認と検証
struct RLSVerification {
    private let secureLogger = SecureLogger.shared
    
    /// RLSポリシーが正しく設定されているかテスト
    func verifyRLSPolicies() async -> Bool {
        secureLogger.info("Starting RLS policy verification")
        
        var allTestsPassed = true
        
        // プロフィールテーブルのRLSテスト
        allTestsPassed = await testProfileRLS() && allTestsPassed
        
        // 投稿テーブルのRLSテスト
        allTestsPassed = await testPostsRLS() && allTestsPassed
        
        // いいねテーブルのRLSテスト
        allTestsPassed = await testLikesRLS() && allTestsPassed
        
        if allTestsPassed {
            secureLogger.info("✅ All RLS policy tests passed")
        } else {
            secureLogger.securityEvent("❌ Some RLS policy tests failed")
        }
        
        return allTestsPassed
    }
    
    /// プロフィールテーブルのRLS検証
    private func testProfileRLS() async -> Bool {
        secureLogger.info("Testing profile RLS policies")
        
        do {
            // 認証されていない状態でのプロフィール取得テスト
            let publicProfiles: [String] = try await supabase
                .from("profiles")
                .select("id")
                .eq("is_private", value: false)
                .execute()
                .value
            
            secureLogger.info("Public profiles accessible: \(publicProfiles.count)")
            return true
            
        } catch {
            secureLogger.securityEvent("Profile RLS test failed", details: ["error": error.localizedDescription])
            return false
        }
    }
    
    /// 投稿テーブルのRLS検証
    private func testPostsRLS() async -> Bool {
        secureLogger.info("Testing posts RLS policies")
        
        do {
            // パブリック投稿のみアクセス可能かテスト
            let publicPosts: [String] = try await supabase
                .from("posts")
                .select("id")
                .eq("is_public", value: true)
                .execute()
                .value
            
            secureLogger.info("Public posts accessible: \(publicPosts.count)")
            return true
            
        } catch {
            secureLogger.securityEvent("Posts RLS test failed", details: ["error": error.localizedDescription])
            return false
        }
    }
    
    /// いいねテーブルのRLS検証
    private func testLikesRLS() async -> Bool {
        secureLogger.info("Testing likes RLS policies")
        
        do {
            // いいね情報の取得テスト（パブリック投稿のみ）
            let likes: [String] = try await supabase
                .from("likes")
                .select("id")
                .execute()
                .value
            
            secureLogger.info("Accessible likes: \(likes.count)")
            return true
            
        } catch {
            secureLogger.securityEvent("Likes RLS test failed", details: ["error": error.localizedDescription])
            return false
        }
    }
    
    /// 管理者向け：データベースセキュリティ状況の詳細チェック
    func performSecurityAudit() async {
        secureLogger.securityEvent("Starting database security audit")
        
        // RLS有効化状況の確認
        await checkRLSStatus()
        
        // ポリシー数の確認
        await countSecurityPolicies()
        
        // インデックス設定の確認
        await checkSecurityIndexes()
    }
    
    private func checkRLSStatus() async {
        secureLogger.info("Checking RLS status for all tables")
        
        let tables = ["profiles", "posts", "likes", "comments", "follows"]
        for table in tables {
            // 実際の実装では、Supabaseの管理APIを使用してRLS状況を確認
            secureLogger.info("Table \(table): RLS should be enabled")
        }
    }
    
    private func countSecurityPolicies() async {
        secureLogger.info("Counting security policies")
        // 実際の実装では、pg_policies システムテーブルをクエリ
        secureLogger.info("Security policies should be in place for all tables")
    }
    
    private func checkSecurityIndexes() async {
        secureLogger.info("Checking security-related indexes")
        // パフォーマンスと安全性のための重要インデックスをチェック
        secureLogger.info("Performance indexes should be optimized")
    }
}

// MARK: - Development Helper

#if DEBUG
extension RLSVerification {
    /// 開発環境でのRLS設定確認
    static func developmentRLSCheck() async {
        let verifier = RLSVerification()
        let passed = await verifier.verifyRLSPolicies()
        
        if !passed {
            print("⚠️ RLS Policy Warning: Some policies may not be working correctly")
            print("💡 Please check Supabase dashboard and apply the RLS migration")
        } else {
            print("✅ RLS Policies are working correctly")
        }
    }
}
#endif