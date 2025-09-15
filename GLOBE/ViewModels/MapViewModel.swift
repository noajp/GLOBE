//======================================================================
// MARK: - MapViewModel.swift
// Purpose: ViewModel for map functionality following MVVM pattern
// Path: GLOBE/ViewModels/MapViewModel.swift
//======================================================================

import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit

@MainActor
class MapViewModel: NSObject, ObservableObject {
    // MARK: - Dependencies
    private let postRepository: PostRepositoryProtocol
    private let locationManager: CLLocationManager

    // MARK: - Published Properties
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // Tokyo
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var posts: [Post] = []
    @Published var visiblePosts: [Post] = []
    @Published var selectedPost: Post?

    // MARK: - Location Properties
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationServicesEnabled = false
    @Published var locationError: String?

    // MARK: - Map State
    @Published var currentZoomLevel: Double = 0.1
    @Published var isTrackingUser = false
    @Published var mapType: MKMapType = .hybrid

    // MARK: - UI State
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Constants
    private let globalZoomThreshold: Double = 0.5  // Show high-engagement posts
    private let localZoomThreshold: Double = 0.05  // Show all posts
    private let nearbyRadius: Double = 10000       // 10km radius for nearby posts

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var shouldShowAllPosts: Bool {
        currentZoomLevel <= localZoomThreshold
    }

    var shouldShowHighEngagementOnly: Bool {
        currentZoomLevel >= globalZoomThreshold
    }

    var canCreatePost: Bool {
        userLocation != nil && locationPermissionStatus == .authorizedWhenInUse
    }

    // MARK: - Initialization
    init(
        postRepository: PostRepositoryProtocol = ServiceContainer.serviceLocator.postRepository()
    ) {
        self.postRepository = postRepository
        self.locationManager = CLLocationManager()

        super.init()

        setupLocationManager()
        setupObservers()
    }

    // MARK: - Setup Methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters

        updateLocationServicesStatus()
    }

    private func setupObservers() {
        // Observe zoom level changes to filter posts
        $region
            .map { $0.span.latitudeDelta }
            .removeDuplicates()
            .sink { [weak self] zoomLevel in
                self?.currentZoomLevel = zoomLevel
                self?.updateVisiblePosts()
            }
            .store(in: &cancellables)

        // Observe posts changes
        $posts
            .sink { [weak self] _ in
                self?.updateVisiblePosts()
            }
            .store(in: &cancellables)
    }

    // MARK: - Location Management
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startLocationUpdates() {
        guard locationPermissionStatus == .authorizedWhenInUse else {
            requestLocationPermission()
            return
        }

        locationManager.startUpdatingLocation()
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isTrackingUser = false
    }

    func centerOnUserLocation() {
        guard let userLocation = userLocation else {
            locationError = "位置情報が取得できません"
            return
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            isTrackingUser = true
        }
    }

    private func updateLocationServicesStatus() {
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
        locationPermissionStatus = locationManager.authorizationStatus
    }

    // MARK: - Post Management
    func loadPosts() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let fetchedPosts: [Post]

            // If user location is available, prioritize nearby posts
            if let userLocation = userLocation {
                fetchedPosts = try await postRepository.getPostsByLocation(
                    latitude: userLocation.latitude,
                    longitude: userLocation.longitude,
                    radius: nearbyRadius
                )
            } else {
                fetchedPosts = try await postRepository.getAllPosts()
            }

            await MainActor.run {
                self.posts = fetchedPosts
                self.isLoading = false
                SecureLogger.shared.info("Loaded \(fetchedPosts.count) posts for map")
            }

        } catch {
            await MainActor.run {
                self.errorMessage = "投稿の読み込みに失敗しました"
                self.isLoading = false
                SecureLogger.shared.error("Failed to load posts for map: \(error.localizedDescription)")
            }
        }
    }

    func refreshPosts() async {
        await loadPosts()
    }

    private func updateVisiblePosts() {
        if shouldShowHighEngagementOnly {
            // Show only posts with high engagement at global zoom level
            visiblePosts = posts.filter { $0.likeCount >= 5 || $0.commentCount >= 3 }
        } else if shouldShowAllPosts {
            // Show all posts at local zoom level
            visiblePosts = posts
        } else {
            // Show moderate engagement posts at medium zoom level
            visiblePosts = posts.filter { $0.likeCount >= 1 || $0.commentCount >= 1 }
        }

        SecureLogger.shared.info("Updated visible posts: \(visiblePosts.count)/\(posts.count) visible")
    }

    // MARK: - Map Interaction
    func selectPost(_ post: Post) {
        selectedPost = post

        // Center map on selected post
        withAnimation(.easeInOut(duration: 0.3)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: post.latitude,
                    longitude: post.longitude
                ),
                span: region.span
            )
        }
    }

    func deselectPost() {
        selectedPost = nil
    }

    func updateRegion(_ newRegion: MKCoordinateRegion) {
        region = newRegion
        isTrackingUser = false // Stop tracking when user manually moves map
    }

    // MARK: - Map Configuration
    func toggleMapType() {
        mapType = mapType == .hybrid ? .standard : .hybrid
    }

    func setMapType(_ type: MKMapType) {
        mapType = type
    }

    // MARK: - Utility Methods
    func getLocationName(for coordinate: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                // Return area name without detailed address for privacy
                return [placemark.administrativeArea, placemark.locality, placemark.subLocality]
                    .compactMap { $0 }
                    .first
            }
        } catch {
            SecureLogger.shared.error("Failed to geocode location: \(error.localizedDescription)")
        }

        return nil
    }

    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    // MARK: - Error Management
    func clearError() {
        errorMessage = nil
        locationError = nil
    }

    // MARK: - Cleanup
    // Note: CLLocationManager will stop updates when deallocated with its owner.
}

// MARK: - CLLocationManagerDelegate
extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let newCoordinate = location.coordinate
        userLocation = newCoordinate

        if isTrackingUser {
            withAnimation(.easeInOut(duration: 0.3)) {
                region = MKCoordinateRegion(
                    center: newCoordinate,
                    span: region.span
                )
            }
        }

        SecureLogger.shared.info("User location updated lat=\(newCoordinate.latitude), lon=\(newCoordinate.longitude)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = "位置情報の取得に失敗しました: \(error.localizedDescription)"
        SecureLogger.shared.error("Location manager failed: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationPermissionStatus = status

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Task { @MainActor in self.startLocationUpdates() }
            locationError = nil
        case .denied, .restricted:
            locationError = "位置情報へのアクセスが拒否されています"
            Task { @MainActor in self.stopLocationUpdates() }
        case .notDetermined:
            locationError = nil
        @unknown default:
            locationError = "不明な位置情報エラー"
        }

        SecureLogger.shared.info("Location authorization changed: status=\(String(describing: status))")
    }
}
