//======================================================================
// MARK: - PrivacySelectionView.swift
// Purpose: Privacy selection screen for post creation
// Path: GLOBE/Views/Components/PrivacySelectionView.swift
//======================================================================

import SwiftUI
import CoreLocation

struct PrivacySelectionView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var postManager: PostManager
    
    let postText: String
    let selectedImageData: Data?
    let location: CLLocationCoordinate2D
    let locationName: String
    let onPostComplete: () -> Void
    
    @State private var isPosting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let customBlack = MinimalDesign.Colors.background
    
    var body: some View {
        ZStack {
            // 背景
            customBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("投稿の公開範囲")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // バランス用の空スペース
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Spacer()
                
                // 選択ボタン
                VStack(spacing: 30) {
                    // 全体公開ボタン
                    Button(action: {
                        createPost(isAnonymous: false)
                    }) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "globe")
                                    .font(.system(size: 36))
                                    .foregroundColor(.blue)
                            }

                            Text("全体に公開")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Text("誰でも見ることができます")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 240, height: 160)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .disabled(isPosting)

                    // 匿名投稿ボタン
                    Button(action: {
                        createPost(isAnonymous: true)
                    }) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "theatermasks.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.purple)
                            }

                            Text("匿名で投稿")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Text("あなたの情報は表示されません")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 240, height: 160)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .disabled(isPosting)
                }
                
                Spacer()
                
                if isPosting {
                    ProgressView("投稿中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createPost(isAnonymous: Bool) {
        isPosting = true

        print("🚀 PrivacySelection - Starting post creation")
        print("📝 Content: '\(postText)'")
        print("📍 Location: \(location.latitude), \(location.longitude)")
        print("🔐 Privacy: \(isAnonymous ? "Anonymous" : "Public")")

        Task { @MainActor in
            do {
                try await postManager.createPost(
                    content: postText,
                    imageData: selectedImageData,
                    location: location,
                    locationName: locationName,
                    isAnonymous: isAnonymous
                )
                
                print("✅ PrivacySelection - Post created successfully")
                
                // キーボードを閉じる
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
                // 画面を閉じて元の画面に戻る
                isPresented = false
                onPostComplete()
                
            } catch {
                print("❌ PrivacySelection - Error creating post: \(error)")
                errorMessage = "投稿の作成に失敗しました: \(error.localizedDescription)"
                showError = true
                isPosting = false
            }
        }
    }
}