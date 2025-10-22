//======================================================================
// MARK: - MapContentView.swift
// Purpose: Main map display with posts and location controls
// Path: GLOBE/Views/Components/MapContentView.swift
//======================================================================

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MapContentView: View {
    @ObservedObject var mapManager: MapManager
    @ObservedObject var locationManager: MapLocationService
    @ObservedObject var postManager: PostManager
    @ObservedObject var authManager: AuthManager

    @Binding var showingCreatePost: Bool
    @Binding var shouldMoveToCurrentLocation: Bool
    @Binding var tappedLocation: CLLocationCoordinate2D?
    @Binding var vTipPoint: CGPoint

    @State private var mapCameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917),
            distance: 1500,
            heading: 0,
            pitch: 45
        )
    )

    // Debouncing for data fetching
    @State private var fetchDebounceTask: Task<Void, Never>?
    @State private var lastUpdateTime: Date = Date()

    var body: some View {
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

            // Post annotations with position adjustment and opacity management
            ForEach(mapManager.visiblePosts) { post in
                let adjustedLocation = mapManager.getAdjustedPosition(for: post.id, originalLocation: post.location)
                let opacity = mapManager.getPostOpacity(for: post.id)
                if opacity > 0.0 { // 完全透明なら表示しない
                    Annotation("", coordinate: adjustedLocation) {
                        PostPin(post: post) {
                            // Popup表示を行わない
                        }
                        .opacity(opacity)
                    }
                    .annotationTitles(.hidden)
                }
            }

            // Cluster annotations for far distance view
            ForEach(mapManager.postClusters) { cluster in
                Annotation("", coordinate: cluster.location) {
                    ClusterPin(postCount: cluster.postCount) {
                        // TODO: Expand cluster to show individual posts
                        // For now, zoom in to the cluster location
                        mapManager.focusOnLocation(cluster.location, zoomLevel: 0.01)
                    }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .mapControls {
            MapCompass()
                .mapControlVisibility(.hidden)
        }
        .onMapCameraChange(frequency: .continuous) { context in
            // Throttle updates to reduce stuttering (max 10 updates per second)
            let now = Date()
            guard now.timeIntervalSince(lastUpdateTime) > 0.1 else { return }
            lastUpdateTime = now

            // Update MapManager's region when map camera changes
            // Limit maximum zoom level (minimum span = 0.004 ≈ 400m)
            let minSpan = 0.004

            // Clamp the span values to minimum
            let latDelta = max(context.region.span.latitudeDelta, minSpan)
            let lngDelta = max(context.region.span.longitudeDelta, minSpan)

            // スムーズに制限を適用（カクつき防止）
            if context.region.span.latitudeDelta < minSpan || context.region.span.longitudeDelta < minSpan {
                // アニメーションなしで静かに制限
                DispatchQueue.main.async {
                    let restrictedRegion = MKCoordinateRegion(
                        center: context.camera.centerCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: minSpan, longitudeDelta: minSpan)
                    )
                    mapCameraPosition = .region(restrictedRegion)
                }
            }

            let newRegion = MKCoordinateRegion(
                center: context.camera.centerCoordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: latDelta,
                    longitudeDelta: lngDelta
                )
            )

            mapManager.region = newRegion
        }
        .onMapCameraChange { context in
            // Cancel previous fetch task
            fetchDebounceTask?.cancel()

            // Debounce: wait 0.5 seconds before fetching
            fetchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                guard !Task.isCancelled else { return }

                // Fetch posts when user stops moving map
                await mapManager.fetchPostsInViewport()

                // Update clusters after fetching
                await MainActor.run {
                    mapManager.updateClusters()
                }
            }

            // Temporarily disable 3D correction to prevent crashes
            // TODO: Re-implement with safer approach
            // let perspectiveCorrectedCenter = calculatePerspectiveCorrectedCenter(
            //     camera: context.camera,
            //     region: context.region
            // )
            // mapManager.draftPostCoordinate = perspectiveCorrectedCenter
        }
        .onAppear {
            locationManager.startLocationServices()

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
        }
        .onChange(of: mapManager.shouldUpdateMapPosition) { _, newPosition in
            if let newPosition = newPosition {
                withAnimation(.easeInOut(duration: 0.8)) {
                    mapCameraPosition = newPosition
                }
                // Reset the trigger to allow for subsequent updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    mapManager.shouldUpdateMapPosition = nil
                }
            }
        }
    }

    // MARK: - 3D Perspective Correction

    private func calculatePerspectiveCorrectedCenter(camera: MapCamera, region: MKCoordinateRegion) -> CLLocationCoordinate2D {
        let pitch = camera.pitch
        let _ = camera.distance

        // If pitch is 0 (top-down view), no correction needed
        guard pitch > 0 else {
            return camera.centerCoordinate
        }

        // Calculate the offset caused by pitch
        // The visible center appears shifted towards the viewer due to perspective
        let pitchRadians = pitch * .pi / 180.0
        let offsetFactor = tan(pitchRadians) * 0.3 // Empirical factor for perspective correction

        // Calculate latitude offset (negative because we shift towards viewer)
        let latitudeOffset = region.span.latitudeDelta * offsetFactor

        // Apply the correction
        let correctedLatitude = camera.centerCoordinate.latitude - latitudeOffset
        let correctedCoordinate = CLLocationCoordinate2D(
            latitude: correctedLatitude,
            longitude: camera.centerCoordinate.longitude
        )

        return correctedCoordinate
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var showingCreatePost = false
        @State private var shouldMoveToCurrentLocation = false
        @State private var tappedLocation: CLLocationCoordinate2D?
        @State private var vTipPoint: CGPoint = CGPoint.zero

        var body: some View {
            MapContentView(
                mapManager: MapManager(),
                locationManager: MapLocationService(),
                postManager: PostManager.shared,
                authManager: AuthManager.shared,
                showingCreatePost: $showingCreatePost,
                shouldMoveToCurrentLocation: $shouldMoveToCurrentLocation,
                tappedLocation: $tappedLocation,
                vTipPoint: $vTipPoint
            )
        }
    }

    return PreviewContainer()
}
