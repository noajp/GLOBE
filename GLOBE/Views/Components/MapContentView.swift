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
    @Binding var vTipPoint: CGPoint?

    @State private var mapCameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917),
            distance: 1500,
            heading: 0,
            pitch: 45
        )
    )

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

            // Post annotations
            ForEach(mapManager.posts) { post in
                if CLLocationCoordinate2DIsValid(post.location) {
                    Annotation("", coordinate: post.location) {
                        PostPin(post: post) {
                            // Popup表示を行わない
                        }
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .onMapCameraChange(frequency: .onEnd) { context in
            // Update MapManager's region when map camera changes
            let newRegion = MKCoordinateRegion(
                center: context.camera.centerCoordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: context.region.span.latitudeDelta,
                    longitudeDelta: context.region.span.longitudeDelta
                )
            )
            mapManager.region = newRegion

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
                print("🗺️ MapContentView: Received position update from MapManager")
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
        @State private var vTipPoint: CGPoint?

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
