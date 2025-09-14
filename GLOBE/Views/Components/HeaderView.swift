//======================================================================
// MARK: - HeaderView.swift
// Purpose: Main app header with title and profile button
// Path: GLOBE/Views/Components/HeaderView.swift
//======================================================================

import SwiftUI

struct HeaderView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @Binding var showingAuth: Bool
    @Binding var showingProfile: Bool

    var body: some View {
        VStack(spacing: 0) {
            // App title bar
            HStack {
                Text("GLOBE")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                // Profile button
                Button(action: {
                    if authManager.isAuthenticated {
                        showingProfile = true
                    } else {
                        showingAuth = true
                    }
                }) {
                    Image(systemName: authManager.isAuthenticated ? "person.circle.fill" : "person.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 15)
        }
        .background(MinimalDesign.Colors.background)
    }
}

#Preview {
    HeaderView(
        showingAuth: .constant(false),
        showingProfile: .constant(false)
    )
    .background(.black)
}