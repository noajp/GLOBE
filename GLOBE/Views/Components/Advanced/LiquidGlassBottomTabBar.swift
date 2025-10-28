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

    private let buttonWidth: CGFloat = 32
    private let buttonHeight: CGFloat = 32

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 20) {
                // Post Button
                Button(action: {
                    selectedTab = .post
                    onPostTapped()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selectedTab == .post ? .black : .white)
                        .frame(width: buttonWidth, height: buttonHeight)
                }
                .background {
                    if selectedTab == .post {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().fill(Color.white.opacity(0.15)))
                            .matchedGeometryEffect(id: "tab_selection", in: namespace)
                    }
                }

                // Location Button
                Button(action: {
                    selectedTab = .location
                    onLocationTapped()
                }) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(selectedTab == .location ? .black : .white)
                        .frame(width: buttonWidth, height: buttonHeight)
                }
                .background {
                    if selectedTab == .location {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().fill(Color.white.opacity(0.15)))
                            .matchedGeometryEffect(id: "tab_selection", in: namespace)
                    }
                }

                // Profile Button
                Button(action: {
                    selectedTab = .profile
                    onProfileTapped()
                }) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(selectedTab == .profile ? .black : .white)
                        .frame(width: buttonWidth, height: buttonHeight)
                }
                .background {
                    if selectedTab == .profile {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().fill(Color.white.opacity(0.15)))
                            .matchedGeometryEffect(id: "tab_selection", in: namespace)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(height: 40)
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
