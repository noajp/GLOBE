//======================================================================
// MARK: - RefactoredMainTabView.swift
// Purpose: Refactored main view with separated components
// Path: GLOBE/Views/RefactoredMainTabView.swift
//======================================================================

import SwiftUI
import MapKit
import CoreLocation

struct RefactoredMainTabView: View {
    // MARK: - Dependencies
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var postManager = PostManager.shared
    @StateObject private var mapManager = MapManager()
    @StateObject private var locationManager = MapLocationService()
    @StateObject private var appSettings = AppSettings.shared

    // MARK: - State
    @State private var showingCreatePost = false
    @State private var stories: [Story] = Story.mockStories
    @State private var showingAuth = false
    @State private var showingProfile = false
    @State private var shouldMoveToCurrentLocation = false
    @State private var selectedStory: Story?

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Header
                HeaderView(
                    showingAuth: $showingAuth,
                    showingProfile: $showingProfile
                )

                // Stories bar
                StoriesBarView(
                    stories: stories,
                    selectedStory: $selectedStory
                )

                // Map content
                MapContentView(
                    mapManager: mapManager,
                    locationManager: locationManager,
                    postManager: postManager,
                    authManager: authManager,
                    showingCreatePost: $showingCreatePost,
                    shouldMoveToCurrentLocation: $shouldMoveToCurrentLocation
                )
            }
            .background(MinimalDesign.Colors.background)

            // Create post popup
            if showingCreatePost {
                PostPopupView(
                    isPresented: $showingCreatePost,
                    mapManager: mapManager
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showingCreatePost)
            }
        }
        .onAppear {
            setupInitialState()
        }
        .sheet(isPresented: $showingAuth) {
            AuthenticationView()
        }
        .sheet(isPresented: $showingProfile) {
            MyPageView()
        }
        .sheet(item: $selectedStory) { story in
            StoryDetailView(story: story, isPresented: .constant(true))
        }
    }

    // MARK: - Private Methods
    private func setupInitialState() {
        // Request location permission
        locationManager.requestLocationPermission()

        // Load posts
        Task {
            await postManager.fetchPosts()
            // Posts are automatically synchronized via MapManager's setupPostSubscription()
        }

        // Security event logging
        authManager.reportSecurityEvent(
            "app_launch",
            severity: .low,
            details: ["view": "main_tab"]
        )

        // Move to current location if available
        if let location = locationManager.location {
            mapManager.focusOnLocation(location.coordinate)
        }
    }
}

// MARK: - Preview
#Preview {
    RefactoredMainTabView()
}