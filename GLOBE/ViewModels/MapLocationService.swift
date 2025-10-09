//======================================================================
// MARK: - MapLocationService.swift
// Purpose: Centralized location management for MapKit integration
// Path: GLOBE/Core/Managers/MapLocationService.swift
//======================================================================

import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - MapLocationService
/// Centralized location service for map view
/// Handles location permissions and updates for MapKit
class MapLocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Properties
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917), // Tokyo default (Shibuya area)
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationAvailable = false
    @Published private(set) var annotations: [LocationAnnotation] = []
    
    private var hasSetInitialRegion = false
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // Update every 10 meters
        
        // Check initial authorization status
        authorizationStatus = manager.authorizationStatus
        
        // Set availability flag based on current status
        isLocationAvailable = (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
        
        // Don't automatically start services here - wait for explicit request
        // This prevents UI unresponsiveness warnings during initialization
    }
    
    // MARK: - Public Methods
    /// Main method to request location - handles permissions automatically
    func requestLocation() {
        // First check if location services are enabled at system level
        // Move to background thread to avoid UI warning
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            guard CLLocationManager.locationServicesEnabled() else {
                return
            }
            
            DispatchQueue.main.async {
                self.handleLocationRequest()
            }
        }
    }
    
    private func handleLocationRequest() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            startLocationServices()

        case .denied:
            break

        case .restricted:
            break

        @unknown default:
            break
        }
    }
    
    /// Legacy method for backward compatibility
    func requestLocationPermission() {
        requestLocation()
    }
    
    func startLocationServices() {
        // Only start if we have proper authorization
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }

        // Start continuous location updates (this doesn't cause UI warnings)
        manager.startUpdatingLocation()
        
        // Only request one-time location if we haven't received updates recently
        // This reduces the number of requestLocation() calls that cause UI warnings
        if location == nil {
            // Delay the one-time request to avoid UI thread blocking
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                // Final check before requesting location
                if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                    self.manager.requestLocation()
                }
            }
        }
    }
    
    func stopLocationServices() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let oldStatus = self.authorizationStatus
            self.authorizationStatus = manager.authorizationStatus

            switch self.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isLocationAvailable = true
                // Only start if we weren't already authorized
                if oldStatus != .authorizedWhenInUse && oldStatus != .authorizedAlways {
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        self?.startLocationServices()
                    }
                }

            case .denied, .restricted:
                self.isLocationAvailable = false
                self.stopLocationServices()
                self.location = nil

            case .notDetermined:
                self.isLocationAvailable = false
                
            @unknown default:
                self.isLocationAvailable = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Get the most recent location
        guard let newLocation = locations.last else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Update current location
            self.location = newLocation
            
            // Create location annotation (similar to provided code pattern)
            let annotation = LocationAnnotation(coordinate: newLocation.coordinate)
            self.annotations = [annotation]
            
            // Update region to center on user location
            let center = CLLocationCoordinate2D(
                latitude: newLocation.coordinate.latitude,
                longitude: newLocation.coordinate.longitude
            )
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            self.region = MKCoordinateRegion(center: center, span: span)

            if !self.hasSetInitialRegion {
                self.hasSetInitialRegion = true
            }

            // Trigger objectWillChange for any additional observers (following provided pattern)
            self.objectWillChange.send()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                isLocationAvailable = false

            case .locationUnknown:
                break

            case .network:
                break

            default:
                break
            }
        }
    }
    
    // MARK: - Helper Methods
    func centerOnUserLocation() {
        guard let location = location else {
            return
        }

        withAnimation {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    // MARK: - Debug Methods
    #if DEBUG
    func debugLocationStatus() {
        // Debug info available in debugger
    }

    func forcePermissionRequest() {
        manager.requestWhenInUseAuthorization()
    }
    #endif
    
    var authorizationStatusText: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "While Using"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Location Annotation
/// Simple annotation for marking locations on the map
struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}