//======================================================================
// MARK: - LiquidGlassTabBar.swift
// Purpose: Liquid Glass style tab bar for bottom safe area
// Path: GLOBE/Views/Components/LiquidGlassTabBar.swift
//======================================================================

import SwiftUI

struct LiquidGlassTabBar: View {
    let onPostButtonTapped: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                // Center Post Button
                Button(action: onPostButtonTapped) {
                    ZStack {
                        // Glass background
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.2)
                            )
                            .overlay(
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.15),
                                                Color.white.opacity(0.05),
                                                Color.clear
                                            ]),
                                            center: .topLeading,
                                            startRadius: 3,
                                            endRadius: 20
                                        )
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.8),
                                                .white.opacity(0.3),
                                                .white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.5
                                    )
                            )

                        // Plus icon with glass reflection
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 0)
                    }
                }
                .buttonStyle(LiquidGlassButtonStyle())

                Spacer()
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Liquid Glass Button Style
struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(
                color: .black.opacity(0.2),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .shadow(
                color: .white.opacity(0.1),
                radius: configuration.isPressed ? 2 : 4,
                x: 0,
                y: configuration.isPressed ? -1 : -2
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
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

        LiquidGlassTabBar {
            print("Post button tapped")
        }
    }
}