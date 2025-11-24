//======================================================================
// MARK: - AboutView.swift
// Purpose: About GLOBE app information
// Path: GLOBE/Views/Settings/About/AboutView.swift
//======================================================================
import SwiftUI

struct AboutView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App Icon and Name
                VStack(spacing: 16) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 80))
                        .foregroundColor(MinimalDesign.Colors.accent)

                    Text("GLOBE")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.system(size: 15))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                }
                .padding(.top, 32)

                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("About GLOBE")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    Text("GLOBE is a location-based social network that lets you share moments tied to real-world places. Discover what's happening around you, connect with your community, and explore the world through the eyes of others.")
                        .font(.system(size: 15))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 20)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    Text("Key Features")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    FeatureRow(icon: "map", title: "Location-Based Posts", description: "Share content tied to specific places")
                    FeatureRow(icon: "clock", title: "24-Hour Stories", description: "Posts expire automatically after 24 hours")
                    FeatureRow(icon: "person.2", title: "Social Connections", description: "Follow friends and discover new people")
                    FeatureRow(icon: "hand.thumbsup", title: "Engagement", description: "Like and comment on posts")
                    FeatureRow(icon: "lock.shield", title: "Privacy First", description: "Control what you share and who sees it")
                }
                .padding(.horizontal, 20)

                // Credits
                VStack(alignment: .leading, spacing: 12) {
                    Text("Credits")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Developer")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)
                        Text("Takanori Nakano")
                            .font(.system(size: 15))
                            .foregroundColor(MinimalDesign.Colors.text)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Technologies")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)
                        Text("SwiftUI, MapKit, Supabase")
                            .font(.system(size: 15))
                            .foregroundColor(MinimalDesign.Colors.text)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

                // Copyright
                VStack(spacing: 8) {
                    Text("© 2025 GLOBE")
                        .font(.system(size: 13))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)

                    Text("Made with ❤️ for explorers")
                        .font(.system(size: 13))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                }
                .padding(.bottom, 32)
            }
        }
        .background(MinimalDesign.Colors.background)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(MinimalDesign.Colors.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MinimalDesign.Colors.text)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
