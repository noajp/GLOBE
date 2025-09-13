//======================================================================
// MARK: - ScrollableHeader.swift
// Purpose: Auto-hiding scrollable header component with scroll offset tracking and animated show/hide transitions
// Path: GLOBE/Core/Components/ScrollableHeader.swift
//======================================================================

import SwiftUI

// MARK: - Header Button Model
struct HeaderButton {
    let icon: String
    let action: () -> Void
}

// MARK: - Unified Header Component
struct UnifiedHeader: View {
    let title: String
    let showBackButton: Bool
    let rightButton: HeaderButton?
    let extraRightButton: HeaderButton?
    let onBack: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        title: String,
        showBackButton: Bool = false,
        rightButton: HeaderButton? = nil,
        extraRightButton: HeaderButton? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.rightButton = rightButton
        self.extraRightButton = extraRightButton
        self.onBack = onBack
    }
    
    var body: some View {
        HStack {
            // Back button or title
            if showBackButton {
                Button(action: {
                    if let onBack = onBack {
                        onBack()
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MinimalDesign.Colors.primary)
                }
            }
            
            Text(title)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(MinimalDesign.Colors.primary)
                .padding(.leading, showBackButton ? 8 : 0)
            
            Spacer()
            
            // Right buttons
            HStack(spacing: MinimalDesign.Spacing.md) {
                if let extraRightButton = extraRightButton {
                    Button(action: extraRightButton.action) {
                        Image(systemName: extraRightButton.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.primary)
                    }
                }
                
                if let rightButton = rightButton {
                    Button(action: rightButton.action) {
                        if rightButton.icon == "custom.three.lines" {
                            // Custom three lines (hamburger menu)
                            VStack(spacing: 4) {
                                ForEach(0..<3) { _ in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(MinimalDesign.Colors.primary)
                                        .frame(width: 20, height: 2)
                                }
                            }
                        } else {
                            Image(systemName: rightButton.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(MinimalDesign.Colors.primary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MinimalDesign.Spacing.md)
        .padding(.vertical, MinimalDesign.Spacing.sm)
        .frame(height: 44)
        .background(MinimalDesign.Colors.background)
    }
}

// MARK: - Scrollable Header View
struct ScrollableHeaderView<Content: View>: View {
    let title: String
    let showBackButton: Bool
    let rightButton: HeaderButton?
    let extraRightButton: HeaderButton?
    let onBack: (() -> Void)?
    let content: Content
    
    init(
        title: String,
        showBackButton: Bool = false,
        rightButton: HeaderButton? = nil,
        extraRightButton: HeaderButton? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.rightButton = rightButton
        self.extraRightButton = extraRightButton
        self.onBack = onBack
        self.content = content()
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header as part of content
                UnifiedHeader(
                    title: title,
                    showBackButton: showBackButton,
                    rightButton: rightButton,
                    extraRightButton: extraRightButton,
                    onBack: onBack
                )
                
                // Content
                content
            }
        }
        .background(MinimalDesign.Colors.background.ignoresSafeArea())
    }
}