//======================================================================
// MARK: - DebugLogger.swift
// Purpose: Debug logging system for development and troubleshooting
// Path: GLOBE/Core/Debug/DebugLogger.swift
//======================================================================
import Foundation
import SwiftUI
import Combine

// MARK: - Extensions

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}

/// デバッグ用ログレベル
enum LogLevel: String, CaseIterable {
    case debug = "🔍"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "❌"
    case success = "✅"
    case auth = "🔐"
    case network = "🌐"
    case database = "🗄️"
}

/// ログエントリ
struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String
    let details: [String: Any]?
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
    
    var fullMessage: String {
        var components = ["\(level.rawValue)", "[\(formattedTimestamp)]", "[\(category)]", message]
        
        if let details = details, !details.isEmpty {
            let detailsString = details.map { "\($0): \($1)" }.joined(separator: ", ")
            components.append("Details: \(detailsString)")
        }
        
        return components.joined(separator: " ")
    }
    
    static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
        lhs.id == rhs.id
    }
}

/// デバッグログマネージャー
@MainActor
final class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    
    @Published var logs: [LogEntry] = []
    @Published var isLoggingEnabled = true
    @Published var maxLogEntries = 1000
    
    private init() {
        // 初期化時に強制ログ出力
        let initMessage = "DebugLogger initialized at \(Date())"
        print("🔥 DIRECT PRINT: \(initMessage)")
        NSLog("🔥 NSLOG: \(initMessage)")
    }
    
    // MARK: - Logging Methods
    
    func log(
        level: LogLevel,
        category: String,
        message: String,
        details: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isLoggingEnabled else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let fullCategory = "\(category)[\(fileName):\(line)]"
        
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: fullCategory,
            message: message,
            details: details
        )
        
        // コンソール出力
        print(entry.fullMessage)
        
        // ログエントリを保存
        logs.append(entry)
        
        // 最大エントリ数を超えた場合、古いエントリを削除
        if logs.count > maxLogEntries {
            logs.removeFirst(logs.count - maxLogEntries)
        }
    }
    
    // MARK: - Convenience Methods
    
    func debug(_ message: String, category: String = "DEBUG", details: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, category: category, message: message, details: details, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "INFO", details: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, category: category, message: message, details: details, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "WARNING", details: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, category: category, message: message, details: details, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: String = "ERROR", details: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, category: category, message: message, details: details, file: file, function: function, line: line)
    }
    
    func success(_ message: String, category: String = "SUCCESS", details: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .success, category: category, message: message, details: details, file: file, function: function, line: line)
    }
    
    func auth(_ message: String, category: String = "AUTH", details: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .auth, category: category, message: message, details: details, file: file, function: function, line: line)
    }
    
    func network(_ message: String, category: String = "NETWORK", details: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .network, category: category, message: message, details: details, file: file, function: function, line: line)
    }
    
    func database(_ message: String, category: String = "DATABASE", details: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .database, category: category, message: message, details: details, file: file, function: function, line: line)
    }
    
    // MARK: - Log Management
    
    func clearLogs() {
        logs.removeAll()
        info("Logs cleared", category: "LOGGER")
    }
    
    func filterLogs(by level: LogLevel) -> [LogEntry] {
        return logs.filter { $0.level == level }
    }
    
    func filterLogs(by category: String) -> [LogEntry] {
        return logs.filter { $0.category.contains(category) }
    }
    
    func exportLogs() -> String {
        return logs.map { $0.fullMessage }.joined(separator: "\n")
    }
    
    // MARK: - Test Methods
    
    /// テスト用のサンプルログを生成
    func generateTestLogs() {
        info("🧪 Test log: App initialized", category: "TEST")
        success("🧪 Test log: Operation successful", category: "TEST")
        warning("🧪 Test log: Warning message", category: "TEST")
        error("🧪 Test log: Error message", category: "TEST")
        auth("🧪 Test log: Authentication event", category: "TEST")
        network("🧪 Test log: Network request", category: "TEST")
        database("🧪 Test log: Database operation", category: "TEST")
        
        // 詳細情報付きテストログ
        info("🧪 Test log with details", category: "TEST", details: [
            "user_id": "test-user-123",
            "action": "test_action",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    /// 強制的にコンソールに出力（デバッグ用）
    func forceConsoleOutput(_ message: String) {
        let timestamp = DateFormatter().apply {
            $0.dateFormat = "HH:mm:ss.SSS"
        }.string(from: Date())
        
        let output = "🔥 FORCE LOG [\(timestamp)] \(message)"
        print(output)
        NSLog(output) // システムログにも出力
    }
}