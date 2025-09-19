//======================================================================
// MARK: - LiquidGlassBottomTabBar.swift
// Purpose: Bottom tab bar with liquid glass effect containing profile and post buttons
// Path: GLOBE/Views/Components/Advanced/LiquidGlassBottomTabBar.swift
//======================================================================

import SwiftUI

struct LiquidGlassBottomTabBar: View {
    let onProfileTapped: () -> Void
    let onPostTapped: () -> Void

    private let buttonWidth: CGFloat = 50
    private let buttonHeight: CGFloat = 50

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 15) {
                GlassRectangleButton(
                    id: "profile-button",
                    width: buttonWidth,
                    height: buttonHeight,
                    action: onProfileTapped
                ) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .white.opacity(0.25), radius: 1, x: 0, y: 0)
                }

                GlassRectangleButton(
                    id: "post-button-main",
                    width: buttonWidth,
                    height: buttonHeight,
                    action: onPostTapped
                ) {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .white.opacity(0.25), radius: 1, x: 0, y: 0)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(width: 80)
            .coordinatedGlassEffect(id: "floating-action-tab", cornerRadius: 16)
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
        }
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
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: .trailing, vertical: .center))
        .padding(.trailing, 20)
    }
    .glassContainer()
}
