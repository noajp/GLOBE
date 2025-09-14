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
            Map(coordinateRegion: $mapManager.region, showsUserLocation: true, annotationItems: mapManager.posts) { post in
                MapAnnotation(coordinate: post.location) {
                    PostPin(post: post) {
                        selectedPost = post
                        showingPostDetail = true
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .onReceive(locationManager.$userLocation) { location in
                if let location = location, shouldMoveToCurrentLocation {
                    mapManager.moveToLocation(location.coordinate)
                    shouldMoveToCurrentLocation = false
                }
            }
            .onTapGesture(coordinateSpace: .local) { location in
                if authManager.isAuthenticated {
                    handleMapTap(at: location)
                }
            }

            // Floating controls overlay
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 12) {
                        // Current location button
                        Button(action: {
                            if let userLocation = locationManager.userLocation {
                                mapManager.moveToLocation(userLocation.coordinate)
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }

                        // Zoom out to world view button
                        Button(action: {
                            mapManager.showWorldView()
                        }) {
                            Image(systemName: "globe")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post, isPresented: .constant(true))
        }
    }

    // MARK: - Private Methods

    private func handleMapTap(at location: CGPoint) {
        authManager.reportSecurityEvent(
            "map_interaction",
            severity: .low,
            details: ["action": "tap", "authenticated": "true"]
        )

        let coordinate = mapManager.convertPointToCoordinate(location)
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