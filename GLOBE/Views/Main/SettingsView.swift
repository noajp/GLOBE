//======================================================================
// MARK: - SettingsView.swift
// Purpose: App settings and preferences interface
// Path: GLOBE/Views/SettingsView.swift
//======================================================================
import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Binding var showingAuth: Bool
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        ScrollView {
            VStack(spacing: MinimalDesign.Spacing.lg) {
                // Account Section
                if authManager.isAuthenticated {
                    SectionHeader(title: "Account")
                    VStack(alignment: .leading, spacing: 0) {
                        NavigationLink(destination: AccountSettingsView()) {
                            SettingsRow(icon: "person.circle", title: "Account Settings")
                        }
                        Divider().padding(.leading, 48)

                        NavigationLink(destination: DataManagementView()) {
                            SettingsRow(icon: "externaldrive", title: "Data Management")
                        }
                    }
                }

                // Privacy & Safety Section
                SectionHeader(title: "Privacy & Safety")
                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(icon: "lock.circle", title: "Privacy Settings")
                    }
                    Divider().padding(.leading, 48)

                    NavigationLink(destination: LocationSettingsView()) {
                        SettingsRow(icon: "location.circle", title: "Location Settings")
                    }
                    Divider().padding(.leading, 48)

                    NavigationLink(destination: BlockedUsersView()) {
                        SettingsRow(icon: "hand.raised.circle", title: "Blocked Users")
                    }
                }

                // Legal Section
                SectionHeader(title: "Legal")
                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink(destination: TermsOfServiceView()) {
                        SettingsRow(icon: "doc.text", title: "Terms of Service")
                    }
                    Divider().padding(.leading, 48)

                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsRow(icon: "hand.raised.circle", title: "Privacy Policy")
                    }
                    Divider().padding(.leading, 48)

                    NavigationLink(destination: CommunityGuidelinesView()) {
                        SettingsRow(icon: "person.3", title: "Community Guidelines")
                    }
                }

                // Support Section
                SectionHeader(title: "Support")
                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink(destination: HelpCenterView()) {
                        SettingsRow(icon: "questionmark.circle", title: "Help Center")
                    }
                    Divider().padding(.leading, 48)

                    NavigationLink(destination: ContactSupportView()) {
                        SettingsRow(icon: "envelope", title: "Contact Support")
                    }
                    Divider().padding(.leading, 48)

                    NavigationLink(destination: ReportProblemView()) {
                        SettingsRow(icon: "exclamationmark.bubble", title: "Report a Problem")
                    }
                }

                // About Section
                SectionHeader(title: "About")
                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(icon: "info.circle", title: "About GLOBE")
                    }
                    Divider().padding(.leading, 48)

                    NavigationLink(destination: LicensesView()) {
                        SettingsRow(icon: "doc.plaintext", title: "Open Source Licenses")
                    }
                }

                // Sign In / Sign Out
                if authManager.isAuthenticated {
                    Button(action: {
                        Task { @MainActor in
                            await authManager.signOut()
                            isPresented = false
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
                } else {
                    Button(action: {
                        isPresented = false
                        // 少し遅延させて設定画面が閉じた後に認証画面を表示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingAuth = true
                        }
                    }) {
                        Text("Sign In")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MinimalDesign.Spacing.md)
                            .background(MinimalDesign.Colors.accentRed)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, MinimalDesign.Spacing.lg)
                }
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
            .padding(.top, MinimalDesign.Spacing.md)
        }
        .background(MinimalDesign.Colors.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(MinimalDesign.Colors.textSecondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MinimalDesign.Spacing.md)
            .padding(.top, MinimalDesign.Spacing.md)
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: MinimalDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(MinimalDesign.Colors.text)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(MinimalDesign.Colors.text)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(MinimalDesign.Colors.textTertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, MinimalDesign.Spacing.md)
        .background(MinimalDesign.Colors.background)
    }
}
