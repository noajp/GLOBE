//======================================================================
// MARK: - TabSelection.swift
// Purpose: Custom tab selection component for profile screens
// Path: GLOBE/Core/Components/TabSelection.swift
//======================================================================
import SwiftUI

// MARK: - Tab Selection Component
struct TabSelectionView: View {
    @Binding var selectedTab: Int
    
    private let tabs = ["Posts", "Followers", "Following", "Stories", "Notifications"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    TabButton(
                        title: tabs[index],
                        isSelected: selectedTab == index,
                        action: { selectedTab = index }
                    )
                }
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
        }
        .background(MinimalDesign.Colors.background)
    }
}

// MARK: - Tab Button Component  
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? MinimalDesign.Colors.primary : MinimalDesign.Colors.tertiary)
                
                // Selection indicator
                Rectangle()
                    .fill(isSelected ? MinimalDesign.Colors.accentRed : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}