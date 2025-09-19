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

    // Interactive liquid glass effect for post cards
    func liquidGlassEffect(cornerRadius: CGFloat = 14) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Liquid Glass Modifier (Interactive)
struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .background(
                ZStack {
                    // Base glass material - responds to interaction
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(isPressed ? 0.15 : 0.08)
                        .animation(.easeInOut(duration: 0.2), value: isPressed)

                    // Dynamic top glossy highlight - intensifies on press
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(isPressed ? 0.5 : 0.3),
                                    .white.opacity(isPressed ? 0.2 : 0.1),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: 0.3)
                            )
                        )
                        .blendMode(.plusLighter)
                        .animation(.easeInOut(duration: 0.15), value: isPressed)

                    // Adaptive diagonal shine - shifts with interaction
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(isPressed ? 0.3 : 0.2),
                                    .clear,
                                    .clear,
                                    .white.opacity(isPressed ? 0.1 : 0.05)
                                ],
                                startPoint: isPressed ? .topTrailing : .topLeading,
                                endPoint: isPressed ? .bottomLeading : .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                        .animation(.easeInOut(duration: 0.2), value: isPressed)

                    // Dynamic edge highlight - gets brighter on press
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(isPressed ? 0.6 : 0.4),
                                    .white.opacity(isPressed ? 0.4 : 0.2),
                                    .white.opacity(isPressed ? 0.1 : 0.05),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isPressed ? 1.5 : 1
                        )
                        .blendMode(.plusLighter)
                        .animation(.easeInOut(duration: 0.15), value: isPressed)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(isPressed ? 0.12 : 0.08), radius: isPressed ? 15 : 10, x: 0, y: isPressed ? 8 : 5)
            .shadow(color: .white.opacity(isPressed ? 0.2 : 0.1), radius: isPressed ? 4 : 2, x: 0, y: -1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scale)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .onTapGesture {
                // Liquid ripple effect on tap
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    scale = 0.98
                }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) {
                    scale = 1.0
                }
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
                isPressed = isPressing
                if isPressing {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        scale = 0.95
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 1.0
                    }
                }
            }, perform: {})
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
