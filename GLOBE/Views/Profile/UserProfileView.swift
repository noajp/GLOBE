//======================================================================
// MARK: - UserProfileView.swift
// Purpose: User profile view for displaying other users' information
// Path: GLOBE/Views/UserProfileView.swift
//======================================================================

import SwiftUI
import Supabase

struct UserProfileView: View {
    let userName: String
    let userId: String
    @Binding var isPresented: Bool
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                // Background layer (solid black #121212)
                MinimalDesign.Colors.background
                    .ignoresSafeArea()

                // Embed TabBarProfileView with userId parameter
                // It will handle loading and displaying the profile
                TabBarProfileView(userId: userId)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.text)
                    }
                }
            }
            .toolbarBackground(MinimalDesign.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            SecureLogger.shared.info("UserProfileView: Displaying profile for userId: \(userId), userName: \(userName)")
        }
    }
}

#Preview {
    UserProfileView(
        userName: "John Doe",
        userId: "12345678",
        isPresented: .constant(true)
    )
}