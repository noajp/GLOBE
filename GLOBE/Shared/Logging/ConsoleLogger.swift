//======================================================================
// MARK: - ConsoleLogger.swift
// Purpose: Lightweight console logger used in development builds
// Path: GLOBE/Core/Logging/ConsoleLogger.swift
//======================================================================

import Foundation

final class ConsoleLogger {
    static let shared = ConsoleLogger()
    private init() {}

    // 最小ログモード: エラーのみ出力
    private let minimalLogging = true

    func forceLog(_ message: String) {
        #if DEBUG
        guard !minimalLogging else { return }
        print("📝 [Console] \(message)")
        #endif
    }

    func logError(_ message: String, error: Error) {
        #if DEBUG
        print("❌ [Console] \(message): \(error.localizedDescription)")
        #endif
        SecureLogger.shared.error("\(message): \(error.localizedDescription)")
    }
}

