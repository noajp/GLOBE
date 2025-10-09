//======================================================================
// MARK: - UserProfileView.swift
// Purpose: User profile view for displaying other users' information
// Path: GLOBE/Views/UserProfileView.swift
//======================================================================

import SwiftUI
import Supabase

struct UserProfileView: View {
    let userName: String
    let userId: String
    @Binding var isPresented: Bool
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @StateObject private var postManager = PostManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    // 現在のユーザーかどうか
    private var isCurrentUser: Bool {
        return userId == authManager.currentUser?.id
    }

    // このユーザーの投稿を取得
    private var userPosts: [Post] {
        return postManager.posts.filter { $0.userId == userId }
    }

    var body: some View {
        GeometryReader { geometry in
            GlassEffectContainer {
                ZStack {
                    // 背景タップで閉じる（透明度を下げて地図を見やすく）
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isPresented = false
                        }

                    // プロフィールカードポップアップ（画面の下半分）
                    VStack(spacing: 0) {
                        Spacer()

                        VStack(spacing: 16) {
                            HStack(alignment: .top, spacing: 16) {
                                // Profile Image
                                ProfileImageView(
                                    userProfile: userProfile,
                                    size: 70
                                )

                                // Profile Info
                                VStack(alignment: .leading, spacing: 8) {
                                    // Display Name
                                    if let displayName = userProfile?.displayName, !displayName.isEmpty {
                                        Text(displayName)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(MinimalDesign.Colors.primary)
                                            .lineLimit(1)
                                    } else if let username = userProfile?.username {
                                        Text(username)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(MinimalDesign.Colors.primary)
                                            .lineLimit(1)
                                    }

                                    // User ID with @ prefix
                                    if let userId = userProfile?.id {
                                        Text("@\(userId.prefix(8))")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }

                                    Spacer(minLength: 8)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, MinimalDesign.Spacing.sm)

                            // Bio Section
                            if let bio = userProfile?.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, MinimalDesign.Spacing.sm)
                            }

                            Spacer()
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                        .frame(height: geometry.size.height * 0.5)
                        .frame(maxWidth: .infinity)
                        .glassEffect(.clear, in: UnevenRoundedRectangle(
                            topLeadingRadius: 24,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 24
                        ))
                        .overlay(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 24,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 24
                            )
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(radius: 10)
                        .padding(.horizontal, 0)
                        .padding(.bottom, 0)
                    }

                    // Loading overlay
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.ultraThinMaterial.opacity(0.8))
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadUserProfile()
            }
        }
    }

    // MARK: - Data Loading
    private func loadUserProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // プロフィールデータを取得
            let profileData = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()

            let decoder = JSONDecoder()
            let profiles = try decoder.decode([UserProfile].self, from: profileData.data)

            if let profile = profiles.first {
                await MainActor.run {
                    userProfile = profile
                }
                print("✅ UserProfileView: Profile loaded for \(profile.username)")
            } else {
                await MainActor.run {
                    errorMessage = "プロフィールが見つかりませんでした"
                }
                print("❌ UserProfileView: Profile not found for userId: \(userId)")
            }

        } catch {
            await MainActor.run {
                errorMessage = "プロフィールの読み込みに失敗しました: \(error.localizedDescription)"
            }
            print("❌ UserProfileView: Failed to load profile: \(error)")
        }
    }
}

#Preview {
    UserProfileView(
        userName: "John Doe",
        userId: "12345678",
        isPresented: .constant(true)
    )
}