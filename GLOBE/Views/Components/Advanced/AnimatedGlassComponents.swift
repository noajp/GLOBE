//======================================================================
// MARK: - AnimatedGlassComponents.swift
// Purpose: Animated glass components with symbol transitions
// Path: GLOBE/Views/Components/Advanced/AnimatedGlassComponents.swift
//======================================================================

import SwiftUI

// MARK: - Animated Glass Post Button
struct AnimatedGlassPostButton: View {
    @State private var isPressed = false
    @State private var isExpanded = false
    let onPostTapped: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                ZStack {
                    // Main post button
                    GlassCircleButton(
                        id: "post-button",
                        size: isExpanded ? 70 : 60,
                        action: {
                            withAnimation(.bouncy(duration: 0.6)) {
                                isExpanded.toggle()
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onPostTapped()
                                withAnimation(.easeOut(duration: 0.4)) {
                                    isExpanded = false
                                }
                            }
                        }
                    ) {
                        Image(systemName: isExpanded ? "plus.circle.fill" : "plus")
                            .font(.system(size: isExpanded ? 28 : 24, weight: .medium))
                            .foregroundStyle(.white)
                            .contentTransition(.symbolEffect(.replace.byLayer))
                            .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
                    }

                    // Ripple effect
                    if isExpanded {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 90, height: 90)
                            .scaleEffect(isExpanded ? 1.2 : 0.8)
                            .opacity(isExpanded ? 0 : 1)
                            .animation(.easeOut(duration: 0.8), value: isExpanded)
                    }
                }

                Spacer()
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Expandable Glass Action Cluster
struct ExpandableGlassActionCluster: View {
    @State private var isExpanded = false
    @State private var likedState = false
    @State private var savedState = false

    let onShare: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                HStack(spacing: 16) {
                    if isExpanded {
                        // Share button
                        GlassCircleButton(
                            id: "share-button",
                            size: 50,
                            action: onShare
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))

                        // Like button
                        GlassCircleButton(
                            id: "like-button",
                            size: 50,
                            action: {
                                withAnimation(.bouncy(duration: 0.5)) {
                                    likedState.toggle()
                                }
                                onLike()
                            }
                        ) {
                            Image(systemName: likedState ? "heart.fill" : "heart")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(likedState ? .red : .white)
                                .contentTransition(.symbolEffect(.replace.byLayer))
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))

                        // Save button
                        GlassCircleButton(
                            id: "save-button",
                            size: 50,
                            action: {
                                withAnimation(.bouncy(duration: 0.5)) {
                                    savedState.toggle()
                                }
                                onSave()
                            }
                        ) {
                            Image(systemName: savedState ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(savedState ? .yellow : .white)
                                .contentTransition(.symbolEffect(.replace.byLayer))
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }

                    // More/Close button
                    GlassCircleButton(
                        id: "more-button",
                        size: 60,
                        action: {
                            withAnimation(.bouncy(duration: 0.6)) {
                                isExpanded.toggle()
                            }
                        }
                    ) {
                        Image(systemName: isExpanded ? "xmark" : "ellipsis")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                            .contentTransition(.symbolEffect(.replace.byLayer))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }

                Spacer()
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Glass Quote Panel
struct GlassQuotePanel: View {
    let quote: String
    let author: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(quote)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            if let author = author {
                Text("— \(author)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(24)
        .coordinatedGlassEffect(id: "quote-panel")
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Glass Navigation Header
struct GlassNavigationHeader: View {
    let title: String
    let showBackButton: Bool
    let onBack: (() -> Void)?

    var body: some View {
        HStack {
            if showBackButton {
                GlassCircleButton(
                    id: "back-button",
                    size: 44,
                    action: { onBack?() }
                ) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            if showBackButton {
                // Invisible spacer for balance
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .coordinatedGlassEffect(id: "nav-header")
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}