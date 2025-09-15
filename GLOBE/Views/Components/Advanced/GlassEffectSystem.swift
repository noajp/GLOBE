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

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // Use native glass effect for iOS 26+
            content
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
                .modifier(NativeGlassEffect(id: id, namespace: namespace))
        } else {
            // Fallback for older iOS versions
            content
                .modifier(LegacyGlassEffect())
        }
    }
}

// MARK: - Native Glass Effect (iOS 26+)
@available(iOS 26.0, *)
struct NativeGlassEffect: ViewModifier {
    let id: String?
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let id = id, let namespace = namespace {
            content
                .glassEffect()
                .glassEffectID(id, in: namespace)
        } else {
            content
                .glassEffect()
        }
    }
}

// MARK: - Legacy Glass Effect (iOS 25 and below)
struct LegacyGlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.3),
                                        .white.opacity(0.1),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - View Extensions
extension View {
    func glassContainer() -> some View {
        GlassEffectContainer {
            self
        }
    }

    func coordinatedGlassEffect(id: String) -> some View {
        modifier(CoordinatedGlassModifier(id: id))
    }
}

// MARK: - Coordinated Glass Modifier
struct CoordinatedGlassModifier: ViewModifier {
    let id: String
    @Environment(\.glassNamespace) private var namespace

    func body(content: Content) -> some View {
        content
            .modifier(GlassEffectModifier(id: id, namespace: namespace))
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
                .coordinatedGlassEffect(id: id)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
    }
}
