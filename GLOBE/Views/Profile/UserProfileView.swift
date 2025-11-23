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
    @ObservedObject private var authManager = AuthManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background layer (solid black #121212)
                Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0)
                    .ignoresSafeArea()

                // Embed TabBarProfileView with userId parameter
                // It will handle loading and displaying the profile
                TabBarProfileView(userId: userId)
                    .onAppear {
                        SecureLogger.shared.info("UserProfileView: Displaying profile for userId: \(userId), currentUserId: \(authManager.currentUser?.id ?? "none")")
                    }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
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