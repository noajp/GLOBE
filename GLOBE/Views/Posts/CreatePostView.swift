//======================================================================
// MARK: - CreatePostView.swift
// Function: Post Creation View
// Overview: Full-screen post creation with text, image, location, and privacy options
// Processing: Capture input → Validate content → Get location → Upload image → Create post → Dismiss
//======================================================================
import SwiftUI
import UIKit
import CoreLocation
import MapKit

//###########################################################################
// MARK: - Post Privacy Types
// Function: PostPrivacyType
// Overview: Privacy options for post visibility
// Processing: publicPost (visible to all) | anonymous (hide author identity)
//###########################################################################

enum PostPrivacyType: Equatable, Sendable {
    case publicPost
    case anonymous
}

//###########################################################################
// MARK: - Create Post View
// Function: CreatePostView
// Overview: Main post creation interface with camera, text input, and privacy controls
// Processing: Initialize state → Render UI → Handle user input → Validate → Submit post
//###########################################################################

struct CreatePostView: View {
    @Binding var isPresented: Bool
    let mapManager: MapManager  // Remove @ObservedObject
    let initialLocation: CLLocationCoordinate2D? // Add parameter for exact post location
    @StateObject private var mapLocationService = MapLocationService()
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var postManager = PostManager.shared

    private let logger = SecureLogger.shared
    
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    
    @State private var postText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingLocationPermissionAlert = false
    @State private var postLocation: CLLocationCoordinate2D?
    // 位置決定は地図の中心に揃える（Vの先端=地図中心）。余計なオフセットは使わない。
    @State private var areaName: String = ""
    @State private var showPrivacyDropdown = false
    @State private var selectedPrivacyType: PostPrivacyType = .anonymous
    @State private var isSubmitting = false
    @State private var showingCamera = false
    @State private var selectedImageData: Data?
    @State private var capturedImage: UIImage?
    // App settings
    @StateObject private var appSettings = AppSettings.shared

    //###########################################################################
    // MARK: - Computed Properties
    // Function: Validation and UI state calculations
    // Overview: Calculate button states, character counts, and validation results
    // Processing: Check conditions → Apply business rules → Return computed value
    //###########################################################################

    // Computed properties to reduce complexity
    private var isButtonDisabled: Bool {
        postText.isEmpty || weightedCharacterCount > Double(maxTextLength)
    }

    // 投稿ボタンがアクティブになる条件を集約
    private var isPostActionEnabled: Bool {
        !postText.isEmpty && weightedCharacterCount <= Double(maxTextLength) && !isSubmitting
    }

    // 重み付き文字数カウント（日中韓=1.0、アルファベット=0.5）
    private var weightedCharacterCount: Double {
        postText.reduce(0.0) { count, character in
            let scalar = character.unicodeScalars.first
            guard let unicodeScalar = scalar else { return count + 1.0 }

            // 日本語（ひらがな、カタカナ、漢字）、中国語、韓国語
            let isAsianCharacter = (0x3040...0x309F).contains(unicodeScalar.value) || // ひらがな
                                   (0x30A0...0x30FF).contains(unicodeScalar.value) || // カタカナ
                                   (0x4E00...0x9FFF).contains(unicodeScalar.value) || // 漢字（CJK統合漢字）
                                   (0xAC00...0xD7AF).contains(unicodeScalar.value)    // ハングル

            return count + (isAsianCharacter ? 1.0 : 0.5)
        }
    }

    private var maxTextLength: Int {
        // 画像の有無に関わらず60文字まで
        return 60
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    // Popup content with speech bubble design
                    GlassEffectContainer {
                        VStack(spacing: 0) {
                            // Main card with rounded corners
                            VStack(spacing: 0) {
                                postCreationView
                            }
                            .frame(width: 280, height: selectedImageData != nil ? 350 : 200)
                            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )

                            // Simple triangle tail below card
                            Triangle()
                                .fill(Color.clear)
                                .frame(width: 50, height: 25)
                                .glassEffect(.clear, in: Triangle())
                                .rotationEffect(.degrees(180))
                                .offset(y: -1) // Slight overlap to hide seam
                        }
                    }
                    .shadow(radius: 10)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 1.8) // 画面の中央やや下に固定
                    .ignoresSafeArea(.keyboard) // キーボードが表示されてもカードを動かさない
                }
            }

            // Privacy selection popup from bottom - outside GeometryReader
            if showPrivacyDropdown {
                Color.clear // Transparent background
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showPrivacyDropdown = false
                        }
                    }

                VStack(spacing: 0) {
                    Spacer()
                    privacyPopupContent
                        .ignoresSafeArea(edges: .bottom)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPrivacyDropdown)
        .onDisappear {
            // Clean up when popup closes
            mapManager.draftPostCoordinate = nil
            postLocation = nil
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .alert("Location access required", isPresented: $showingLocationPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow location access in Settings to move to your current location.")
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPreviewView(capturedImage: $capturedImage)
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                // 画像を正方形にクロップして角丸を適用
                if let croppedImage = cropToSquare(image: image) {
                    selectedImageData = croppedImage.jpegData(compressionQuality: 0.8)
                }
                // 画像処理後にcapturedImageをリセット
                capturedImage = nil
                showingCamera = false
            }
        }
        .onAppear {
            // Use initial location if provided
            if let initial = initialLocation {
                postLocation = initial
            }
        }
    }
    
    // MARK: - Post Creation View
    private var postCreationView: some View {
        VStack(spacing: 0) {
            headerView
            textInputView
            Spacer()
            bottomSectionView
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
    
    // MARK: - Header View
    private var headerView: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 280, height: 32)
            .overlay(alignment: .topLeading) {
                headerCloseButton
                    .padding(.leading, 8)
                    .padding(.top, 6)
            }
            .overlay(alignment: .topTrailing) {
                postActionButton
                    .padding(.trailing, 4)
                    .padding(.top, 6)
            }
    }

    private var headerCloseButton: some View {
        Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            isPresented = false
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(glassCircleBackground)
                .clipShape(Circle())
                .overlay(circleStrokeOverlay)
        }
        .shadow(color: Color.black.opacity(0.22), radius: 6, x: 0, y: 4)
        .accessibilityLabel(Text("投稿を閉じる"))
    }

    private var postActionButton: some View {
        Button(action: {
            logger.info("POST button pressed")
            logger.info("Post validation - hasImage=\(selectedImageData != nil), textLength=\(postText.count)")

            // 画像がある場合はテキストなしでもOK
            let hasValidContent = selectedImageData != nil || (!postText.isEmpty && weightedCharacterCount <= Double(maxTextLength))
            guard hasValidContent else {
                logger.warning("POST validation failed - no valid content")
                return
            }
            createPost()
        }) {
            Text("POST")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .background(simpleWhiteBackground)
        .clipShape(Capsule())
    }

    private var simpleWhiteBackground: some View {
        Capsule()
            .fill(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
    }

    // MARK: - Circular Progress Counter
    private var circularProgressCounter: some View {
        let progress = min(weightedCharacterCount / Double(maxTextLength), 1.0)
        let isOverLimit = weightedCharacterCount > Double(maxTextLength)
        let isNearLimit = weightedCharacterCount >= Double(maxTextLength) * 0.9

        return ZStack {
            // 背景の円
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2.5)

            // プログレスリング
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isOverLimit ? Color.red :
                    isNearLimit ? Color.orange :
                    Color.white.opacity(0.9),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: weightedCharacterCount)
        }
        .frame(width: 26, height: 26)
    }
    
    
    // MARK: - Text Input View
    private var textInputView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // 画像プレビュー
            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                VStack(spacing: 4) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 220, height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        // 削除ボタン
                        Button(action: {
                            selectedImageData = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(Circle().fill(.black.opacity(0.6)))
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }

                    // 画像がある時のテキスト入力
                    ZStack(alignment: .topLeading) {
                        if postText.isEmpty {
                            Text("text")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 8)
                        }

                        TextEditor(text: Binding(
                            get: { postText },
                            set: { newValue in
                                // 改行数を2行までに制限
                                let lineCount = newValue.components(separatedBy: "\n").count
                                if lineCount > 2 {
                                    return // 2行を超える改行は無視
                                }
                                // 重み付き文字数制限を適用
                                let newWeightedCount = newValue.reduce(0.0) { count, character in
                                    let scalar = character.unicodeScalars.first
                                    guard let unicodeScalar = scalar else { return count + 1.0 }
                                    let isAsianCharacter = (0x3040...0x309F).contains(unicodeScalar.value) ||
                                                           (0x30A0...0x30FF).contains(unicodeScalar.value) ||
                                                           (0x4E00...0x9FFF).contains(unicodeScalar.value) ||
                                                           (0xAC00...0xD7AF).contains(unicodeScalar.value)
                                    return count + (isAsianCharacter ? 1.0 : 0.5)
                                }
                                if newWeightedCount <= Double(maxTextLength) {
                                    postText = newValue
                                }
                            }
                        ))
                        .font(.system(size: 14))
                        .foregroundColor(weightedCharacterCount > Double(maxTextLength) ? .red : .white)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                    .frame(height: 50)
                }
            } else {
                // 画像がない時のみテキスト入力を表示
                ZStack(alignment: .topLeading) {
                    if postText.isEmpty {
                        Text("text")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                    }

                    TextEditor(text: Binding(
                        get: { postText },
                        set: { newValue in
                            // 改行数を5行までに制限
                            let lineCount = newValue.components(separatedBy: "\n").count
                            if lineCount > 5 {
                                return // 5行を超える改行は無視
                            }
                            // 重み付き文字数制限を適用
                            let newWeightedCount = newValue.reduce(0.0) { count, character in
                                let scalar = character.unicodeScalars.first
                                guard let unicodeScalar = scalar else { return count + 1.0 }
                                let isAsianCharacter = (0x3040...0x309F).contains(unicodeScalar.value) ||
                                                       (0x30A0...0x30FF).contains(unicodeScalar.value) ||
                                                       (0x4E00...0x9FFF).contains(unicodeScalar.value) ||
                                                       (0xAC00...0xD7AF).contains(unicodeScalar.value)
                                return count + (isAsianCharacter ? 1.0 : 0.5)
                            }
                            if newWeightedCount <= Double(maxTextLength) {
                                postText = newValue
                            }
                        }
                    ))
                    .font(.system(size: 16))
                    .foregroundColor(weightedCharacterCount > Double(maxTextLength) ? .red : .white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
                .frame(height: 120) // 固定高さでスクロール可能に
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
    
    // MARK: - Bottom Section View
    private var bottomSectionView: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 280, height: 36)
            .overlay(alignment: .bottom) {
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        chevronActionButton
                        locationActionButton
                    }

                    Spacer()

                    privacyDescriptionLabel

                    Spacer()

                    HStack(spacing: 8) {
                        circularProgressCounter
                        cameraActionButton
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
    }

    private var chevronActionButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showPrivacyDropdown.toggle()
            }
        }) {
            Image(systemName: showPrivacyDropdown ? "chevron.down" : "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(glassCircleBackground)
                .clipShape(Circle())
                .overlay(circleStrokeOverlay)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 5, x: 0, y: 3)
    }

    private var locationActionButton: some View {
        Button(action: handleLocationButton) {
            Image(systemName: postLocation != nil ? "location.fill" : "location")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(glassCircleBackground)
                .clipShape(Circle())
                .overlay(circleStrokeOverlay)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 5, x: 0, y: 3)
    }

    private var cameraActionButton: some View {
        Button(action: handleCameraButton) {
            Image(systemName: "camera.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(glassCircleBackground)
                .clipShape(Circle())
                .overlay(circleStrokeOverlay)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 5, x: 0, y: 3)
    }

    private var privacyDescriptionLabel: some View {
        Text(
            selectedPrivacyType == .publicPost ? "Publicly" : "Anonymously"
        )
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.white.opacity(0.85))
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.6)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.15), lineWidth: 0.6)
                        .blendMode(.overlay)
                )
        )
        .clipShape(Capsule())
    }

    //###########################################################################
    // MARK: - Action Handlers
    // Function: Button action handlers
    // Overview: Handle user interactions for location and camera buttons
    // Processing: Request permissions → Update state → Trigger appropriate action
    //###########################################################################

    private func handleLocationButton() {
        // Request location permission if needed
        mapLocationService.startLocationServices()

        // Move to current location if available
        if let currentLocation = mapLocationService.location?.coordinate {
            mapManager.focusOnLocation(currentLocation, zoomLevel: 0.0008)
            postLocation = currentLocation
        }
    }

    private func handleCameraButton() {
        logger.info("Camera button pressed")
        showingCamera = true
    }

    private var glassCircleBackground: some View {
        Circle()
            .fill(.white.opacity(0.95))
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
    }

    private var circleBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color.white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var circleStrokeOverlay: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color.black.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.9
            )
    }

    
    // MARK: - Speech Bubble Tail
    private var speechBubbleTail: some View {
        Triangle()
            .fill(Color.clear)
            .frame(width: 20, height: 15)
            .glassEffect(.clear, in: Triangle())
            .rotationEffect(.degrees(180))
            .offset(y: 15)
    }

    // MARK: - Privacy Popup Content
    private var privacyPopupContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Post Privacy")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showPrivacyDropdown = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Privacy options
            VStack(alignment: .leading, spacing: 1) {
                privacyPopupOption(.anonymous, "person.fill.questionmark", .black, "Anonymously", "Your identity will be hidden")
                privacyPopupOption(.publicPost, "globe", .black, "Publicly", "Everyone can see this post")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            // Spacer to push content to safe area and fill to bottom
            Spacer()
                .frame(height: 50)
        }
        .background(.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
        .overlay(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20).stroke(.black.opacity(0.1), lineWidth: 1))
        .shadow(radius: 10)
        .edgesIgnoringSafeArea(.bottom)
    }

    private func privacyPopupOption(_ type: PostPrivacyType, _ icon: String, _ color: Color, _ title: String, _ subtitle: String) -> some View {
        Button(action: {
            selectedPrivacyType = type
            withAnimation(.easeInOut(duration: 0.3)) {
                showPrivacyDropdown = false
            }
        }) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 24, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    HStack {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.black.opacity(0.6))
                        Spacer()
                    }
                }

                if selectedPrivacyType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(selectedPrivacyType == type ? .black.opacity(0.05) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }

    //###########################################################################
    // MARK: - Post Creation
    // Function: createPost
    // Overview: Create new post with text, image, and location data
    // Processing: Capture form values → Close UI → Call PostManager async → Handle errors
    //###########################################################################

    private func createPost() {
        logger.info("Starting post creation")

        // Capture values before closing UI
        let text = postText
        let privacy = selectedPrivacyType
        // 常に画面中央（吹き出しの先端が指す位置）の座標を使用
        let loc = mapManager.region.center
        let imageData = selectedImageData

        logger.info("Post metadata - hasImage=\(imageData != nil), privacy=\(privacy)")

        // Close UI immediately
        isPresented = false

        // Create post after UI is closed
        Task {
            do {
                try await postManager.createPost(
                    content: text,
                    imageData: imageData,
                    location: loc,
                    locationName: nil,
                    isAnonymous: privacy == .anonymous
                )
                logger.info("Post created successfully")
            } catch {
                logger.error("Failed to create post: \(error.localizedDescription)")
            }
        }
    }


    //###########################################################################
    // MARK: - Image Processing
    // Function: cropToSquare
    // Overview: Crop image to square aspect ratio from center
    // Processing: Calculate side length → Determine crop rect → Crop CGImage → Return UIImage
    //###########################################################################

    private func cropToSquare(image: UIImage) -> UIImage? {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        let sideLength = min(originalWidth, originalHeight)

        let xOffset = (originalWidth - sideLength) / 2.0
        let yOffset = (originalHeight - sideLength) / 2.0

        let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}


// MARK: - Speech Bubble Shape
// Replaced with separate RoundedRectangle and Triangle components for stability
