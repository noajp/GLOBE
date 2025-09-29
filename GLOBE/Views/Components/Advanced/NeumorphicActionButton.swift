//======================================================================
// MARK: - NeumorphicActionButton.swift
// Purpose: Capsule-shaped button with neumorphic styling for primary actions
// Path: GLOBE/Views/Components/Advanced/NeumorphicActionButton.swift
//======================================================================

import SwiftUI

// MARK: - Supporting Types
enum NeumorphicActionButtonArrowPosition {
    case leading
    case trailing
}

enum NeumorphicActionButtonSize {
    case regular
    case compact
}

/// ニューモーフィック風のカプセルボタン。
///
/// 利用例:
/// ```swift
/// NeumorphicActionButton(
///     title: "POST",
///     isEnabled: canPost,
///     arrowPosition: .leading,
///     size: .compact,
///     arrowRotationDegrees: showOptions ? 90 : 0,
///     secondaryActionAccessibilityLabel: "プライバシー設定",
///     secondaryAction: toggleOptions
/// ) {
///     createPost()
/// }
/// ```
/// - Parameters:
///   - title: ボタンに表示するテキスト
///   - isEnabled: 有効状態を制御するフラグ
///   - arrowPosition: 矢印アイコンを配置する位置（左または右）
///   - size: ボタン全体のスケール（`.regular` または `.compact`）
///   - arrowRotationDegrees: 矢印アイコンの回転角度（例: 90度で展開状態を表現）
///   - secondaryActionAccessibilityLabel: 副アクションのアクセシビリティラベル（任意）
///   - action: タップ時に実行する主アクション
///   - secondaryAction: 矢印領域のみで呼び出す副アクション（任意）
struct NeumorphicActionButton: View {
    // MARK: - Properties
    let title: String
    var isEnabled: Bool
    var arrowPosition: NeumorphicActionButtonArrowPosition
    var size: NeumorphicActionButtonSize
    var arrowRotationDegrees: Double
    var secondaryActionAccessibilityLabel: String?
    var action: () -> Void
    var secondaryAction: (() -> Void)?

    init(
        title: String,
        isEnabled: Bool = true,
        arrowPosition: NeumorphicActionButtonArrowPosition = .trailing,
        size: NeumorphicActionButtonSize = .regular,
        arrowRotationDegrees: Double = 0,
        secondaryActionAccessibilityLabel: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.arrowPosition = arrowPosition
        self.size = size
        self.arrowRotationDegrees = arrowRotationDegrees
        self.secondaryActionAccessibilityLabel = secondaryActionAccessibilityLabel
        self.secondaryAction = secondaryAction
        self.action = action
    }

    // MARK: - Body
    var body: some View {
        Button(action: action) {
            decoratedButtonContent
        }
        .buttonStyle(.plain) // 既定のハイライトを無効化して質感を保つ
        .disabled(!isEnabled)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(isEnabled ? "タップしてアクションを実行" : "入力が完了すると有効になります"))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Subviews
    @ViewBuilder
    private var decoratedButtonContent: some View {
        if let secondaryAction {
            buttonContent
                .overlay(alignment: overlayAlignment) {
                    arrowTapOverlay(action: secondaryAction)
                }
        } else {
            buttonContent
        }
    }

    private var buttonContent: some View {
        HStack(spacing: contentSpacing) {
            if arrowPosition == .leading {
                arrowCircle
            }

            Text(title)
                .font(titleFont)
                .foregroundColor(titleColor)
                .padding(.leading, 4)

            Spacer(minLength: 0)

            if arrowPosition == .trailing {
                arrowCircle
            }
        }
        .padding(.vertical, verticalPadding)
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .background(capsuleBackground)
        .compositingGroup()
        .shadow(color: Color.black.opacity(isEnabled ? 0.18 : 0.05), radius: shadowRadius, x: 0, y: shadowOffsetY)
        .shadow(color: Color.white.opacity(isEnabled ? 0.5 : 0.2), radius: highlightShadowRadius, x: -2, y: -2)
        .opacity(isEnabled ? 1 : 0.65)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }

    // MARK: - Overlay for Secondary Action
    private func arrowTapOverlay(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Color.clear
        }
        .buttonStyle(.plain)
        .frame(width: overlayWidth, height: overlayHeight)
        .contentShape(Circle())
        .offset(overlayOffset)
        .accessibilityLabel(Text(secondaryActionAccessibilityLabel ?? "\(title)のオプションを開く"))
    }

    private var arrowCircle: some View {
        Circle()
            .fill(arrowBackground)
            .overlay(arrowOverlay)
            .frame(width: circleSize, height: circleSize)
            .shadow(color: Color.black.opacity(isEnabled ? 0.25 : 0.1), radius: arrowShadowRadius, x: 0, y: arrowShadowOffsetY)
            .allowsHitTesting(false) // タップ判定はオーバーレイ側に委譲
    }

    // MARK: - Computed Views
    private var capsuleBackground: some View {
        Capsule()
            .fill(backgroundGradient)
            .overlay(
                Capsule()
                    .stroke(borderGradient, lineWidth: 1)
                    .blendMode(.overlay)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                    .blur(radius: 0.6)
                    .offset(y: -1)
                    .blendMode(.screen)
            )
    }

    private var arrowOverlay: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            .rotationEffect(.degrees(arrowRotationDegrees))
            .animation(.easeInOut(duration: 0.2), value: arrowRotationDegrees)
    }

    // MARK: - Style Helpers
    private var overlayAlignment: Alignment {
        arrowPosition == .leading ? .leading : .trailing
    }

    private var contentSpacing: CGFloat {
        switch size {
        case .regular: return 14
        case .compact: return 10
        }
    }

    private var circleSize: CGFloat {
        switch size {
        case .regular: return 36
        case .compact: return 30
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .regular: return 10
        case .compact: return 8
        }
    }

    private var leadingPadding: CGFloat {
        switch size {
        case .regular: return 22
        case .compact: return 16
        }
    }

    private var trailingPadding: CGFloat {
        switch size {
        case .regular: return 8
        case .compact: return 6
        }
    }

    private var overlayWidth: CGFloat {
        circleSize + 16
    }

    private var overlayHeight: CGFloat {
        circleSize + verticalPadding * 2
    }

    private var overlayInsets: EdgeInsets {
        if arrowPosition == .leading {
            return EdgeInsets(top: 0, leading: leadingPadding - 4, bottom: 0, trailing: 0)
        } else {
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: trailingPadding - 2)
        }
    }

    private var backgroundGradient: LinearGradient {
        let colors: [Color] = isEnabled
            ? [Color.white.opacity(0.95), Color.white.opacity(0.75)]
            : [Color.white.opacity(0.55), Color.white.opacity(0.4)]

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(isEnabled ? 0.9 : 0.4),
                Color.black.opacity(isEnabled ? 0.15 : 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var arrowBackground: LinearGradient {
        let baseOpacity: Double = isEnabled ? 0.95 : 0.5
        return LinearGradient(
            colors: [Color.black.opacity(baseOpacity), Color.black.opacity(isEnabled ? 0.7 : 0.45)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var titleColor: Color {
        isEnabled ? Color.black.opacity(0.78) : Color.black.opacity(0.35)
    }

    private var titleFont: Font {
        switch size {
        case .regular: return .system(size: 16, weight: .semibold)
        case .compact: return .system(size: 14, weight: .semibold)
        }
    }

    private var shadowRadius: CGFloat {
        switch size {
        case .regular: return isEnabled ? 9 : 4
        case .compact: return isEnabled ? 6 : 3
        }
    }

    private var shadowOffsetY: CGFloat {
        switch size {
        case .regular: return isEnabled ? 8 : 4
        case .compact: return isEnabled ? 6 : 3
        }
    }

    private var highlightShadowRadius: CGFloat {
        size == .regular ? 3 : 2
    }

    private var arrowShadowRadius: CGFloat {
        size == .regular ? 6 : 4
    }

    private var arrowShadowOffsetY: CGFloat {
        size == .regular ? 4 : 3
    }
}

// MARK: - Preview
#if DEBUG
struct NeumorphicActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            NeumorphicActionButton(title: "POST", isEnabled: true) {}
            NeumorphicActionButton(title: "POST", isEnabled: false) {}
            NeumorphicActionButton(
                title: "POST",
                isEnabled: true,
                arrowPosition: .leading,
                size: .compact,
                arrowRotationDegrees: 90,
                secondaryActionAccessibilityLabel: "プライバシー設定",
                secondaryAction: {}
            ) {}
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
#endif
