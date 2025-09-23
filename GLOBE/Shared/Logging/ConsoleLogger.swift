//======================================================================
// MARK: - ConsoleLogger.swift
// Purpose: Lightweight console logger used in development builds
// Path: GLOBE/Core/Logging/ConsoleLogger.swift
//======================================================================

import Foundation

final class ConsoleLogger {
    static let shared = ConsoleLogger()
    private init() {}

    func forceLog(_ message: String) {
        #if DEBUG
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

