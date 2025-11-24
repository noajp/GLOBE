//======================================================================
// MARK: - LiquidGlassBottomTabBar.swift
// Purpose: Bottom tab bar with liquid glass effect containing profile, post, and location buttons
// Path: GLOBE/Views/Components/Advanced/LiquidGlassBottomTabBar.swift
//======================================================================

import SwiftUI

enum TabType {
    case post
    case location
    case profile
}

struct LiquidGlassBottomTabBar: View {
    let onProfileTapped: () -> Void
    let onPostTapped: () -> Void
    let onLocationTapped: () -> Void

    @State private var selectedTab: TabType = .post
    @Namespace private var namespace

    private let buttonWidth: CGFloat = 44
    private let buttonHeight: CGFloat = 44
    private let selectedColor = Color(red: 0.0, green: 0.55, blue: 0.75) // Same as Follow button

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 24) {
                // Post Button
                Button(action: {
                    selectedTab = .post
                    onPostTapped()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(selectedTab == .post ? selectedColor : Color.white)
                        .frame(width: buttonWidth, height: buttonHeight)
                }

                // Location Button
                Button(action: {
                    selectedTab = .location
                    onLocationTapped()
                }) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(selectedTab == .location ? selectedColor : Color.white)
                        .frame(width: buttonWidth, height: buttonHeight)
                }

                // Profile Button
                Button(action: {
                    selectedTab = .profile
                    onProfileTapped()
                }) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(selectedTab == .profile ? selectedColor : Color.white)
                        .frame(width: buttonWidth, height: buttonHeight)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .frame(height: 52)
        }
        .animation(.smooth(duration: 0.3), value: selectedTab)
        .coordinatedGlassEffect(id: "bottom-tab-bar")
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Background for preview
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.3),
                Color.purple.opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        LiquidGlassBottomTabBar(
            onProfileTapped: {
                print("Profile tapped")
            },
            onPostTapped: {
                print("Post tapped")
            },
            onLocationTapped: {
                print("Location tapped")
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: .center, vertical: .bottom))
        .padding(.bottom, 40)
    }
    .glassContainer()
}
