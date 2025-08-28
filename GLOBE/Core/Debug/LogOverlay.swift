//======================================================================
// MARK: - LogOverlay.swift
// Purpose: Floating log overlay for real-time debug viewing
// Path: GLOBE/Core/Debug/LogOverlay.swift
//======================================================================
import SwiftUI

/// フローティングログオーバーレイ
struct LogOverlay: View {
    @ObservedObject private var logger = DebugLogger.shared
    @State private var isExpanded = false
    @State private var dragOffset = CGSize.zero
    @State private var position = CGPoint(x: 300, y: 100) // 初期位置を固定値に
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if isExpanded {
                    expandedView(geometry: geometry)
                } else {
                    floatingButton(geometry: geometry)
                }
            }
        }
    }
    
    private func floatingButton(geometry: GeometryProxy) -> some View {
        Button(action: { isExpanded = true }) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 50, height: 50)
                
                VStack(spacing: 2) {
                    Text("LOG")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(logger.logs.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let newX = max(25, min(geometry.size.width - 25, position.x + value.translation.width))
                    let newY = max(50, min(geometry.size.height - 50, position.y + value.translation.height))
                    position = CGPoint(x: newX, y: newY)
                    dragOffset = .zero
                }
        )
    }
    
    private func expandedView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("Debug Logs")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Clear") {
                    logger.clearLogs()
                    ConsoleLogger.shared.forceLog("Logs cleared from overlay")
                }
                .foregroundColor(.orange)
                
                Button("Test") {
                    logger.generateTestLogs()
                    ConsoleLogger.shared.forceLog("Test logs generated from overlay")
                }
                .foregroundColor(.green)
                
                Button("✕") {
                    isExpanded = false
                }
                .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            
            // ログリスト
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(logger.logs.suffix(50)) { entry in
                        LogEntryMini(entry: entry)
                    }
                }
                .padding(.horizontal, 8)
            }
            .background(Color.black.opacity(0.6))
            .frame(maxHeight: 400)
        }
        .frame(width: geometry.size.width - 40)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
}

/// ミニログエントリ
struct LogEntryMini: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.level.rawValue)
                .font(.system(size: 12))
            
            Text(entry.formattedTimestamp)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.message)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let details = entry.details, !details.isEmpty {
                    Text(details.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.yellow)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

/// デバッグオーバーレイを表示するViewModifier
struct DebugOverlayModifier: ViewModifier {
    @State private var showOverlay = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    #if DEBUG
                    if showOverlay {
                        LogOverlay()
                    }
                    #endif
                }
            )
            .onShake {
                #if DEBUG
                showOverlay.toggle()
                ConsoleLogger.shared.forceLog("Debug overlay toggled by shake: \(showOverlay)")
                #endif
            }
    }
}

extension View {
    func debugOverlay() -> some View {
        modifier(DebugOverlayModifier())
    }
}

/// シェイクジェスチャーの検出
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

struct ShakeViewModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeViewModifier(action: action))
    }
}