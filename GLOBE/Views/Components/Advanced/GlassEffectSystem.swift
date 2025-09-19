//======================================================================
// MARK: - GlassEffectSystem.swift
// Purpose: iOS 26 native glass effect system with coordinated elements
// Path: GLOBE/Views/Components/Advanced/GlassEffectSystem.swift
//======================================================================

import SwiftUI

// MARK: - Glass Effect Container
struct GlassEffectContainer<Content: View>: View {
    let content: Content
    @Namespace private var glassNamespace

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environment(\.glassNamespace, glassNamespace)
    }
}

// MARK: - Glass Namespace Environment
private struct GlassNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var glassNamespace: Namespace.ID? {
        get { self[GlassNamespaceKey.self] }
        set { self[GlassNamespaceKey.self] = newValue }
    }
}

// MARK: - Glass Effect View Modifier
struct GlassEffectModifier: ViewModifier {
    let id: String?
    let namespace: Namespace.ID?
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // Use native glass effect for iOS 26+
            content
                .modifier(NativeGlassEffect(id: id, namespace: namespace, cornerRadius: cornerRadius))
        } else {
            // Fallback for older iOS versions
            content
                .modifier(LegacyGlassEffect(cornerRadius: cornerRadius))
        }
    }
}

// MARK: - Native Glass Effect (iOS 26+)
@available(iOS 26.0, *)
struct NativeGlassEffect: ViewModifier {
    let id: String?
    let namespace: Namespace.ID?
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if let id = id, let namespace = namespace {
            content
                .glassEffect(.clear.interactive())
                .glassEffectID(id, in: namespace)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content
                .glassEffect(.clear.interactive())
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

// MARK: - Legacy Glass Effect (iOS 25 and below)
struct LegacyGlassEffect: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.08)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.08),
                                        .white.opacity(0.03),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Glass Variation Enum
enum GlassVariation {
    case regular
    case clear
}

// MARK: - View Extensions
extension View {
    func glassContainer() -> some View {
        GlassEffectContainer {
            self
        }
    }

    func coordinatedGlassEffect(id: String, cornerRadius: CGFloat = 16) -> some View {
        modifier(CoordinatedGlassModifier(id: id, cornerRadius: cornerRadius))
    }

    // Standard glassEffect modifier based on Liquid Glass documentation
    func glassEffect(_ variation: GlassVariation, in shape: some Shape) -> some View {
        self
            .background {
                ZStack {
                    // Ultra thin material base - very transparent
                    shape
                        .fill(.ultraThinMaterial)
                        .opacity(variation == .regular ? 0.08 : 0.05)

                    // Glass shine gradient
                    shape
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(0.5), location: 0),
                                    .init(color: .white.opacity(0.2), location: 0.3),
                                    .init(color: .clear, location: 0.7),
                                    .init(color: .black.opacity(0.05), location: 1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(BlendMode.plusLighter)

                    // Specular highlight at top
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: 0.3)
                            )
                        )
                        .blendMode(BlendMode.screen)
                }
            }
            .overlay {
                // Strong edge highlight for glass feel
                shape
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white.opacity(0.8), location: 0),
                                .init(color: .white.opacity(0.4), location: 0.5),
                                .init(color: .white.opacity(0.1), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .blendMode(BlendMode.plusLighter)
            }
            .overlay {
                // Inner glow
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        ),
                        lineWidth: 0.5
                    )
                    .blur(radius: 0.5)
                    .blendMode(BlendMode.screen)
            }
    }
}

// MARK: - Coordinated Glass Modifier
struct CoordinatedGlassModifier: ViewModifier {
    let id: String
    let cornerRadius: CGFloat
    @Environment(\.glassNamespace) private var namespace

    func body(content: Content) -> some View {
        content
            .modifier(GlassEffectModifier(id: id, namespace: namespace, cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    let id: String?

    init(id: String? = nil) {
        self.id = id
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .coordinatedGlassEffect(id: id ?? "button")
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Glass Circle Button
struct GlassCircleButton<Content: View>: View {
    let id: String
    let size: CGFloat
    let action: () -> Void
    let content: Content

    init(
        id: String,
        size: CGFloat = 60,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id
        self.size = size
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(width: size, height: size)
                .contentShape(Circle())
                .coordinatedGlassEffect(id: id, cornerRadius: size / 2)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Glass Rectangle Button
struct GlassRectangleButton<Content: View>: View {
    let id: String
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void
    let content: Content

    init(
        id: String,
        width: CGFloat = 60,
        height: CGFloat = 60,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(width: width, height: height)
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .coordinatedGlassEffect(id: id, cornerRadius: 12)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}
