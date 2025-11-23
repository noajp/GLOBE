//======================================================================
// MARK: - ProfilePopupView.swift
// Purpose: Full-screen profile view with black background matching ProfileView
// Path: GLOBE/Views/Profile/ProfilePopupView.swift
//======================================================================

import SwiftUI

struct ProfilePopupView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Background layer (solid black #121212)
            Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0)
                .ignoresSafeArea()
                .onTapGesture {
                    // Close on background tap
                    isPresented = false
                }

            // Profile view content
            VStack(spacing: 0) {
                // Back button at top left with glass effect
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black.opacity(0.85))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(.white.opacity(0.95))
                                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                            )
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.55),
                                                Color.black.opacity(0.18)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.9
                                    )
                            )
                    }
                    .shadow(color: Color.black.opacity(0.22), radius: 6, x: 0, y: 4)
                    .padding(.leading, 16)
                    .padding(.top, 16)

                    Spacer()
                }

                // Embed TabBarProfileView
                TabBarProfileView()
            }
        }
    }
}
