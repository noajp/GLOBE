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
    @Binding var tappedLocation: CLLocationCoordinate2D?

    @State private var selectedPost: Post?
    @State private var showingPostDetail = false
    @State private var mapCameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917),
            distance: 1500,
            heading: 0,
            pitch: 45  // Start with 3D angle
        )
    )

    var body: some View {
        ZStack {
            // Map with 3D capabilities
            Map(position: $mapCameraPosition, interactionModes: .all) {
                // User location marker
                if let userLocation = locationManager.location {
                    Annotation("", coordinate: userLocation.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 30, height: 30)
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 12, height: 12)
                        }
                    }
                }

                // Post annotations
                ForEach(mapManager.posts) { post in
                    let isValidCoordinate = CLLocationCoordinate2DIsValid(post.location)
                    if isValidCoordinate {
                        Annotation("", coordinate: post.location) {
                            PostPin(post: post) {
                                selectedPost = post
                                showingPostDetail = true
                            }
                        }
                        .annotationTitles(.hidden)
                    } else {
                        let _ = print("⚠️ Invalid coordinate for post \(post.id): (\(post.location.latitude), \(post.location.longitude))")
                    }
                }
            }
            // Enable all interactions and 3D features
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                // Empty - no visible controls, gesture only
            }
            .onReceive(locationManager.$location) { location in
                if let location = location, shouldMoveToCurrentLocation {
                    // Update camera position with 3D perspective
                    withAnimation {
                        mapCameraPosition = .camera(
                            MapCamera(
                                centerCoordinate: location.coordinate,
                                distance: 1000, // Distance in meters
                                heading: 0, // North facing
                                pitch: 60 // 60 degree angle for 3D view
                            )
                        )
                    }
                    shouldMoveToCurrentLocation = false
                }
            }
            .onAppear {
                // Start location updates
                locationManager.startLocationServices()

                // Set initial camera position with 3D view
                if let location = locationManager.location {
                    mapCameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: location.coordinate,
                            distance: 1000,
                            heading: 0,
                            pitch: 60
                        )
                    )
                }

                // Debug post display
                print("🗺️ MapContentView onAppear: Displaying \(mapManager.posts.count) posts")
                for (index, post) in mapManager.posts.enumerated() {
                    print("📍 Post \(index): \(post.id) at (\(post.location.latitude), \(post.location.longitude)) - '\(post.text)'")
                }
            }
            .onChange(of: locationManager.location) { _, newLocation in
                // Update user location when it changes
                if let location = newLocation {
                    // Only update if we're not manually controlling the camera
                    if shouldMoveToCurrentLocation {
                        withAnimation {
                            mapCameraPosition = .camera(
                                MapCamera(
                                    centerCoordinate: location.coordinate,
                                    distance: 1000,
                                    heading: 0,
                                    pitch: 60
                                )
                            )
                        }
                        shouldMoveToCurrentLocation = false
                    }
                }
            }
            // MapManager からの位置更新をSwiftUI Mapに反映
            .onReceive(mapManager.$shouldUpdateMapPosition) { newPosition in
                guard let newPosition else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    mapCameraPosition = newPosition
                }
            }
            .onChange(of: mapManager.posts) { _, newPosts in
                print("🗺️ MapContentView: Posts changed to \(newPosts.count) posts")
                for (index, post) in newPosts.enumerated() {
                    print("📍 Updated Post \(index): \(post.id) at (\(post.location.latitude), \(post.location.longitude)) - '\(post.text)'")
                }
            }
            // 画面タップで投稿作成を起動しない（＋ボタン専用）

            // Debug UI removed: no test post button in production

        }
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post, isPresented: .constant(true))
        }
    }

    // MARK: - Private Methods (投稿作成は＋ボタン専用のため、タップ起動処理は削除)
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var showingCreatePost = false
        @State private var shouldMoveToCurrentLocation = false
        @State private var tappedLocation: CLLocationCoordinate2D?

        var body: some View {
            MapContentView(
                mapManager: MapManager(),
                locationManager: MapLocationService(),
                postManager: PostManager.shared,
                authManager: AuthManager.shared,
                showingCreatePost: $showingCreatePost,
                shouldMoveToCurrentLocation: $shouldMoveToCurrentLocation,
                tappedLocation: $tappedLocation
            )
        }
    }

    return PreviewContainer()
}
