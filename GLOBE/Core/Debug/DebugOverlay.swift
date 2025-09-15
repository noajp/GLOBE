//======================================================================
// MARK: - DebugOverlay.swift
// Purpose: Lightweight debug overlay modifier for development builds
// Path: GLOBE/Core/Debug/DebugOverlay.swift
//======================================================================

import SwiftUI

#if DEBUG
extension View {
    func debugOverlay() -> some View {
        self.overlay(
            VStack {
                HStack {
                    Text("DEBUG")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(4)
                    Spacer()
                }
                Spacer()
            }
            .padding(8)
        )
    }
}
#else
extension View {
    func debugOverlay() -> some View { self }
}
#endif

