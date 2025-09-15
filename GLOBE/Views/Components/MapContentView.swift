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

    @State private var selectedPost: Post?
    @State private var showingPostDetail = false
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
                            selectedPost = post
                            showingPostDetail = true
                        }
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
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
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post, isPresented: .constant(true))
        }
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