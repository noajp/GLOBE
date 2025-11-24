//======================================================================
// MARK: - AppleSignUpProfileSetupView.swift
// Purpose: Profile setup after Apple Sign In (User ID, Display Name, City, Bio, Avatar)
// Path: GLOBE/Views/Auth/AppleSignUpProfileSetupView.swift
//======================================================================
import SwiftUI
import Supabase
import PhotosUI

struct AppleSignUpProfileSetupView: View {
    let session: Session

    @Environment(\.dismiss) private var dismiss
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

                            Text("Tap to add photo")
                                .font(.system(size: 13))
                                .foregroundColor(MinimalDesign.Colors.textSecondary)
                        }

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

                        // Country picker button
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Home Country")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MinimalDesign.Colors.textSecondary)

                            Button(action: {
                                showCountryPicker = true
                            }) {
                                HStack {
                                    if let country = selectedCountry {
                                        HStack(spacing: 12) {
                                            Text(country.emoji)
                                                .font(.system(size: 32))

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(country.name)
                                                    .font(.system(size: 17))
                                                    .foregroundColor(MinimalDesign.Colors.text)
                                                Text(country.landmarkName)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(MinimalDesign.Colors.textSecondary)
                                            }
                                        }
                                    } else {
                                        Text("Select your country")
                                            .font(.system(size: 17))
                                            .foregroundColor(MinimalDesign.Colors.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                                }
                                .padding(16)
                                .background(MinimalDesign.Colors.secondaryBackground)
                                .cornerRadius(12)
                            }
                        }

                        // Bio input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MinimalDesign.Colors.textSecondary)

                            TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                                .font(.system(size: 17))
                                .foregroundColor(MinimalDesign.Colors.text)
                                .lineLimit(3...6)
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
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(selectedCountry: $selectedCountry, countrySearchQuery: $countrySearchQuery)
        }
        .onAppear {
            // Appleから取得した名前を初期値として設定（もしあれば）
            if let fullName = session.user.userMetadata["full_name"] as? String {
                displayName = fullName
            }

            // デバイスのロケールから国を自動選択
            let countryCode = Locale.current.region?.identifier ?? "JP"
            selectedCountry = CountryData.country(for: countryCode)
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
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            // アバター画像をSupabase Storageにアップロード
            var avatarUrl: String? = nil
            if let avatarImage = avatarImage,
               let imageData = avatarImage.jpegData(compressionQuality: 0.8) {
                let fileName = "\(session.user.id.uuidString).jpg"
                let filePath = try await supabase.storage
                    .from("avatars")
                    .upload(path: fileName, file: imageData, options: .init(contentType: "image/jpeg"))

                // Public URLを生成
                avatarUrl = try supabase.storage
                    .from("avatars")
                    .getPublicURL(path: fileName)
                    .absoluteString

                SecureLogger.shared.info("Avatar uploaded successfully: \(fileName)")
            }

            // profilesテーブルに保存
            struct ProfileInsert: Encodable {
                let id: String
                let userid: String
                let display_name: String
                let email: String
                let avatar_url: String?
                let bio: String?
                let home_country: String?
                let post_count: Int
                let follower_count: Int
                let following_count: Int
            }

            let profileData = ProfileInsert(
                id: session.user.id.uuidString,
                userid: cleanedUserId,
                display_name: trimmedDisplayName,
                email: session.user.email ?? "",
                avatar_url: avatarUrl,
                bio: trimmedBio.isEmpty ? nil : trimmedBio,
                home_country: selectedCountry?.countryCode,
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

// MARK: - Country Picker Sheet

struct CountryPickerSheet: View {
    @Binding var selectedCountry: Country?
    @Binding var countrySearchQuery: String
    @Environment(\.dismiss) private var dismiss

    var filteredCountries: [Country] {
        CountryData.searchCountries(query: countrySearchQuery)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(MinimalDesign.Colors.textSecondary)

                    TextField("Search country", text: $countrySearchQuery)
                        .font(.system(size: 17))
                        .foregroundColor(MinimalDesign.Colors.text)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(MinimalDesign.Colors.secondaryBackground)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Country list
                List(filteredCountries) { country in
                    Button(action: {
                        selectedCountry = country
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Text(country.emoji)
                                .font(.system(size: 32))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(country.name)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(MinimalDesign.Colors.text)

                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.0, green: 0.55, blue: 0.75))

                                    Text(country.landmarkName)
                                        .font(.system(size: 14))
                                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(MinimalDesign.Colors.background)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(MinimalDesign.Colors.background)
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.55, blue: 0.75))
                }
            }
        }
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
