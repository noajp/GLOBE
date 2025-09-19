//======================================================================
// MARK: - LiquidGlassCard.swift
// Purpose: Reusable Liquid Glass styled container for cards and dialogs
// Path: GLOBE/Views/Components/Advanced/LiquidGlassCard.swift
//======================================================================

import SwiftUI

struct LiquidGlassCard<Content: View>: View {
    let id: String
    var cornerRadius: CGFloat
    var tint: Color
    var strokeColor: Color
    var highlightColor: Color
    var contentPadding: EdgeInsets
    var contentBackdropOpacity: Double
    var shadowColor: Color
    var shadowRadius: CGFloat
    var shadowOffsetY: CGFloat
    let content: Content

    init(
        id: String,
        cornerRadius: CGFloat = 18,
        tint: Color = Color.white.opacity(0.12),
        strokeColor: Color = Color.white.opacity(0.32),
        highlightColor: Color = Color.white.opacity(0.75),
        contentPadding: EdgeInsets = EdgeInsets(),
        contentBackdropOpacity: Double = 0.18,
        shadowColor: Color = .clear,
        shadowRadius: CGFloat = 0,
        shadowOffsetY: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.strokeColor = strokeColor
        self.highlightColor = highlightColor
        self.contentPadding = contentPadding
        self.contentBackdropOpacity = contentBackdropOpacity
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffsetY = shadowOffsetY
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        GlassEffectContainer {
            ZStack(alignment: .topLeading) {
                shape
                    .fill(.clear)
                    .background(.ultraThinMaterial)
                    .overlay(
                        shape
                            .fill(tint)
                    )
                    .overlay(
                        shape
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        highlightColor,
                                        strokeColor,
                                        strokeColor.opacity(0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.1
                            )
                    )
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                            .blur(radius: 0.6)
                            .blendMode(.plusLighter)
                    )

                content
                    .padding(contentPadding)
                    .background(
                        RoundedRectangle(cornerRadius: max(cornerRadius - 14, 6), style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: max(cornerRadius - 14, 6), style: .continuous)
                                    .fill(Color.black.opacity(contentBackdropOpacity))
                            )
                            .compositingGroup()
                            .blur(radius: contentBackdropOpacity > 0 ? 12 : 0)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: max(cornerRadius - 14, 6), style: .continuous))
            }
            .clipShape(shape)
            .coordinatedGlassEffect(id: id, cornerRadius: cornerRadius)
            .contentShape(shape)
        }
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffsetY)
    }
}
