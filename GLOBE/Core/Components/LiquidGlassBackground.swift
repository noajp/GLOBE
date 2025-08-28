//======================================================================
// MARK: - LiquidGlassBackground.swift
// Purpose: Apple's official Liquid Glass background effect component
// Path: GLOBE/Core/Components/LiquidGlassBackground.swift
//======================================================================
import SwiftUI

// MARK: - Liquid Glass Background
struct LiquidGlassBackground: View {
    var body: some View {
        // Completely transparent background
        Rectangle()
            .fill(Color.clear)
    }
}

// MARK: - Floating Glass Button Style
struct FloatingGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .modifier(LiquidGlassEffectModifier(isPressed: configuration.isPressed))
    }
}

// MARK: - Liquid Glass Effect Modifier
struct LiquidGlassEffectModifier: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(isPressed ? 0.3 : 0.15)
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ]),
                                    center: .topLeading,
                                    startRadius: 5,
                                    endRadius: 30
                                )
                            )
                    )
            )
    }
}

#Preview {
    LiquidGlassBackground()
        .frame(height: 100)
}