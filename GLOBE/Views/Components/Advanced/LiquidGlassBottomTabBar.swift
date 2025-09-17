//======================================================================
// MARK: - LiquidGlassBottomTabBar.swift
// Purpose: Bottom tab bar with liquid glass effect containing profile and post buttons
// Path: GLOBE/Views/Components/Advanced/LiquidGlassBottomTabBar.swift
//======================================================================

import SwiftUI

struct LiquidGlassBottomTabBar: View {
    let onProfileTapped: () -> Void
    let onPostTapped: () -> Void

    private let profileButtonSize: CGFloat = 40
    private let postButtonSize: CGFloat = 40

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 12) {
                GlassCircleButton(
                    id: "profile-button",
                    size: profileButtonSize,
                    action: onProfileTapped
                ) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .white.opacity(0.25), radius: 1, x: 0, y: 0)
                }

                GlassCircleButton(
                    id: "post-button-main",
                    size: postButtonSize,
                    action: onPostTapped
                ) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .white.opacity(0.25), radius: 1, x: 0, y: 0)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .frame(width: 72)
            .coordinatedGlassEffect(id: "floating-action-tab", cornerRadius: 22)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .centerTrailing)
        .padding(.trailing, 20)
    }
    .glassContainer()
}
