//======================================================================
// MARK: - LiquidGlassBottomTabBar.swift
// Purpose: Bottom tab bar with liquid glass effect containing profile and post buttons
// Path: GLOBE/Views/Components/Advanced/LiquidGlassBottomTabBar.swift
//======================================================================

import SwiftUI

struct LiquidGlassBottomTabBar: View {
    let onProfileTapped: () -> Void
    let onPostTapped: () -> Void

    private let buttonWidth: CGFloat = 40
    private let buttonHeight: CGFloat = 40

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 12) {
                Button(action: onProfileTapped) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.black.opacity(0.9))
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(.white.opacity(0.9))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                }

                Button(action: onPostTapped) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.9))
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(.white.opacity(0.9))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
        }
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
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: .trailing, vertical: .center))
        .padding(.trailing, 20)
    }
    .glassContainer()
}
