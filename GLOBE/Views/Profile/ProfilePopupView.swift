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
                // Close button at top
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }

                // Embed ProfileView
                ProfileView()
            }
        }
    }
}
