//======================================================================
// MARK: - AppState.swift
// Purpose: Central application state management using Redux-like pattern
// Path: GLOBE/Core/State/AppState.swift
//======================================================================

import Foundation
import CoreLocation
import Combine

// MARK: - App State

struct AppState: Equatable {
    var authState: AuthState
    var postsState: PostsState
    var mapState: MapState
    var userState: UserState
    var uiState: UIState

    static let initial = AppState(
        authState: .initial,
        postsState: .initial,
        mapState: .initial,
        userState: .initial,
        uiState: .initial
    )
}

// MARK: - Auth State

struct AuthState: Equatable {
    var isAuthenticated: Bool
    var currentUser: AppUser?
    var isLoading: Bool
    var error: AppError?
    var loginAttempts: Int
    var isLocked: Bool

    static let initial = AuthState(
        isAuthenticated: false,
        currentUser: nil,
        isLoading: false,
        error: nil,
        loginAttempts: 0,
        isLocked: false
    )
}

// MARK: - Posts State

struct PostsState: Equatable {
    var posts: [Post]
    var userPosts: [Post]
    var selectedPost: Post?
    var isLoading: Bool
    var error: AppError?
    var lastFetchTime: Date?

    static let initial = PostsState(
        posts: [],
        userPosts: [],
        selectedPost: nil,
        isLoading: false,
        error: nil,
        lastFetchTime: nil
    )
}

// MARK: - Map State

struct MapState: Equatable {
    var userLocation: CLLocationCoordinate2D?
    var region: MapRegion
    var visiblePosts: [Post]
    var selectedPost: Post?
    var isTrackingUser: Bool
    var locationPermissionStatus: LocationPermissionStatus
    var isLocationServicesEnabled: Bool
    var zoomLevel: Double

    static let initial = MapState(
        userLocation: nil,
        region: MapRegion.tokyo,
        visiblePosts: [],
        selectedPost: nil,
        isTrackingUser: false,
        locationPermissionStatus: .notDetermined,
        isLocationServicesEnabled: false,
        zoomLevel: 0.1
    )
}

// MARK: - User State

struct UserState: Equatable {
    var profile: UserProfile?
    var stories: [Story]
    var isLoading: Bool
    var error: AppError?

    static let initial = UserState(
        profile: nil,
        stories: [],
        isLoading: false,
        error: nil
    )
}

// MARK: - UI State

struct UIState: Equatable {
    var selectedTab: TabSelection
    var showingAuth: Bool
    var showingCreatePost: Bool
    var showingProfile: Bool
    var showingSettings: Bool
    var isNetworkAvailable: Bool

    static let initial = UIState(
        selectedTab: .map,
        showingAuth: false,
        showingCreatePost: false,
        showingProfile: false,
        showingSettings: false,
        isNetworkAvailable: true
    )
}

// MARK: - Supporting Types

struct MapRegion: Equatable {
    let latitude: Double
    let longitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double

    static let tokyo = MapRegion(
        latitude: 35.6762,
        longitude: 139.6503,
        latitudeDelta: 0.1,
        longitudeDelta: 0.1
    )

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum LocationPermissionStatus: String, CaseIterable, Equatable {
    case notDetermined
    case denied
    case authorizedWhenInUse
    case authorizedAlways
    case restricted
}

enum TabSelection: String, CaseIterable, Equatable {
    case map
    case profile
    case settings
}

// MARK: - State Extensions for Computed Properties

extension AppState {
    var isAuthenticated: Bool {
        authState.isAuthenticated
    }

    var currentUser: AppUser? {
        authState.currentUser
    }

    var allPosts: [Post] {
        postsState.posts
    }

    var visiblePosts: [Post] {
        mapState.visiblePosts
    }

    var canCreatePost: Bool {
        isAuthenticated && mapState.userLocation != nil
    }

    var shouldShowAuth: Bool {
        uiState.showingAuth || (!isAuthenticated && !authState.isLoading)
    }
}

// MARK: - State Debugging

extension AppState: CustomStringConvertible {
    var description: String {
        return """
        AppState:
        - Auth: \(authState.isAuthenticated ? "Authenticated" : "Not Authenticated")
        - Posts: \(postsState.posts.count) posts
        - Map: \(mapState.visiblePosts.count) visible posts
        - User: \(userState.profile?.username ?? "No profile")
        - UI: Tab=\(uiState.selectedTab.rawValue)
        """
    }
}

// MARK: - State Validation

extension AppState {
    func validate() -> [String] {
        var issues: [String] = []

        // Validate auth consistency
        if authState.isAuthenticated && authState.currentUser == nil {
            issues.append("Authenticated but no current user")
        }

        if !authState.isAuthenticated && authState.currentUser != nil {
            issues.append("Not authenticated but has current user")
        }

        // Validate posts consistency
        if !postsState.userPosts.allSatisfy({ post in
            post.userId == authState.currentUser?.id
        }) {
            issues.append("User posts contain posts from other users")
        }

        // Validate map consistency
        if mapState.isTrackingUser && mapState.userLocation == nil {
            issues.append("Tracking user but no user location")
        }

        return issues
    }
}