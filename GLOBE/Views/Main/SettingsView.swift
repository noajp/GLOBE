//======================================================================
// MARK: - SettingsView.swift
// Purpose: App settings and preferences interface
// Path: GLOBE/Views/SettingsView.swift
//======================================================================
import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var appSettings = AppSettings.shared
    @State private var showDebugLogs = false
    @State private var showLocationDeniedAlert = false
    @State private var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    @State private var locationServicesEnabled = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MinimalDesign.Colors.primary)
                }
                
                Text("SETTINGS")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .padding(.leading, 8)
                
                Spacer()
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            .padding(.vertical, MinimalDesign.Spacing.xs)
            
            // Content
            ScrollView {
                VStack(spacing: MinimalDesign.Spacing.lg) {
                    // Account Section
                    VStack(alignment: .leading, spacing: MinimalDesign.Spacing.md) {
                        Text("Account")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.primary)
                        
                        SettingsItem(
                            icon: "person.circle",
                            title: "Profile",
                            action: {}
                        )
                        
                        SettingsItem(
                            icon: "lock",
                            title: "Privacy",
                            action: {}
                        )
                    }
                    
                    // Posting Section
                    VStack(alignment: .leading, spacing: MinimalDesign.Spacing.md) {
                        Text("Posting")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.primary)

                        HStack {
                            Toggle(isOn: $appSettings.defaultAnonymousPosting) {
                                Text("Post as Anonymous by default")
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                    .font(.system(size: 16))
                            }
                            .tint(MinimalDesign.Colors.accentRed)
                        }

                        HStack {
                            Toggle(isOn: $appSettings.showLocationNameOnPost) {
                                Text("Include location name in posts")
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                    .font(.system(size: 16))
                            }
                            .tint(MinimalDesign.Colors.primary)
                        }
                    }

                    // App Section
                    VStack(alignment: .leading, spacing: MinimalDesign.Spacing.md) {
                        Text("App")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.primary)

                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $appSettings.showMyLocationOnMap) {
                                Text("Show my location on the map")
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                    .font(.system(size: 16))
                            }
                            // Avoid white-on-white appearance; use accent color for ON state
                            .tint(MinimalDesign.Colors.accentRed)
                            .disabled(!locationServicesEnabled && 
                                     locationAuthStatus != .authorizedWhenInUse &&
                                     locationAuthStatus != .authorizedAlways)

                            // Enhanced status display with color coding
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(statusColor(for: locationAuthStatus))
                                    .frame(width: 8, height: 8)
                                
                                Text("Permission: \(authorizationStatusText(locationAuthStatus))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(statusColor(for: locationAuthStatus))
                                
                                Text("•")
                                    .foregroundColor(MinimalDesign.Colors.tertiary)
                                
                                Text("Services: \(locationServicesEnabled ? "On" : "Off")")
                                    .font(.system(size: 12))
                                    .foregroundColor(locationServicesEnabled ? .green : .red)
                            }

                            // Action buttons based on current status
                            HStack(spacing: 8) {
                                if locationAuthStatus == .notDetermined {
                                    Button {
                                        requestLocationPermission()
                                    } label: {
                                        Label("Grant Permission", systemImage: "location.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(MinimalDesign.Colors.accentRed)
                                            .cornerRadius(8)
                                    }
                                } else if locationAuthStatus == .denied || 
                                         locationAuthStatus == .restricted ||
                                         !locationServicesEnabled {
                                    Button {
                                        showLocationDeniedAlert = true
                                    } label: {
                                        Label("Open Settings", systemImage: "gear")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.yellow.opacity(0.9))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            // Help text based on status
                            if locationAuthStatus == .denied {
                                Text("⚠️ Location access denied. Tap 'Open Settings' to enable.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                                    .padding(.top, 4)
                            } else if !locationServicesEnabled {
                                Text("⚠️ Location Services are off. Enable in Settings > Privacy & Security.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                                    .padding(.top, 4)
                            } else if locationAuthStatus == .authorizedWhenInUse {
                                Text("✅ Location enabled. Your position will show on the map.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green)
                                    .padding(.top, 4)
                            }
                        }
                        
                        SettingsItem(
                            icon: "bell",
                            title: "Notifications",
                            action: {}
                        )
                        
                        SettingsItem(
                            icon: "questionmark.circle",
                            title: "Help",
                            action: {}
                        )
                        
                        #if DEBUG
                        SettingsItem(
                            icon: "doc.text",
                            title: "Debug Logs",
                            action: { showDebugLogs = true }
                        )
                        #endif
                    }
                    
                    // Sign Out
                    Button(action: {
                        Task { @MainActor in
                            await authManager.signOut()
                        }
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.accentRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MinimalDesign.Spacing.md)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(MinimalDesign.Colors.accentRed, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, MinimalDesign.Spacing.lg)
                }
                .padding(.horizontal, MinimalDesign.Spacing.md)
                .padding(.top, MinimalDesign.Spacing.md)
            }
        }
        .background(MinimalDesign.Colors.background)
        .navigationBarHidden(true)
        .sheet(isPresented: $showDebugLogs) {
            DebugConsoleView()
        }
        .onAppear {
            updateLocationAuthStatus()
        }
        .onChange(of: appSettings.showMyLocationOnMap) { _, newValue in
            if newValue {
                if locationAuthStatus == .notDetermined {
                    requestLocationPermission()
                } else if locationAuthStatus == .denied || locationAuthStatus == .restricted {
                    showLocationDeniedAlert = true
                }
            }
        }
        .alert("Location access required", isPresented: $showLocationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable location access in iOS Settings to show your position on the map.")
        }
    }
    
    // MARK: - Location Permission Handling
    private func updateLocationAuthStatus() {
        // Check status on background thread to avoid UI warnings
        DispatchQueue.global(qos: .userInitiated).async {
            let locationManager = CLLocationManager()
            let authStatus = locationManager.authorizationStatus
            let servicesEnabled = CLLocationManager.locationServicesEnabled()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.locationAuthStatus = authStatus
                self.locationServicesEnabled = servicesEnabled
            }
        }
    }
    
    private func requestLocationPermission() {
        print("🔑 Requesting location permission from Settings")
        
        // Only request if not determined
        guard locationAuthStatus == .notDetermined else {
            print("⚠️ Permission already determined: \(locationAuthStatus.rawValue)")
            return
        }
        
        // Use the shared MapLocationService instead of creating a new CLLocationManager
        // This prevents conflicts with the main location service
        print("🔗 Delegating to MapLocationService for permission request")
        
        // We'll let the main location service handle the permission request
        // and just update our UI state when it changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateLocationAuthStatus()
        }
    }
}

// MARK: - Local helpers
private func authorizationStatusText(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "Not Determined"
    case .restricted:    return "Restricted"
    case .denied:        return "Denied"
    case .authorizedAlways:    return "Always"
    case .authorizedWhenInUse: return "While Using"
    @unknown default:     return "Unknown"
    }
}

private func statusColor(for status: CLAuthorizationStatus) -> Color {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
        return .green
    case .notDetermined:
        return .orange
    case .denied, .restricted:
        return .red
    @unknown default:
        return .gray
    }
}

// MARK: - Settings Item
struct SettingsItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MinimalDesign.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(MinimalDesign.Colors.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.tertiary)
            }
            .padding(.vertical, MinimalDesign.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
