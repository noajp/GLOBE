//======================================================================
// MARK: - PostCreationViewModel.swift
// Purpose: ViewModel for post creation following MVVM pattern
// Path: GLOBE/ViewModels/PostCreationViewModel.swift
//======================================================================

import Foundation
import SwiftUI
import Combine
import CoreLocation
import UIKit

@MainActor
class PostCreationViewModel: BaseViewModel {
    // MARK: - Dependencies
    private let postRepository: PostRepositoryProtocol
    private let authService: AuthServiceProtocol

    // MARK: - Published Properties
    @Published var content = ""
    @Published var selectedImage: UIImage?
    @Published var imageData: Data?
    @Published var isPrivate = false
    @Published var isAnonymous = false

    // MARK: - UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isValidContent = false
    @Published var remainingCharacters = 60
    @Published var showingImagePicker = false
    @Published var showingCamera = false

    // MARK: - Location Properties
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationName: String?
    @Published var isLocationSet = false

    // MARK: - Validation Properties
    private let maxContentLength = 60
    private let maxContentLengthWithImage = 30

    var currentMaxLength: Int {
        selectedImage != nil ? maxContentLengthWithImage : maxContentLength
    }

    var canPost: Bool {
        let hasContent = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = selectedImage != nil
        let isWithinLimit = content.count <= currentMaxLength
        let hasLocation = isLocationSet

        return (hasContent || hasImage) && isWithinLimit && hasLocation && !isLoading
    }

    // MARK: - Initialization
    init(
        postRepository: PostRepositoryProtocol = ServiceContainer.serviceLocator.postRepository(),
        authService: AuthServiceProtocol = ServiceContainer.serviceLocator.authService()
    ) {
        self.postRepository = postRepository
        self.authService = authService

        super.init()

        setupContentObserver()
    }

    // MARK: - Setup Methods
    private func setupContentObserver() {
        $content
            .map { [weak self] text in
                guard let self = self else { return (false, 0) }
                let maxLength = self.currentMaxLength
                let remaining = maxLength - text.count
                let isValid = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= maxLength
                return (isValid, remaining)
            }
            .sink { [weak self] (isValid, remaining) in
                self?.isValidContent = isValid
                self?.remainingCharacters = remaining
            }
            .store(in: &cancellables)

        $selectedImage
            .sink { [weak self] image in
                if let image = image {
                    self?.imageData = image.jpegData(compressionQuality: 0.8)
                } else {
                    self?.imageData = nil
                }
                // Recalculate content validation when image changes
                self?.updateContentValidation()
            }
            .store(in: &cancellables)
    }

    // MARK: - Content Management
    func updateContent(_ newContent: String) {
        let maxLength = currentMaxLength
        if newContent.count <= maxLength {
            content = newContent
        } else {
            content = String(newContent.prefix(maxLength))
        }
    }

    func clearContent() {
        content = ""
        selectedImage = nil
        imageData = nil
        errorMessage = nil
    }

    private func updateContentValidation() {
        let maxLength = currentMaxLength
        remainingCharacters = maxLength - content.count
        isValidContent = (!content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil) && content.count <= maxLength

        // Trim content if it exceeds new limit
        if content.count > maxLength {
            content = String(content.prefix(maxLength))
        }
    }

    // MARK: - Image Management
    func selectImageFromLibrary() {
        showingImagePicker = true
    }

    func selectImageFromCamera() {
        showingCamera = true
    }

    func removeImage() {
        selectedImage = nil
        imageData = nil
    }

    func setSelectedImage(_ image: UIImage?) {
        selectedImage = image
        showingImagePicker = false
        showingCamera = false
    }

    // MARK: - Location Management
    func setLocation(_ location: CLLocationCoordinate2D, name: String?) {
        userLocation = location
        locationName = name
        isLocationSet = true
    }

    func clearLocation() {
        userLocation = nil
        locationName = nil
        isLocationSet = false
    }

    // MARK: - Post Creation
    func createPost() async -> Bool {
        guard canPost,
              let location = userLocation,
              let userId = authService.currentUser?.id else {
            await MainActor.run {
                self.errorMessage = "投稿に必要な情報が不足しています"
            }
            return false
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            // Validate content using InputValidator
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

            let validatedContent: String
            if trimmedContent.isEmpty && selectedImage != nil {
                // Photo-only post
                validatedContent = ""
            } else {
                let contentValidation = InputValidator.validatePostContent(trimmedContent)
                guard contentValidation.isValid, let validated = contentValidation.value else {
                    await MainActor.run {
                        self.errorMessage = contentValidation.errorMessage ?? "投稿内容が無効です"
                        self.isLoading = false
                    }
                    return false
                }
                validatedContent = validated
            }

            // Create post object
            let post = Post(
                id: UUID(),
                userId: userId,
                content: validatedContent,
                imageURL: nil, // Will be set by repository if image is uploaded
                latitude: location.latitude,
                longitude: location.longitude,
                locationName: locationName,
                isAnonymous: isAnonymous,
                createdAt: Date(),
                likeCount: 0,
                commentCount: 0,
                isLikedByCurrentUser: false,
                authorProfile: nil // Will be populated by repository
            )

            // Use PostRepository to create the post
            let createdPost = try await postRepository.createPost(post)

            await MainActor.run {
                self.isLoading = false
            }

            SecureLogger.shared.info("Post created successfully", details: [
                "postId": createdPost.id.uuidString,
                "hasImage": self.selectedImage != nil ? "true" : "false"
            ])

            return true

        } catch {
            await MainActor.run {
                self.errorMessage = AppError.from(error).localizedDescription
                self.isLoading = false
            }

            SecureLogger.shared.error("Failed to create post", error: error)
            return false
        }
    }

    // MARK: - Validation Helpers
    func validatePostContent() -> ValidationResult {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Allow empty content if there's an image
        if trimmedContent.isEmpty && selectedImage != nil {
            return ValidationResult(isValid: true, value: "", errorMessage: nil)
        }

        // Otherwise, validate normally
        return InputValidator.validatePostContent(trimmedContent)
    }

    func getContentLengthInfo() -> String {
        let current = content.count
        let max = currentMaxLength

        if selectedImage != nil {
            return "\(current)/\(max) (写真付き投稿)"
        } else {
            return "\(current)/\(max)"
        }
    }

    // MARK: - Reset Method
    func reset() {
        content = ""
        selectedImage = nil
        imageData = nil
        isPrivate = false
        isAnonymous = false
        userLocation = nil
        locationName = nil
        isLocationSet = false
        errorMessage = nil
        isLoading = false
        showingImagePicker = false
        showingCamera = false
    }

    // MARK: - Error Management
    func clearError() {
        errorMessage = nil
    }
}