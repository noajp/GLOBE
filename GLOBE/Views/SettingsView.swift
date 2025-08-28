//======================================================================
// MARK: - SettingsView.swift
// Purpose: App settings and preferences interface
// Path: GLOBE/Views/SettingsView.swift
//======================================================================
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var showDebugLogs = false
    
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
                    
                    // App Section
                    VStack(alignment: .leading, spacing: MinimalDesign.Spacing.md) {
                        Text("App")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.primary)
                        
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
                            do {
                                try await authManager.signOut()
                            } catch {
                                print("❌ サインアウトエラー: \(error.localizedDescription)")
                                // エラーログを記録
                                SecureLogger.shared.error("Sign out failed in Settings", file: #file, function: #function, line: #line)
                            }
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
            DebugLogView()
        }
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