//======================================================================
// MARK: - PostPopupView.swift
// Purpose: Post creation popup with full-screen photo background
// Path: GLOBE/Views/Components/PostPopupView.swift
//======================================================================
import SwiftUI
import UIKit
import CoreLocation
import MapKit
import Combine

// MARK: - Post Privacy Options
enum PostPrivacyType: Equatable, Sendable {
    case followersOnly
    case publicPost
    case anonymous
}

// MARK: - Post Type Options


struct PostPopupView: View {
    @Binding var isPresented: Bool
    @ObservedObject var mapManager: MapManager
    let initialLocation: CLLocationCoordinate2D? // Add parameter for exact post location
    var postType: PostType = .textPost // Default to text post
    @StateObject private var mapLocationService = MapLocationService()
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var postManager = PostManager.shared
    
    // カスタムデザイン用の色定義
    private let customBlack = MinimalDesign.Colors.background
    
    @State private var postText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingLocationPermissionAlert = false
    @State private var postLocation: CLLocationCoordinate2D?
    // 位置決定は地図の中心に揃える（Vの先端=地図中心）。余計なオフセットは使わない。
    @State private var areaName: String = ""
    @State private var showPrivacyDropdown = false
    @State private var selectedPrivacyType: PostPrivacyType = .anonymous
    @State private var isSubmitting = false
    // App settings
    @StateObject private var appSettings = AppSettings.shared
    
    // Computed properties to reduce complexity
    private var isButtonDisabled: Bool {
        let hasText = !postText.isEmpty
        let disabled = !hasText
        print("🔘 PostPopup - isButtonDisabled calculated: \(disabled) (hasText=\(hasText))")
        return disabled
    }
    
    private var maxTextLength: Int {
        30  // Maximum 30 characters for all posts
    }
    
    var body: some View {
        ZStack {
            // Popup content with speech bubble design
            GlassEffectContainer {
                VStack(spacing: 0) {
                    // Main card with rounded corners
                    VStack(spacing: 0) {
                        postCreationView
                    }
                    .frame(width: 280, height: 210) // Reduced height for slimmer card
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                    // Simple triangle tail below card
                    Triangle()
                        .fill(Color.clear)
                        .frame(width: 50, height: 25)
                        .glassEffect(.clear, in: Triangle())
                        .rotationEffect(.degrees(180))
                        .offset(y: -1) // Slight overlap to hide seam
                }
            }
            .shadow(radius: 10)
            // TEMPORARILY DISABLED - VTipPreferenceKey causes crashes
            // .overlay(alignment: .bottom) {
            //     GeometryReader { proxy in
            //         Color.clear
            //             .frame(width: 1, height: 1)
            //             .preference(key: VTipPreferenceKey.self, value: {
            //                 let f = proxy.frame(in: .global)
            //                 // Speech bubble tail tip position (integrated into shape)
            //                 return CGPoint(x: f.midX, y: f.maxY)
            //             }())
            //     }
            //     .frame(width: 1, height: 1)
            // }

            // Privacy selection popup from bottom
            if showPrivacyDropdown {
                Color.black.opacity(0.001) // Invisible tap area
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showPrivacyDropdown = false
                        }
                    }

                privacyPopupView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPrivacyDropdown)
        .onDisappear {
            // Clean up when popup closes
            mapManager.draftPostCoordinate = nil
            postLocation = nil
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .alert("Location access required", isPresented: $showingLocationPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow location access in Settings to move to your current location.")
        }
        .onAppear {
            // Start location services
            mapLocationService.startLocationServices()

            // Initialize with current map center
            postLocation = mapManager.region.center
            updateAreaLocation(for: mapManager.region.center)
        }
    }
    
    // MARK: - Post Creation View
    private var postCreationView: some View {
        VStack(spacing: 0) {
            headerView
            textInputView
            Spacer()
            bottomSectionView
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
    
    // MARK: - Header View
    private var headerView: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 280, height: 44) // Adjusted for smaller popup
            .overlay(
                ZStack {
                    // X button - TOP LEFT (same size as chevron button)
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(6)
                    }
                    .background(.white.opacity(0.9))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                    .position(x: 20, y: 22) // ABSOLUTE POSITION - LEFT SIDE

                    // POST button - base layer (white background)
                    Button(action: createPost) {
                        Text("POST")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.vertical, 7)
                            .padding(.leading, 16) // Move text to the right
                            .padding(.trailing, 8) // Less padding on the right
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.3), lineWidth: 1))
                    .disabled(isButtonDisabled || isSubmitting)
                    .position(x: 240, y: 22)

                    // Chevron button - overlaid on top of POST button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showPrivacyDropdown.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(9)
                            .rotationEffect(.degrees(showPrivacyDropdown ? 90 : 0))
                    }
                    .background(.black)
                    .clipShape(Circle())
                    .glassEffect(.clear, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                    .position(x: 218, y: 22) // Positioned on top of POST button
                    .onAppear {
                        print("🔘 PostPopup - Button state on appear: disabled=\(isButtonDisabled)")
                    }
                }
            )
            .zIndex(1) // ensure header stays above other layers for hit testing
    }
    
    
    // MARK: - Text Input View
    private var textInputView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            TextField("text", text: Binding(
                get: { postText },
                set: { newValue in
                    postText = newValue
                }
            ), axis: .vertical)
            .font(.system(size: 16))
            .foregroundColor(postText.count > maxTextLength ? .red : .white)
            .lineLimit(10)
            .textFieldStyle(PlainTextFieldStyle())
            .scrollContentBackground(.hidden)
            
            // 文字数カウンター
            Text("\(postText.count)/\(maxTextLength)")
                .font(.system(size: 12))
                .foregroundColor(postText.count > maxTextLength ? .red : (postText.count >= maxTextLength ? .orange : .white.opacity(0.6)))
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Bottom Section View 
    private var bottomSectionView: some View {
        // TOTALLY STATIC FRAME - NEVER CHANGES SIZE
        Rectangle()
            .fill(.clear)
            .frame(width: 280, height: 50) // Back to safer size
            .overlay(
                ZStack {
                    // Camera button - TOP ROW, RIGHT SIDE
                    Button(action: {
                        // TODO: カメラ機能の実装
                        print("📷 PostPopup: Camera button pressed")
                    }) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal,15 )
                            .padding(.vertical, 7)
                    }
                    .background(.white.opacity(0.9))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                    .position(x: 245, y: 2) // Camera button at y:2

                    // Location button - BOTTOM ROW, LEFT SIDE
                    Button(action: {
                        print("📍 PostPopup: Location button pressed")
                        // Move map to user's current location
                        if let currentLocation = mapLocationService.location?.coordinate {
                            // Move map to user location with offset
                            let offsetCoordinate = CLLocationCoordinate2D(
                                latitude: currentLocation.latitude + 0.0005,
                                longitude: currentLocation.longitude
                            )
                            mapManager.focusOnLocation(offsetCoordinate, zoomLevel: 0.0008)

                            // Update the area name for the new location
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.updateAreaLocation(for: mapManager.region.center)
                                self.postLocation = mapManager.region.center
                            }
                        } else {
                            // Request location if not available
                            mapLocationService.startLocationServices()
                        }
                    }) {
                        Image(systemName: postLocation != nil ? "location.fill" : "location")
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .background(.white.opacity(0.9))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                    .position(x: 20, y: 5) // Location button adjusted

                    // Privacy text display (shown when dropdown is open)
                    if showPrivacyDropdown {
                        Text(selectedPrivacyType == .publicPost ? "Post publicly" :
                             selectedPrivacyType == .followersOnly ? "Post to followers" : "Post anonymously")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 20)
                            .position(x: 180, y: 5)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            )
    }

    
    // MARK: - Speech Bubble Tail
    private var speechBubbleTail: some View {
        Triangle()
            .fill(Color.clear)
            .frame(width: 20, height: 15)
            .glassEffect(.clear, in: Triangle())
            .rotationEffect(.degrees(180))
            .offset(y: 15)
    }

    // MARK: - Privacy Popup View
    private var privacyPopupView: some View {
        VStack {
            Spacer()
            Spacer() // Additional spacer to push popup lower
            Spacer() // Extra spacer to push popup even lower

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select Privacy")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPrivacyDropdown = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Privacy options
                VStack(alignment: .leading, spacing: 1) {
                    privacyPopupOption(.anonymous, "person.fill.questionmark", .black, "Post anonymously", "Your identity will be hidden")
                    privacyPopupOption(.publicPost, "globe", .black, "Post publicly", "Everyone can see this post")
                    privacyPopupOption(.followersOnly, "person.2.fill", .black, "Post to followers", "Only your followers can see this")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.black.opacity(0.1), lineWidth: 1))
            .padding(.horizontal, 20)
            .shadow(radius: 10)
        }
    }

    private func privacyPopupOption(_ type: PostPrivacyType, _ icon: String, _ color: Color, _ title: String, _ subtitle: String) -> some View {
        Button(action: {
            selectedPrivacyType = type
            withAnimation(.easeInOut(duration: 0.3)) {
                showPrivacyDropdown = false
            }
        }) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 24, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    HStack {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.black.opacity(0.6))
                        Spacer()
                    }
                }

                if selectedPrivacyType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(selectedPrivacyType == type ? .black.opacity(0.05) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Action Methods

    private func createPost() {
        guard !isSubmitting else { return }
        isSubmitting = true

        // Capture values to avoid self reference issues
        let currentText = postText
        let currentPrivacyType = selectedPrivacyType
        // ALWAYS use the map center (where the popup is displayed)
        let location = mapManager.region.center

        print("📍 PostPopupView: Creating post at map center: (\(location.latitude), \(location.longitude))")

        // Create post in background without waiting for result
        Task.detached {
            do {
                try await postManager.createPost(
                    content: currentText,
                    imageData: nil,  // No image data for text-only posts
                    location: location,
                    locationName: nil,
                    isAnonymous: {
                        switch currentPrivacyType {
                        case .anonymous: return true
                        default: return false
                        }
                    }()
                )
            } catch {
                // Silently handle errors in background
            }
        }

        // Close immediately
        postText = ""
        showPrivacyDropdown = false
        isSubmitting = false
        isPresented = false
    }


    // MARK: - Helper Functions
    private func resolveAreaName(for coordinate: CLLocationCoordinate2D) async -> String? {
        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "\(coordinate.latitude),\(coordinate.longitude)"
            request.resultTypes = [.address]
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            if let mapItem = response.mapItems.first {
                var components: [String] = []
                if let name = mapItem.name {
                    let cleaned = name
                        .replacingOccurrences(of: #"[0-9]+-[0-9]+.*"#, with: "", options: .regularExpression)
                        .replacingOccurrences(of: #"[0-9]+番地.*"#, with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleaned.isEmpty { components.append(cleaned) }
                }
                // Skip if no meaningful location name found
                return components.prefix(2).joined(separator: " ")
            }
        } catch {
            return nil
        }
        return nil
    }

    
    private func updateAreaLocation(for coordinate: CLLocationCoordinate2D) {
        Task {
            if let area = await resolveAreaName(for: coordinate) {
                await MainActor.run {
                    self.areaName = area
                }
            }
        }
    }
    
    private func moveToCurrentLocation() {
        // Removed - using simpler inline approach in button action
    }

    // MARK: - Auto acquire current location on demand
    private func autoAcquireCurrentLocation() {
        // Removed - using simpler inline approach in button action
    }
    
    private func updatePostLocation() {
        postLocation = mapManager.region.center
    }
}


// MARK: - Speech Bubble Shape - TEMPORARILY DISABLED DUE TO CRASHES
// Replaced with separate RoundedRectangle and Triangle components

// MARK: - V Tip Preference - TEMPORARILY DISABLED
// struct VTipPreferenceKey: PreferenceKey {
//     static var defaultValue: CGPoint = CGPoint.zero
//     static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
//         value = nextValue()
//     }
// }

