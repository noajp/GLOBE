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
