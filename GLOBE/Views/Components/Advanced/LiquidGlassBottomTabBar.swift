//======================================================================
// MARK: - LiquidGlassBottomTabBar.swift
// Purpose: Bottom tab bar with liquid glass effect containing profile and post buttons
// Path: GLOBE/Views/Components/Advanced/LiquidGlassBottomTabBar.swift
//======================================================================

import SwiftUI

struct LiquidGlassBottomTabBar: View {
    let onProfileTapped: () -> Void
    let onPostTapped: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 0) {
                // Profile Section
                HStack {
                    Spacer()

                    GlassCircleButton(
                        id: "profile-button",
                        size: 50,
                        action: onProfileTapped
                    ) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                            .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                // Center Post Button
                GlassCircleButton(
                    id: "post-button-main",
                    size: 60,
                    action: onPostTapped
                ) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.4), radius: 2, x: 0, y: 0)
                }

                // Right spacer (for future buttons or balance)
                HStack {
                    Spacer()

                    // Placeholder for future button
                    Color.clear
                        .frame(width: 50, height: 50)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                // Glass tab bar background
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.03))
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.ultraThinMaterial)
                            .opacity(0.15)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.12),
                                        Color.white.opacity(0.04),
                                        Color.clear
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.4),
                                        .white.opacity(0.2),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 34) // Safe area bottom
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
    }
    .glassContainer()
}