//======================================================================
// MARK: - PrivacySettingsView.swift
// Purpose: Privacy settings screen
// Path: GLOBE/Views/Main/PrivacySettingsView.swift
//======================================================================

import SwiftUI

struct PrivacySettingsView: View {
    @StateObject private var appSettings = AppSettings.shared

    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Location Privacy Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.secondary)

                        Toggle(isOn: $appSettings.showMyLocationOnMap) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Show my location on the map")
                                    .font(.system(size: 16))
                                    .foregroundColor(MinimalDesign.Colors.primary)

                                Text("Display your current location as a blue marker on the map")
                                    .font(.system(size: 13))
                                    .foregroundColor(MinimalDesign.Colors.secondary)
                            }
                        }
                        .tint(MinimalDesign.Colors.accentRed)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
