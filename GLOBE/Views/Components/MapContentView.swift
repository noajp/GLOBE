//======================================================================
// MARK: - MapContentView.swift
// Purpose: Main map display with posts and location controls
// Path: GLOBE/Views/Components/MapContentView.swift
//======================================================================

import SwiftUI
import MapKit
import CoreLocation

struct MapContentView: View {
    @ObservedObject var mapManager: MapManager
    @ObservedObject var locationManager: MapLocationService
    @ObservedObject var postManager: PostManager
    @ObservedObject var authManager: AuthManager

    @Binding var showingCreatePost: Bool
    @Binding var shouldMoveToCurrentLocation: Bool

    @State private var selectedPost: Post?
    @State private var showingPostDetail = false

    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $mapManager.region, interactionModes: [.pan, .zoom, .rotate], showsUserLocation: true, annotationItems: mapManager.posts) { post in
                MapAnnotation(coordinate: post.location) {
                    PostPin(post: post) {
                        selectedPost = post
                        showingPostDetail = true
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .onReceive(locationManager.$location) { location in
                if let location = location, shouldMoveToCurrentLocation {
                    mapManager.focusOnLocation(location.coordinate)
                    shouldMoveToCurrentLocation = false
                }
            }
            .onTapGesture {
                if authManager.isAuthenticated {
                    handleMapTap()
                }
            }

        }
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post, isPresented: .constant(true))
        }
    }

    // MARK: - Private Methods

    private func handleMapTap() {
        authManager.reportSecurityEvent(
            "map_interaction",
            severity: .low,
            details: ["action": "tap", "authenticated": "true"]
        )
        showingCreatePost = true
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var showingCreatePost = false
        @State private var shouldMoveToCurrentLocation = false

        var body: some View {
            MapContentView(
                mapManager: MapManager(),
                locationManager: MapLocationService(),
                postManager: PostManager.shared,
                authManager: AuthManager.shared,
                showingCreatePost: $showingCreatePost,
                shouldMoveToCurrentLocation: $shouldMoveToCurrentLocation
            )
        }
    }

    return PreviewContainer()
}
