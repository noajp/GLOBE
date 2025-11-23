//======================================================================
// MARK: - PostPinShared.swift
// Function: Shared Post Pin Components
// Overview: Common UI components and utilities shared between PostPin and ScalablePostPin
// Processing: Provide reusable shapes, utilities, and view components for post pin rendering
//======================================================================

import SwiftUI
import UIKit

//###########################################################################
// MARK: - Speech Bubble Shape
// Function: PostCardBubbleShape
// Overview: Custom Shape for speech bubble with tail pointing to location
// Processing: Draw rounded rectangle → Add triangle tail → Return complete path
//###########################################################################

struct PostCardBubbleShape: Shape {
    let cornerRadius: CGFloat
    let tailWidth: CGFloat
    let tailHeight: CGFloat

    init(cornerRadius: CGFloat = 12, tailWidth: CGFloat = 20, tailHeight: CGFloat = 10) {
        self.cornerRadius = cornerRadius
        self.tailWidth = tailWidth
        self.tailHeight = tailHeight
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Safety checks to prevent crashes
        guard rect.width > 0, rect.height > tailHeight else {
            return path
        }

        // Main rounded rectangle (card body)
        let mainRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: max(0, rect.height - tailHeight)
        )

        // Add rounded rectangle for main body
        if mainRect.width > 0 && mainRect.height > 0 {
            path.addRoundedRect(in: mainRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        }

        // Add simple triangle tail
        let tailCenterX = rect.midX
        let tailBaseY = mainRect.maxY
        let tailTipY = rect.maxY

        // Safety check for triangle
        if tailTipY > tailBaseY && tailWidth > 0 {
            // Triangle points
            let leftPoint = CGPoint(x: tailCenterX - tailWidth / 2, y: tailBaseY)
            let rightPoint = CGPoint(x: tailCenterX + tailWidth / 2, y: tailBaseY)
            let tipPoint = CGPoint(x: tailCenterX, y: tailTipY)

            // Draw triangle
            path.move(to: leftPoint)
            path.addLine(to: tipPoint)
            path.addLine(to: rightPoint)
            path.addLine(to: leftPoint)
        }

        return path
    }
}

//###########################################################################
// MARK: - Post Pin Utilities
// Function: PostPinUtilities
// Overview: Shared utility functions for post pin calculations
// Processing: Provide static helper methods for text height, image checks, etc.
//###########################################################################

enum PostPinUtilities {

    //###########################################################################
    // MARK: - Text Height Calculation
    // Function: measuredTextHeight
    // Overview: Calculate required height for text rendering with given constraints
    // Processing: Create NSString → Get bounding rect → Return height
    //###########################################################################

    static func measuredTextHeight(for text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let nsString = text as NSString
        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let rect = nsString.boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(rect.height)
    }

    //###########################################################################
    // MARK: - Image Content Checks
    // Function: hasImageContent, isPhotoOnly
    // Overview: Check post media content status
    // Processing: Check imageData/imageUrl → Determine content type
    //###########################################################################

    /// Check if post has image content (either Data or URL)
    static func hasImageContent(_ post: Post) -> Bool {
        (post.imageData != nil) || (post.imageUrl != nil)
    }

    /// Check if post is photo-only (no text)
    static func isPhotoOnly(_ post: Post) -> Bool {
        hasImageContent(post) && post.text.isEmpty
    }
}

//###########################################################################
// MARK: - Shared View Modifiers
// Function: postPinModals
// Overview: Standard modal presentations for post pins (profile, image viewer, delete)
// Processing: Add fullScreenCover for profile → Add fullScreenCover for image → Add delete alert
//###########################################################################

extension View {
    /// Add standard post pin modals (profile viewer, image viewer, delete confirmation)
    func postPinModals(
        showingUserProfile: Binding<Bool>,
        showingImageViewer: Binding<Bool>,
        showingDeleteAlert: Binding<Bool>,
        post: Post,
        onDelete: @escaping () async -> Void
    ) -> some View {
        self
            .fullScreenCover(isPresented: showingUserProfile) {
                UserProfileView(
                    userName: post.authorName,
                    userId: post.userId,
                    isPresented: showingUserProfile
                )
            }
            .fullScreenCover(isPresented: showingImageViewer) {
                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                    PhotoViewerView(image: uiImage, onClose: {
                        showingImageViewer.wrappedValue = false
                    })
                } else if let urlString = post.imageUrl, let url = URL(string: urlString) {
                    PhotoViewerView(imageUrl: url, onClose: {
                        showingImageViewer.wrappedValue = false
                    })
                }
            }
            .alert("Delete Post", isPresented: showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await onDelete()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this post? This action cannot be undone.")
            }
    }
}
