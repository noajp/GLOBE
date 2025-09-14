//======================================================================
// MARK: - AuthLiquidGlassBackground.swift
// Purpose: Enhanced liquid glass background with Earth view for auth screens
// Path: GLOBE/Core/Components/AuthLiquidGlassBackground.swift
//======================================================================
import SwiftUI

// MARK: - Auth-specific Liquid Glass Background with Earth View
struct AuthLiquidGlassBackground: View {
    @State private var animationOffset: CGFloat = 0
    @State private var secondaryOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Earth/Space background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                    .init(color: Color(red: 0.1, green: 0.15, blue: 0.3), location: 0.3),
                    .init(color: Color(red: 0.2, green: 0.3, blue: 0.5), location: 0.6),
                    .init(color: Color(red: 0.3, green: 0.4, blue: 0.7), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Earth-like curved gradients
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.6, blue: 0.8).opacity(0.3),
                            Color(red: 0.1, green: 0.3, blue: 0.6).opacity(0.2),
                            Color.clear
                        ]),
                        center: .bottomTrailing,
                        startRadius: 50,
                        endRadius: 400
                    )
                )
                .scaleEffect(1.5)
                .offset(x: 100, y: 200)
                .offset(x: animationOffset * 0.3)
            
            // Secondary earth gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.3, green: 0.7, blue: 0.4).opacity(0.2),
                            Color(red: 0.2, green: 0.5, blue: 0.3).opacity(0.15),
                            Color.clear
                        ]),
                        center: .topLeading,
                        startRadius: 30,
                        endRadius: 300
                    )
                )
                .scaleEffect(1.2)
                .offset(x: -80, y: -150)
                .offset(x: secondaryOffset * 0.2)
            
            // Atmospheric glow effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.1),
                            Color.cyan.opacity(0.05),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 100,
                        endRadius: 500
                    )
                )
                .scaleEffect(2.0)
                .offset(y: animationOffset * 0.1)
            
            // Enhanced blur overlay for login content visibility
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
                .blur(radius: 1.5)
            
            // Additional blur layer for better text readability
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .blur(radius: 0.5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animationOffset = 50
            }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                secondaryOffset = -30
            }
        }
    }
}

// MARK: - Enhanced Glass Effect for Auth Screens
struct AuthLiquidGlassEffectModifier: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(0.9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.3),
                                        .white.opacity(0.1),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: .black.opacity(0.2),
                radius: isPressed ? 8 : 12,
                x: 0,
                y: isPressed ? 4 : 8
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
    }
}