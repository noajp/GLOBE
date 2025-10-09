//======================================================================
// MARK: - ClusterPin.swift
// Purpose: Cluster pin for displaying multiple posts at far zoom levels
// Path: GLOBE/Views/Components/ClusterPin.swift
//======================================================================

import SwiftUI

struct ClusterPin: View {
    let postCount: Int
    let onTap: () -> Void

    private let diameter: CGFloat = 60

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // White circle background
                Circle()
                    .fill(Color.white)
                    .frame(width: diameter, height: diameter)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                // Post count in black
                Text("\(postCount)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            ClusterPin(postCount: 5) {}
            ClusterPin(postCount: 23) {}
            ClusterPin(postCount: 142) {}
        }
    }
}
