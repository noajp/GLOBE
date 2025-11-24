//======================================================================
// MARK: - PlaceholderViews.swift
// Purpose: Placeholder views for settings sections
// Path: GLOBE/Views/Settings/PlaceholderViews.swift
//======================================================================
import SwiftUI

// MARK: - Data Management
struct DataManagementView: View {
    var body: some View {
        PlaceholderView(
            icon: "externaldrive",
            title: "Data Management",
            description: "Export your data, manage storage, and control data retention.",
            features: [
                "Export your posts and profile data",
                "View storage usage",
                "Clear cache",
                "Download your information"
            ]
        )
    }
}

// MARK: - Location Settings
struct LocationSettingsView: View {
    var body: some View {
        PlaceholderView(
            icon: "location.circle",
            title: "Location Settings",
            description: "Control how GLOBE uses your location data.",
            features: [
                "Location permission status",
                "Precise vs approximate location",
                "Location history settings",
                "Default location privacy"
            ]
        )
    }
}

// MARK: - Blocked Users
struct BlockedUsersView: View {
    var body: some View {
        PlaceholderView(
            icon: "hand.raised.circle",
            title: "Blocked Users",
            description: "Manage users you've blocked.",
            features: [
                "View blocked users list",
                "Unblock users",
                "Block new users"
            ]
        )
    }
}

// MARK: - Help Center
struct HelpCenterView: View {
    var body: some View {
        PlaceholderView(
            icon: "questionmark.circle",
            title: "Help Center",
            description: "Find answers to common questions.",
            features: [
                "Getting started guide",
                "How to create posts",
                "Privacy and safety tips",
                "Troubleshooting"
            ]
        )
    }
}

// MARK: - Report Problem
struct ReportProblemView: View {
    var body: some View {
        PlaceholderView(
            icon: "exclamationmark.bubble",
            title: "Report a Problem",
            description: "Report bugs or issues you've encountered.",
            features: [
                "Bug reports",
                "Performance issues",
                "Feature not working",
                "Other problems"
            ]
        )
    }
}

// MARK: - Open Source Licenses
struct LicensesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Open Source Licenses")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(MinimalDesign.Colors.text)

                Text("GLOBE is built with the help of these amazing open source projects:")
                    .font(.system(size: 15))
                    .foregroundColor(MinimalDesign.Colors.textSecondary)

                LicenseSection(
                    name: "Supabase Swift",
                    license: "MIT License",
                    url: "https://github.com/supabase/supabase-swift"
                )

                LicenseSection(
                    name: "SwiftUI",
                    license: "Apple EULA",
                    url: "https://www.apple.com/legal/sla/"
                )

                Text("Thank you to all open source contributors!")
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.textSecondary)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(MinimalDesign.Colors.background)
        .navigationTitle("Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicenseSection: View {
    let name: String
    let license: String
    let url: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(MinimalDesign.Colors.text)

            Text(license)
                .font(.system(size: 14))
                .foregroundColor(MinimalDesign.Colors.textSecondary)

            Link(url, destination: URL(string: url)!)
                .font(.system(size: 13))
                .foregroundColor(MinimalDesign.Colors.accent)
        }
        .padding()
        .background(MinimalDesign.Colors.secondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Generic Placeholder View
struct PlaceholderView: View {
    let icon: String
    let title: String
    let description: String
    let features: [String]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon and Title
                VStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundColor(MinimalDesign.Colors.accent)

                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    Text(description)
                        .font(.system(size: 15))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 32)

                // Features List
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(MinimalDesign.Colors.accent)
                                .font(.system(size: 16))

                            Text(feature)
                                .font(.system(size: 15))
                                .foregroundColor(MinimalDesign.Colors.text)
                        }
                    }
                }
                .padding(.horizontal, 32)

                // Coming Soon Badge
                Text("Coming Soon")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(MinimalDesign.Colors.accent)
                    .cornerRadius(20)
                    .padding(.top, 16)
            }
        }
        .background(MinimalDesign.Colors.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HelpCenterView()
    }
}
