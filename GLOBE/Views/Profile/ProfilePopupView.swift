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
    @State private var isEditing = false
    @State private var dragOffset: CGFloat = 0

    // 編集用の一時的な状態
    @State private var editingDisplayName = ""
    @State private var editingBio = ""

    var body: some View {
        GeometryReader { geometry in
            GlassEffectContainer {
                ZStack {
                    // 背景タップで閉じる（プロフィールカード以外の部分）
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isPresented = false
                        }

                    // プロフィールカードポップアップ（投稿作成カードと同じ位置・サイズ）
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 0) {
                                // ヘッダー（設定ボタン）
                                HStack {
                                    Spacer()

                                    // 設定ボタン（三本線）
                                    Button(action: {
                                        showSettings = true
                                    }) {
                                        Image(systemName: "line.3.horizontal")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.black)
                                            .frame(width: 28, height: 28)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.bottom, 4)

                                // プロフィール情報
                                HStack(alignment: .top, spacing: 10) {
                                    // Profile Image
                                    ProfileImageView(
                                        userProfile: viewModel.userProfile,
                                        size: 44
                                    )

                                    // Profile Info
                                    VStack(alignment: .leading, spacing: 2) {
                                        // Display Name (編集可能)
                                        ZStack(alignment: .leading) {
                                            if isEditing {
                                                TextField("Display Name", text: $editingDisplayName)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.black)
                                                    .textFieldStyle(PlainTextFieldStyle())
                                            } else {
                                                if let displayName = viewModel.userProfile?.displayName, !displayName.isEmpty {
                                                    Text(displayName)
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundColor(.black)
                                                        .lineLimit(1)
                                                } else if let username = viewModel.userProfile?.username {
                                                    Text(username)
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundColor(.black)
                                                        .lineLimit(1)
                                                }
                                            }
                                        }
                                        .frame(height: 23)
                                        .padding(.horizontal, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .strokeBorder(isEditing ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )

                                        // User ID with @ prefix
                                        if let userId = viewModel.userProfile?.id {
                                            Text("@\(userId.prefix(8))")
                                                .font(.system(size: 10, weight: .regular))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                                .padding(.leading, 6)
                                        }
                                    }

                                    Spacer()

                                    // Edit/Save/Cancel Buttons
                                    if isEditing {
                                        HStack(spacing: 4) {
                                            Button(action: {
                                                // キャンセル
                                                isEditing = false
                                            }) {
                                                Text("Cancel")
                                                    .font(.system(size: 9, weight: .medium))
                                                    .foregroundColor(.gray)
                                                    .lineLimit(1)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 3)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .fixedSize()

                                            Button(action: {
                                                // 保存
                                                Task {
                                                    let username = viewModel.userProfile?.username ?? ""
                                                    await viewModel.updateProfile(
                                                        username: username,
                                                        displayName: editingDisplayName,
                                                        bio: editingBio
                                                    )
                                                    isEditing = false
                                                }
                                            }) {
                                                Text("Save")
                                                    .font(.system(size: 9, weight: .medium))
                                                    .foregroundColor(.black)
                                                    .lineLimit(1)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 3)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .fixedSize()
                                        }
                                    } else {
                                        Button(action: {
                                            // 編集モードに切り替え
                                            editingDisplayName = viewModel.userProfile?.displayName ?? viewModel.userProfile?.username ?? ""
                                            editingBio = viewModel.userProfile?.bio ?? ""
                                            isEditing = true
                                        }) {
                                            Text("Edit")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.black)
                                                .lineLimit(1)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .fixedSize()
                                    }
                                }

                                // BIO Section
                                if isEditing || (viewModel.userProfile?.bio != nil && !viewModel.userProfile!.bio!.isEmpty) {
                                    ZStack(alignment: .topLeading) {
                                        if isEditing {
                                            // プレースホルダー
                                            if editingBio.isEmpty {
                                                Text("Bio")
                                                    .font(.system(size: 11, weight: .regular))
                                                    .foregroundColor(.gray.opacity(0.5))
                                                    .padding(.leading, 11)
                                                    .padding(.top, 12)
                                            }
                                            TextEditor(text: $editingBio)
                                                .font(.system(size: 11, weight: .regular))
                                                .foregroundColor(.black)
                                                .scrollContentBackground(.hidden)
                                                .background(Color.clear)
                                        } else {
                                            if let bio = viewModel.userProfile?.bio, !bio.isEmpty {
                                                Text(bio)
                                                    .font(.system(size: 11, weight: .regular))
                                                    .foregroundColor(.black)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                            }
                                        }
                                    }
                                    .frame(height: 44)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(isEditing ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                    .padding(.top, 8)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 12)
                            .padding(.bottom, 12)
                        }
                        .frame(width: 280, height: 170)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(radius: 10)
                        .offset(y: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // 下方向のドラッグのみ許可
                                    if value.translation.height > 0 {
                                        dragOffset = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    // 100ポイント以上下にドラッグしたら閉じる
                                    if value.translation.height > 100 {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            dragOffset = 500 // 画面外まで移動
                                        }
                                        // アニメーション完了後に閉じる
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            isPresented = false
                                            dragOffset = 0
                                        }
                                    } else {
                                        // 元の位置に戻す
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            Task {
                await viewModel.loadUserData()
            }
        }
    }
}
