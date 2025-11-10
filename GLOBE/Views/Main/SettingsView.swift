//======================================================================
// MARK: - SettingsView.swift
// Purpose: App settings and preferences interface
// Path: GLOBE/Views/SettingsView.swift
//======================================================================
import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Binding var showingAuth: Bool
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var appSettings = AppSettings.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: MinimalDesign.Spacing.lg) {
                // Privacy Section
                VStack(alignment: .leading, spacing: MinimalDesign.Spacing.md) {
                    NavigationLink(destination: PrivacySettingsView()) {
                        HStack(spacing: MinimalDesign.Spacing.md) {
                            Image(systemName: "lock.circle")
                                .font(.system(size: 20))
                                .foregroundColor(MinimalDesign.Colors.primary)
                                .frame(width: 24)

                            Text("Privacy")
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

                // App Section
                VStack(alignment: .leading, spacing: MinimalDesign.Spacing.md) {
                    SettingsItem(
                        icon: "questionmark.circle",
                        title: "Help",
                        action: {}
                    )
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
