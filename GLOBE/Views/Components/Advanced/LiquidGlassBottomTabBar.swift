//======================================================================
// MARK: - LiquidGlassBottomTabBar.swift
// Purpose: Bottom tab bar with liquid glass effect containing profile, post, and location buttons
// Path: GLOBE/Views/Components/Advanced/LiquidGlassBottomTabBar.swift
//======================================================================

import SwiftUI

struct LiquidGlassBottomTabBar: View {
    let onProfileTapped: () -> Void
    let onPostTapped: () -> Void
    let onLocationTapped: () -> Void

    private let buttonWidth: CGFloat = 44
    private let buttonHeight: CGFloat = 44

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 20) {
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

                Button(action: onLocationTapped) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.9))
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(.white.opacity(0.9))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(height: 60)
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
