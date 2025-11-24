//======================================================================
// MARK: - AppleSignUpProfileSetupView.swift
// Purpose: Profile setup after Apple Sign In (User ID + Display Name only)
// Path: GLOBE/Views/Auth/AppleSignUpProfileSetupView.swift
//======================================================================
import SwiftUI
import Supabase

struct AppleSignUpProfileSetupView: View {
    let session: Session

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var userId = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isUserIdValid = false
    @State private var isCheckingUserId = false
    @State private var userIdValidationMessage = ""

    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Complete Your Profile")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(MinimalDesign.Colors.text)

                        Text("Set up your profile information")
                            .font(.system(size: 16))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 20) {
                        // User ID input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("User ID")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MinimalDesign.Colors.textSecondary)

                            HStack(spacing: 0) {
                                Text("@")
                                    .font(.system(size: 17))
                                    .foregroundColor(MinimalDesign.Colors.text)

                                TextField("", text: $userId)
                                    .font(.system(size: 17))
                                    .foregroundColor(MinimalDesign.Colors.text)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: userId) { _, newValue in
                                        Task {
                                            await checkUserIdAvailability(newValue)
                                        }
                                    }
                            }
                            .padding(16)
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(12)

                            // Validation status
                            if isCheckingUserId {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Checking...")
                                        .font(.system(size: 12))
                                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                                }
                            } else if !userIdValidationMessage.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: isUserIdValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(isUserIdValid ? .green : .red)
                                    Text(userIdValidationMessage)
                                        .font(.system(size: 12))
                                        .foregroundColor(isUserIdValid ? .green : .red)
                                }
                            }
                        }

                        // Display Name input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MinimalDesign.Colors.textSecondary)

                            TextField("", text: $displayName)
                                .font(.system(size: 17))
                                .foregroundColor(MinimalDesign.Colors.text)
                                .padding(16)
                                .background(MinimalDesign.Colors.secondaryBackground)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 32)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                    }

                    // Create Account button
                    Button(action: {
                        Task {
                            await createProfile()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Complete")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .background(canComplete ? Color(red: 0.0, green: 0.55, blue: 0.75) : Color.gray)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .disabled(!canComplete || isLoading)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Appleから取得した名前を初期値として設定（もしあれば）
            if let fullName = session.user.userMetadata["full_name"] as? String {
                displayName = fullName
            }
        }
    }

    private var canComplete: Bool {
        !userId.isEmpty &&
        isUserIdValid &&
        !displayName.isEmpty
    }

    private func checkUserIdAvailability(_ userid: String) async {
        isCheckingUserId = true
        isUserIdValid = false
        userIdValidationMessage = ""

        let cleanedUserId = userid.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !cleanedUserId.isEmpty else {
            isCheckingUserId = false
            return
        }

        guard cleanedUserId.count >= 3 && cleanedUserId.count <= 30 else {
            userIdValidationMessage = "User ID must be 3-30 characters"
            isCheckingUserId = false
            return
        }

        guard cleanedUserId.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            userIdValidationMessage = "Only lowercase letters, numbers, and underscores"
            isCheckingUserId = false
            return
        }

        do {
            let response = try await supabase
                .from("profiles")
                .select("id")
                .eq("userid", value: cleanedUserId)
                .execute()

            let decoder = JSONDecoder()
            let profiles = try? decoder.decode([UserProfile].self, from: response.data)

            if profiles?.isEmpty ?? true {
                isUserIdValid = true
                userIdValidationMessage = "✓ Available"
            } else {
                isUserIdValid = false
                userIdValidationMessage = "Already taken"
            }
        } catch {
            userIdValidationMessage = "Error checking availability"
        }

        isCheckingUserId = false
    }

    private func createProfile() async {
        errorMessage = nil
        isLoading = true

        let cleanedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            // profilesテーブルに保存
            struct ProfileInsert: Encodable {
                let id: String
                let userid: String
                let display_name: String
                let email: String
                let avatar_url: String?
                let bio: String?
                let post_count: Int
                let follower_count: Int
                let following_count: Int
            }

            let profileData = ProfileInsert(
                id: session.user.id.uuidString,
                userid: cleanedUserId,
                display_name: trimmedDisplayName,
                email: session.user.email ?? "",
                avatar_url: nil,
                bio: nil,
                post_count: 0,
                follower_count: 0,
                following_count: 0
            )

            try await supabase
                .from("profiles")
                .insert(profileData)
                .execute()

            SecureLogger.shared.info("Profile created successfully for Apple Sign In user")

            // AuthManagerのセッションを更新
            _ = try? await authManager.validateSession()

            // 画面を閉じる
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            SecureLogger.shared.error("Profile creation failed: \(error.localizedDescription)")
        }

        isLoading = false
    }
}

#Preview {
    // Preview用のダミーセッション
    let dummySession = Session(
        accessToken: "dummy",
        tokenType: "bearer",
        expiresIn: 3600,
        expiresAt: Date().addingTimeInterval(3600).timeIntervalSince1970,
        refreshToken: "dummy",
        user: User(
            id: UUID(),
            appMetadata: [:],
            userMetadata: ["full_name": "山田太郎"],
            aud: "authenticated",
            createdAt: Date(),
            updatedAt: Date()
        )
    )

    NavigationStack {
        AppleSignUpProfileSetupView(session: dummySession)
            .environmentObject(AuthManager.shared)
    }
}
