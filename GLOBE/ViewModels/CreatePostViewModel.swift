//======================================================================
// MARK: - CreatePostViewModel.swift
// Purpose: Business logic for post creation
// Path: GLOBE/ViewModels/CreatePostViewModel.swift
//======================================================================

import SwiftUI
import Combine
import CoreLocation
import UIKit

//###########################################################################
// MARK: - Create Post ViewModel
// Function: CreatePostViewModel
// Overview: Manages post creation state and business logic
// Processing: Handle input → Validate → Process image → Create post → Handle errors
//###########################################################################

@MainActor
class CreatePostViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var postText: String = ""
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showingLocationPermissionAlert: Bool = false
    @Published var postLocation: CLLocationCoordinate2D?
    @Published var areaName: String = ""
    @Published var showPrivacyDropdown: Bool = false
    @Published var selectedPrivacyType: PostPrivacyType = .anonymous
    @Published var isSubmitting: Bool = false
    @Published var showingCamera: Bool = false
    @Published var selectedImageData: Data?
    @Published var capturedImage: UIImage?

    // MARK: - Dependencies
    private let authManager = AuthManager.shared
    private let postManager = PostManager.shared
    private let logger = SecureLogger.shared

    // MARK: - Constants
    private let maxTextLength: Int = 60

    //###########################################################################
    // MARK: - Computed Properties
    // Function: Validation and UI state calculations
    // Overview: Calculate button states, character counts, and validation results
    // Processing: Check conditions → Apply business rules → Return computed value
    //###########################################################################

    var isButtonDisabled: Bool {
        postText.isEmpty || weightedCharacterCount > Double(maxTextLength)
    }

    var isPostActionEnabled: Bool {
        !postText.isEmpty && weightedCharacterCount <= Double(maxTextLength) && !isSubmitting
    }

    var weightedCharacterCount: Double {
        postText.reduce(0.0) { count, character in
            let scalar = character.unicodeScalars.first
            guard let unicodeScalar = scalar else { return count + 1.0 }

            // 日本語（ひらがな、カタカナ、漢字）、中国語、韓国語
            let isAsianCharacter = (0x3040...0x309F).contains(unicodeScalar.value) || // ひらがな
                                   (0x30A0...0x30FF).contains(unicodeScalar.value) || // カタカナ
                                   (0x4E00...0x9FFF).contains(unicodeScalar.value) || // 漢字
                                   (0xAC00...0xD7AF).contains(unicodeScalar.value)    // ハングル

            return count + (isAsianCharacter ? 1.0 : 0.5)
        }
    }

    //###########################################################################
    // MARK: - Post Creation
    // Function: createPost
    // Overview: Create and submit a new post with text, image, and location
    // Processing: Validate input → Process image → Get location → Submit to PostManager → Handle result
    //###########################################################################

    func createPost(completion: @escaping (Bool) -> Void) {
        guard isPostActionEnabled else {
            logger.warning("Post creation attempted with invalid state")
            return
        }

        guard authManager.currentUser?.id != nil else {
            showError(message: "User not authenticated")
            completion(false)
            return
        }

        isSubmitting = true

        Task {
            do {
                // Prepare image data
                var finalImageData: Data?
                if let imageData = selectedImageData {
                    if let uiImage = UIImage(data: imageData) {
                        if let croppedImage = cropToSquare(image: uiImage) {
                            finalImageData = croppedImage.jpegData(compressionQuality: 0.8)
                        }
                    }
                }

                // Validate location
                guard let location = postLocation else {
                    await MainActor.run {
                        showError(message: "位置情報が取得できませんでした")
                        isSubmitting = false
                    }
                    completion(false)
                    return
                }

                // Create post
                let isAnonymous = (selectedPrivacyType == .anonymous)

                try await postManager.createPost(
                    content: postText,
                    imageData: finalImageData,
                    location: location,
                    locationName: areaName.isEmpty ? nil : areaName,
                    isAnonymous: isAnonymous
                )

                await MainActor.run {
                    logger.info("Post created successfully")
                    isSubmitting = false
                    resetForm()
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    logger.error("Failed to create post: \(error.localizedDescription)")
                    showError(message: "投稿の作成に失敗しました: \(error.localizedDescription)")
                    isSubmitting = false
                    completion(false)
                }
            }
        }
    }

    //###########################################################################
    // MARK: - Image Processing
    // Function: cropToSquare
    // Overview: Crop image to square aspect ratio for consistent post display
    // Processing: Calculate crop rect → Apply crop → Return processed image
    //###########################################################################

    func cropToSquare(image: UIImage) -> UIImage? {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        let sideLength = min(originalWidth, originalHeight)

        let xOffset = (originalWidth - sideLength) / 2
        let yOffset = (originalHeight - sideLength) / 2

        let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    //###########################################################################
    // MARK: - Helper Methods
    // Function: showError, resetForm
    // Overview: Utility functions for error handling and form reset
    // Processing: Set error state or clear all form fields
    //###########################################################################

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    private func resetForm() {
        postText = ""
        selectedImageData = nil
        capturedImage = nil
        areaName = ""
        selectedPrivacyType = .anonymous
    }
}
