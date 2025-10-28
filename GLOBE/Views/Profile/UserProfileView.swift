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
        ZStack {
            // 背景タップで閉じる（地図が見えるように透明）
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented = false
                }

            // プロフィールカード
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // プロフィール情報
                    HStack(alignment: .top, spacing: 10) {
                        // Profile Image - COMMENTED OUT for v1.0 release
                        /*
                        ProfileImageView(
                            userProfile: userProfile,
                            size: 44
                        )
                        */

                        // Profile Info
                        VStack(alignment: .leading, spacing: 2) {
                            // Display Name
                            if let displayName = userProfile?.displayName, !displayName.isEmpty {
                                Text(displayName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            } else if let username = userProfile?.username {
                                Text(username)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }

                            // User ID with @ prefix
                            if let userId = userProfile?.id {
                                Text("@\(userId.prefix(8))")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)
                                    .padding(.leading, 6)
                            }
                        }

                        Spacer()
                    }
                    .padding(.bottom, 8)

                    // Bio Section
                    if let bio = userProfile?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .frame(height: 44)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
            .frame(width: 280, height: 170)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(radius: 10)

            // Loading overlay
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
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
            // Get Supabase client
            let client = await SupabaseManager.shared.client

            // プロフィールデータを取得
            let profileData = try await client
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
                SecureLogger.shared.info("UserProfileView: Profile loaded for user \(profile.username)")
            } else {
                await MainActor.run {
                    errorMessage = "プロフィールが見つかりませんでした"
                }
                SecureLogger.shared.warning("UserProfileView: Profile not found for userId: \(userId)")
            }

        } catch {
            await MainActor.run {
                errorMessage = "プロフィールの読み込みに失敗しました: \(error.localizedDescription)"
            }
            SecureLogger.shared.error("UserProfileView: Failed to load profile: \(error.localizedDescription)")
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