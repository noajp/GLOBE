//======================================================================
// MARK: - NotificationsView.swift
// Purpose: Notifications display interface
// Path: GLOBE/Views/NotificationsView.swift
//======================================================================
import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MinimalDesign.Colors.primary)
                }
                
                Text("NOTIFICATIONS")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .padding(.leading, 8)
                
                Spacer()
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            .padding(.vertical, MinimalDesign.Spacing.xs)
            
            // Content
            ScrollView {
                VStack(spacing: MinimalDesign.Spacing.sm) {
                    // Mock notifications
                    ForEach(0..<5, id: \.self) { index in
                        NotificationRow(
                            title: "New Follower",
                            message: "Someone started following you",
                            time: "\(index + 1)h ago"
                        )
                    }
                }
                .padding(.horizontal, MinimalDesign.Spacing.md)
                .padding(.top, MinimalDesign.Spacing.md)
            }
        }
        .background(MinimalDesign.Colors.background)
        .navigationBarHidden(true)
    }
}

// MARK: - Custom Style Notification Row
struct NotificationRow: View {
    let title: String
    let message: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(MinimalDesign.Colors.accentRed)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MinimalDesign.Colors.primary)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 12))
                .foregroundColor(MinimalDesign.Colors.tertiary)
        }
        .padding(MinimalDesign.Spacing.md)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}