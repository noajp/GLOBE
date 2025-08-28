//======================================================================
// MARK: - ConsoleLogger.swift  
// Purpose: Guaranteed console logging for Xcode debugging
// Path: GLOBE/Core/Debug/ConsoleLogger.swift
//======================================================================
import Foundation
import os.log
import UIKit

/// Xcodeコンソールへの確実な出力を保証するロガー
final class ConsoleLogger {
    static let shared = ConsoleLogger()
    
    // OSLogを使用した確実なログ出力
    private let osLog = OSLog(subsystem: "com.globe.app", category: "debug")
    
    private init() {
        // 初期化時に必ず出力される
        forceLog("🔥🔥🔥 ConsoleLogger INITIALIZED 🔥🔥🔥")
        checkLoggingCapabilities()
    }
    
    /// 確実にログを出力する（複数の方法を使用）
    func forceLog(_ message: String, file: String = #file, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let fullMessage = "[\(timestamp)] [\(fileName):\(line)] \(message)"
        
        // 1. 標準のprint
        print("🔥 PRINT: \(fullMessage)")
        
        // 2. NSLog (常にコンソールに出力される)
        NSLog("🔥 NSLOG: %@", fullMessage)
        
        // 3. OSLog (iOS 10+で推奨されるログ出力)
        if #available(iOS 10.0, *) {
            os_log("🔥 OSLOG: %{public}@", log: osLog, type: .info, fullMessage)
        }
        
        // 4. 標準エラー出力
        fputs("🔥 STDERR: \(fullMessage)\n", stderr)
        
        // 5. デバッグ専用出力
        #if DEBUG
        debugPrint("🔥 DEBUG: \(fullMessage)")
        #endif
    }
    
    /// ログ機能の動作確認
    private func checkLoggingCapabilities() {
        forceLog("=== LOGGING CAPABILITY CHECK ===")
        forceLog("iOS Version: \(UIDevice.current.systemVersion)")
        forceLog("Device: \(UIDevice.current.model)")
        forceLog("App Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        
        #if DEBUG
        forceLog("Build Configuration: DEBUG")
        #else
        forceLog("Build Configuration: RELEASE")
        #endif
        
        #if targetEnvironment(simulator)
        forceLog("Environment: iOS Simulator")
        #else
        forceLog("Environment: Physical Device")
        #endif
        
        // 現在時刻
        forceLog("Current Time: \(Date())")
        
        forceLog("=== END CAPABILITY CHECK ===")
    }
    
    /// エラー専用ログ
    func logError(_ message: String, error: Error? = nil, file: String = #file, line: Int = #line) {
        var fullMessage = "❌ ERROR: \(message)"
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
            if let nsError = error as NSError? {
                fullMessage += " | Domain: \(nsError.domain) | Code: \(nsError.code)"
            }
        }
        forceLog(fullMessage, file: file, line: line)
    }
    
    /// 認証専用ログ
    func logAuth(_ message: String, details: [String: Any] = [:], file: String = #file, line: Int = #line) {
        var fullMessage = "🔐 AUTH: \(message)"
        if !details.isEmpty {
            let detailsString = details.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            fullMessage += " | Details: \(detailsString)"
        }
        forceLog(fullMessage, file: file, line: line)
    }
    
    /// ネットワーク専用ログ
    func logNetwork(_ message: String, details: [String: Any] = [:], file: String = #file, line: Int = #line) {
        var fullMessage = "🌐 NETWORK: \(message)"
        if !details.isEmpty {
            let detailsString = details.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            fullMessage += " | Details: \(detailsString)"
        }
        forceLog(fullMessage, file: file, line: line)
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}