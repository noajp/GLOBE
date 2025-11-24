//======================================================================
// MARK: - MapContentView.swift
// Function: Main Map Display View
// Overview: Map-based post display with location tracking and POI selection
// Processing: Render map → Show post pins → Track location → Handle POI taps
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
    @EnvironmentObject var appSettings: AppSettings

    @Binding var showingCreatePost: Bool
    @Binding var shouldMoveToCurrentLocation: Bool
    @Binding var tappedLocation: CLLocationCoordinate2D?
    @Binding var vTipPoint: CGPoint

    @State private var mapCameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: LandmarkCoordinates.getCurrentLocaleCoordinate(),
            distance: 1500,
            heading: 0,
            pitch: 45
        )
    )

    @State private var selectedPOI: MKMapItem?
    @State private var showPOISheet = false

    // Debouncing for data fetching
    @State private var fetchDebounceTask: Task<Void, Never>?
    @State private var lastUpdateTime: Date = Date()

    //###########################################################################
    // MARK: - Map View
    // Function: mapView
    // Overview: Main map with annotations, user location, and post pins
    // Processing: Configure Map → Add user location marker → Display post annotations → Handle POI selection
    //###########################################################################

    private var mapView: some View {
        Map(position: $mapCameraPosition, interactionModes: .all, selection: $selectedPOI) {
            // User location marker (表示設定に基づいて表示/非表示)
            if appSettings.showMyLocationOnMap, let userLocation = locationManager.location {
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
            ForEach(mapManager.visiblePosts, id: \.id) { post in
                let adjustedLocation = mapManager.getAdjustedPosition(for: post.id, originalLocation: post.location)
                let opacity = mapManager.getPostOpacity(for: post.id)
                if opacity > 0.0 {
                    Annotation("", coordinate: adjustedLocation) {
                        PostPin(post: post) {
                            // Popup表示を行わない
                        }
                        .id(post.id) // 明示的なIDを追加してビューの再利用を防止
                        .opacity(opacity)
                    }
                    .annotationTitles(.hidden)
                }
            }

            // Cluster annotations for far distance view
            ForEach(mapManager.postClusters) { cluster in
                Annotation("", coordinate: cluster.location) {
                    ClusterPin(postCount: cluster.postCount) {
                        mapManager.focusOnLocation(cluster.location, zoomLevel: 0.01)
                    }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .excludingAll))
    }

    var body: some View {
        mapView
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
            let newRegion = MKCoordinateRegion(
                center: context.camera.centerCoordinate,
                span: context.region.span
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

            // ユーザーのhome_countryがあれば、その国のランドマークを表示
            Task {
                if let userProfile = authManager.currentUser,
                   let homeCountryCode = userProfile.homeCountry,
                   let country = CountryData.country(for: homeCountryCode) {
                    // ホーム国のランドマークに移動（3Dビュー）
                    mapCameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: country.coordinate,
                            distance: 1000,
                            heading: 0,
                            pitch: 60
                        )
                    )
                    ConsoleLogger.shared.forceLog("MapContentView: Moved to home country \(country.name) at \(country.landmarkName)")
                } else if let location = locationManager.location {
                    // ホーム国が未設定なら現在地を使用
                    mapCameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: location.coordinate,
                            distance: 1000,
                            heading: 0,
                            pitch: 60
                        )
                    )
                } else {
                    // 位置情報もない場合はデバイスのロケールから推測
                    let countryCode = Locale.current.region?.identifier ?? "JP"
                    if let country = CountryData.country(for: countryCode) {
                        mapCameraPosition = .camera(
                            MapCamera(
                                centerCoordinate: country.coordinate,
                                distance: 1000,
                                heading: 0,
                                pitch: 60
                            )
                        )
                        ConsoleLogger.shared.forceLog("MapContentView: Moved to device locale country \(country.name)")
                    }
                }
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
        .onChange(of: selectedPOI) { _, newPOI in
            if newPOI != nil {
                showPOISheet = true
            }
        }
        .sheet(isPresented: $showPOISheet, onDismiss: {
            selectedPOI = nil
        }) {
            if let mapItem = selectedPOI {
                VStack(alignment: .leading, spacing: 12) {
                    Text(mapItem.name ?? "Unknown Place")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let phoneNumber = mapItem.phoneNumber {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text(phoneNumber)
                        }
                        .font(.subheadline)
                    }

                    if let address = mapItem.name {
                        HStack(alignment: .top) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(address)
                        }
                        .font(.subheadline)
                    }

                    Spacer()
                }
                .padding()
                .presentationDetents([.height(200), .medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 3D Perspective Correction

    //###########################################################################
    // MARK: - Perspective Correction
    // Function: calculatePerspectiveCorrectedCenter
    // Overview: Correct map center coordinate based on camera pitch
    // Processing: Check pitch angle → Calculate offset factor → Apply latitude correction → Return adjusted coordinate
    //###########################################################################

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
