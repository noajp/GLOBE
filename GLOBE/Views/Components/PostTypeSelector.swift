//======================================================================
// MARK: - PostTypeSelector.swift
// Purpose: Post type selection component positioned at bottom right
// Path: GLOBE/Views/Components/PostTypeSelector.swift
//======================================================================

import SwiftUI
import CoreLocation
import MapKit

struct PostTypeSelector: View {
    @Binding var showingCreatePost: Bool
    @Binding var selectedPostType: PostType
    @Binding var tappedLocation: CLLocationCoordinate2D?

    let mapManager: MapManager
    let authManager: AuthManager

    @State private var showingTypeSelection = false

    private let buttonSize: CGFloat = 50

    var body: some View {
        VStack(spacing: 12) {
            if showingTypeSelection {
                // Post type options
                VStack(spacing: 8) {
                    PostTypeButton(
                        icon: "text.bubble",
                        title: "テキスト",
                        postType: .textPost
                    )

                    PostTypeButton(
                        icon: "camera",
                        title: "写真",
                        postType: .photoPost
                    )

                    PostTypeButton(
                        icon: "location",
                        title: "位置",
                        postType: .locationPost
                    )

                    PostTypeButton(
                        icon: "calendar",
                        title: "イベント",
                        postType: .eventPost
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Main toggle button
            Button(action: toggleTypeSelection) {
                Image(systemName: showingTypeSelection ? "xmark" : "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(.white.opacity(0.9))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                    .rotationEffect(.degrees(showingTypeSelection ? 45 : 0))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingTypeSelection)
    }

    private func toggleTypeSelection() {
        withAnimation {
            showingTypeSelection.toggle()
        }
    }

    private func selectPostType(_ type: PostType) {
        selectedPostType = type
        tappedLocation = mapManager.region.center
        showingCreatePost = true
        showingTypeSelection = false
    }

    @ViewBuilder
    private func PostTypeButton(icon: String, title: String, postType: PostType) -> some View {
        Button(action: { selectPostType(postType) }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.3), lineWidth: 1))
        }
        .frame(width: 120)
    }
}

// MARK: - PostType enum (if not already defined)
enum PostType: String, CaseIterable, Equatable, Sendable {
    case textPost = "text"
    case photoPost = "photo"
    case locationPost = "location"
    case eventPost = "event"

    var displayName: String {
        switch self {
        case .textPost: return "テキスト"
        case .photoPost: return "写真"
        case .locationPost: return "位置"
        case .eventPost: return "イベント"
        }
    }

    var icon: String {
        switch self {
        case .textPost: return "text.bubble"
        case .photoPost: return "camera"
        case .locationPost: return "location"
        case .eventPost: return "calendar"
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewContainer: View {
        @State var showingCreatePost = false
        @State var selectedPostType: PostType = .textPost
        @State var tappedLocation: CLLocationCoordinate2D?

        var body: some View {
            ZStack {
                Color.blue.opacity(0.3)
                    .ignoresSafeArea()

                PostTypeSelector(
                    showingCreatePost: $showingCreatePost,
                    selectedPostType: $selectedPostType,
                    tappedLocation: $tappedLocation,
                    mapManager: MapManager(),
                    authManager: AuthManager.shared
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20)
                .padding(.bottom, 120)
            }
        }
    }

    return PreviewContainer()
}