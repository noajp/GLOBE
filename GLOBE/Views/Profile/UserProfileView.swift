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
            // Background layer (solid black #121212)
            Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Content layer
            VStack(spacing: 0) {
                // Close button at top
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }

                // Profile content
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else {
                    // Embed ProfileView with userId parameter
                    ProfileView(userId: userId)
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
                SecureLogger.shared.info("UserProfileView: Profile loaded for user \(profile.displayName ?? profile.id)")
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