//======================================================================
// MARK: - ProfilePopupView.swift
// Purpose: Popup view showing only the profile section
// Path: GLOBE/Views/Profile/ProfilePopupView.swift
//======================================================================

import SwiftUI

struct ProfilePopupView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = MyPageViewModel()
    @State private var showSettings = false
    @State private var showEditProfile = false

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

                        HStack(alignment: .center, spacing: 12) {
                            // Profile Image
                            ProfileImageView(
                                userProfile: viewModel.userProfile,
                                size: 44
                            )

                            // Profile Info
                            VStack(alignment: .leading, spacing: 2) {
                                // Display Name
                                if let displayName = viewModel.userProfile?.displayName, !displayName.isEmpty {
                                    Text(displayName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(MinimalDesign.Colors.primary)
                                        .lineLimit(1)
                                } else if let username = viewModel.userProfile?.username {
                                    Text(username)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(MinimalDesign.Colors.primary)
                                        .lineLimit(1)
                                }

                                // User ID with @ prefix
                                if let userId = viewModel.userProfile?.id {
                                    Text("@\(userId.prefix(8))")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Edit Profile Button
                            Button(action: {
                                showEditProfile = true
                                isPresented = false
                            }) {
                                Text("Edit")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 12))
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 24,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 24
                            )
                            .fill(Color.black.opacity(0.3))
                        )
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
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .onAppear {
            Task {
                await viewModel.loadUserData()
            }
        }
    }
}
