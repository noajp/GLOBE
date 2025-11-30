//======================================================================
// MARK: - SignUpFlowView.swift
// Purpose: Sign up flow with step indicator (Step 1: Apple Auth, Step 2: Profile Setup)
// Path: GLOBE/Views/Auth/SignUpFlowView.swift
//======================================================================

import SwiftUI
import AuthenticationServices
import Supabase
import PhotosUI

struct SignUpFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var currentStep = 1
    @State private var session: Session?
    @State private var showError = false
    @State private var errorMessage = ""

    private let customBlack = MinimalDesign.Colors.background
    private let totalSteps = 2

    var body: some View {
        ZStack {
            customBlack
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button and step indicator
                VStack(spacing: 16) {
                    // Close button
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)

                    // Step indicator
                    StepIndicator(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 60)

                // Content based on current step
                if currentStep == 1 {
                    SignUpStep1View(
                        onSuccess: { newSession in
                            session = newSession
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep = 2
                            }
                        },
                        onError: { message in
                            errorMessage = message
                            showError = true
                        }
                    )
                } else if currentStep == 2, let session = session {
                    SignUpStep2View(
                        session: session,
                        onComplete: {
                            dismiss()
                        }
                    )
                    .environmentObject(authManager)
                }

                Spacer()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Step 1: Apple Authentication

struct SignUpStep1View: View {
    let onSuccess: (Session) -> Void
    let onError: (String) -> Void

    private let customBlack = MinimalDesign.Colors.background

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            // Logo and title
            VStack(spacing: 12) {
                Text("GLOBE")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2)

                Text("Create your account")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            // Apple Sign Up Button
            VStack(spacing: 16) {
                SignInWithAppleButton(.signUp) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        await handleAppleSignUp(result)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .cornerRadius(26)

                Text("We'll create your account using your Apple ID")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    @MainActor
    private func handleAppleSignUp(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                SecureLogger.shared.error("Failed to get Apple ID credential")
                onError("Failed to get Apple ID credential")
                return
            }

            guard let identityToken = appleIDCredential.identityToken,
                  let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                SecureLogger.shared.error("Failed to get identity token")
                onError("Failed to get identity token")
                return
            }

            do {
                let session = try await supabase.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: identityTokenString
                    )
                )

                SecureLogger.shared.info("Apple Sign Up successful: \(session.user.id)")

                // プロフィールが既に存在するかチェック
                let profileExists = try await checkProfileExists(userId: session.user.id.uuidString)

                if profileExists {
                    // 既にアカウントがある場合はサインアウトしてエラー表示
                    SecureLogger.shared.warning("Account already exists")
                    try? await supabase.auth.signOut()
                    onError("Account already exists. Please sign in instead.")
                } else {
                    // 新規ユーザー → Step 2へ
                    onSuccess(session)
                }
            } catch {
                SecureLogger.shared.error("Apple Sign Up failed: \(error.localizedDescription)")
                onError("Sign up failed. Please try again.")
            }

        case .failure(let error):
            SecureLogger.shared.error("Apple Sign Up authorization failed: \(error.localizedDescription)")
            if (error as NSError).code != 1001 { // 1001 = user cancelled
                onError("Sign up failed. Please try again.")
            }
        }
    }

    private func checkProfileExists(userId: String) async throws -> Bool {
        let response = try await supabase
            .from("profiles")
            .select("id")
            .eq("id", value: userId)
            .execute()

        let decoder = JSONDecoder()
        let profiles = try? decoder.decode([UserProfile].self, from: response.data)

        return !(profiles?.isEmpty ?? true)
    }
}

// MARK: - Step 2: Profile Setup

struct SignUpStep2View: View {
    let session: Session
    let onComplete: () -> Void

    @EnvironmentObject var authManager: AuthManager

    @State private var userId = ""
    @State private var displayName = ""
    @State private var bio = ""
    @State private var selectedCountry: Country?
    @State private var countrySearchQuery = ""
    @State private var showCountryPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isUserIdValid = false
    @State private var isCheckingUserId = false
    @State private var userIdValidationMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Step title
            Text("Complete Your Profile")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 32)

            ScrollView {
                VStack(spacing: 20) {
                    // Avatar picker
                    VStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            ZStack {
                                if let avatarImage = avatarImage {
                                    Image(uiImage: avatarImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(MinimalDesign.Colors.secondaryBackground)
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(MinimalDesign.Colors.textSecondary)
                                        )
                                }

                                Circle()
                                    .fill(Color(red: 0.0, green: 0.55, blue: 0.75))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 35, y: 35)
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    avatarImage = image
                                }
                            }
                        }

                        Text("Add Profile Photo")
                            .font(.system(size: 14))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)
                    }
                    .padding(.top, 20)

                    // User ID field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("User ID")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)

                        HStack {
                            Text("@")
                                .foregroundColor(MinimalDesign.Colors.textSecondary)
                            TextField("username", text: $userId)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundColor(.white)
                                .onChange(of: userId) { _, newValue in
                                    validateUserId(newValue)
                                }
                        }
                        .padding()
                        .background(MinimalDesign.Colors.secondaryBackground)
                        .cornerRadius(12)

                        if !userIdValidationMessage.isEmpty {
                            Text(userIdValidationMessage)
                                .font(.system(size: 12))
                                .foregroundColor(isUserIdValid ? .green : .red)
                        }
                    }

                    // Display Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)

                        TextField("Your name", text: $displayName)
                            .padding()
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }

                    // Home Country field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Home Country")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)

                        Button(action: { showCountryPicker = true }) {
                            HStack {
                                if let country = selectedCountry {
                                    Text("\(country.emoji) \(country.name)")
                                        .foregroundColor(MinimalDesign.Colors.text)
                                } else {
                                    Text("Select your home country")
                                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(MinimalDesign.Colors.textSecondary)
                            }
                            .padding()
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(12)
                        }
                    }

                    // Bio field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)

                        TextField("Tell us about yourself", text: $bio, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }

                    // Complete button
                    Button(action: {
                        Task {
                            await createProfile()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: MinimalDesign.Colors.background))
                        } else {
                            Text("Complete Sign Up")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canComplete ? Color.white : Color.white.opacity(0.5))
                    .foregroundColor(MinimalDesign.Colors.background)
                    .cornerRadius(26)
                    .disabled(!canComplete || isLoading)
                    .padding(.top, 16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(selectedCountry: $selectedCountry, countrySearchQuery: $countrySearchQuery)
        }
    }

    private var canComplete: Bool {
        isUserIdValid && !displayName.isEmpty && selectedCountry != nil
    }

    private func validateUserId(_ id: String) {
        guard !id.isEmpty else {
            userIdValidationMessage = ""
            isUserIdValid = false
            return
        }

        // 形式チェック
        let validPattern = "^[a-zA-Z0-9_]{3,20}$"
        let regex = try? NSRegularExpression(pattern: validPattern)
        let range = NSRange(id.startIndex..., in: id)

        guard regex?.firstMatch(in: id, range: range) != nil else {
            userIdValidationMessage = "3-20 characters, letters, numbers, underscores only"
            isUserIdValid = false
            return
        }

        // 重複チェック
        isCheckingUserId = true
        Task {
            let exists = await checkUserIdExists(id)
            await MainActor.run {
                isCheckingUserId = false
                if exists {
                    userIdValidationMessage = "This user ID is already taken"
                    isUserIdValid = false
                } else {
                    userIdValidationMessage = "Available!"
                    isUserIdValid = true
                }
            }
        }
    }

    private func checkUserIdExists(_ id: String) async -> Bool {
        do {
            let response = try await supabase
                .from("profiles")
                .select("userid")
                .eq("userid", value: id.lowercased())
                .execute()

            let decoder = JSONDecoder()
            let profiles = try? decoder.decode([[String: String]].self, from: response.data)
            return !(profiles?.isEmpty ?? true)
        } catch {
            return false
        }
    }

    @MainActor
    private func createProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            var avatarUrl: String? = nil

            // アバター画像をアップロード
            if let image = avatarImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                let fileName = "\(session.user.id.uuidString)/avatar.jpg"
                try await supabase.storage
                    .from("avatars")
                    .upload(fileName, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))

                let supabaseClient = await supabase
                avatarUrl = try supabaseClient.storage
                    .from("avatars")
                    .getPublicURL(path: fileName)
                    .absoluteString
            }

            // プロフィールを作成
            let profileData: [String: AnyJSON] = [
                "id": .string(session.user.id.uuidString),
                "userid": .string(userId.lowercased()),
                "display_name": .string(displayName),
                "bio": .string(bio),
                "avatar_url": avatarUrl != nil ? .string(avatarUrl!) : .null,
                "home_country": selectedCountry != nil ? .string(selectedCountry!.countryCode) : .null
            ]

            try await supabase
                .from("profiles")
                .insert(profileData)
                .execute()

            SecureLogger.shared.info("Profile created successfully for new user")

            // AuthManagerのセッションを更新
            _ = try? await authManager.validateSession()

            // 完了
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
            SecureLogger.shared.error("Profile creation failed: \(error.localizedDescription)")
        }

        isLoading = false
    }
}

#Preview {
    SignUpFlowView()
        .environmentObject(AuthManager.shared)
}
