//======================================================================
// MARK: - UIImage+Extensions.swift
// Purpose: UIImage extensions for image processing
// Path: GLOBE/Extensions/UIImage+Extensions.swift
//======================================================================

import UIKit

extension UIImage {
    /// Fixes the image orientation by redrawing the image correctly
    func fixOrientation() -> UIImage {
        // If the image is already in the correct orientation, return it as is
        if imageOrientation == .up {
            return self
        }
        
        // Create a bitmap graphics context
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        // Draw the image with the correct orientation
        draw(in: CGRect(origin: .zero, size: size))
        
        // Get the corrected image from the context
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}