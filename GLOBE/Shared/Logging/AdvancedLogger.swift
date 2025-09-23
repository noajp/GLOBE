//======================================================================
// MARK: - AdvancedLogger.swift
// Purpose: Enhanced logging system with performance monitoring and debug visualization
// Path: GLOBE/Core/Logging/AdvancedLogger.swift
//======================================================================

import Foundation
import os.log
import SwiftUI
import Combine

@MainActor
final class AdvancedLogger: ObservableObject {

    static let shared = AdvancedLogger()

    // MARK: - Published Properties for Debug UI
    @Published var recentLogs: [LogEntry] = []
    @Published var performanceMetrics: [PerformanceMetric] = []
    @Published var isDebugViewVisible = false

    // MARK: - Configuration
    private struct LoggingConfig {
        static let maxRecentLogs = 1000
        static let maxPerformanceMetrics = 500
        static let logRetentionDays = 7
        static let enableFileLogging = false // TEMPORARILY DISABLED FOR CRASH DEBUGGING
        static let enablePerformanceTracking = false // TEMPORARILY DISABLED FOR CRASH DEBUGGING
    }

    // MARK: - Core Properties
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.globe"
    private let fileManager = FileManager.default
    private let logQueue = DispatchQueue(label: "com.globe.logging", qos: .utility)
    private var logFileHandle: FileHandle?

    // MARK: - OSLog Categories
    private let loggers: [LogCategory: OSLog] = [
        .general: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.globe", category: "general"),
        .security: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.globe", category: "security"),
        .authentication: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.globe", category: "auth"),
        .network: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.globe", category: "network"),
        .database: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.globe", category: "database"),
        .ui: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.globe", category: "ui"),
        .performance: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.globe", category: "performance"),
        .lifecycle: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.globe", category: "lifecycle")
    ]

    private init() {
        setupFileLogging()
        startPerformanceMonitoring()
        setupMemoryWarningObserver()
    }

    // MARK: - Log Categories
    enum LogCategory: String, CaseIterable, Codable {
        case general = "general"
        case security = "security"
        case authentication = "auth"
        case network = "network"
        case database = "database"
        case ui = "ui"
        case performance = "performance"
        case lifecycle = "lifecycle"

        var emoji: String {
            switch self {
            case .general: return "📝"
            case .security: return "🔒"
            case .authentication: return "🔑"
            case .network: return "🌐"
            case .database: return "💾"
            case .ui: return "🎨"
            case .performance: return "⚡"
            case .lifecycle: return "🔄"
            }
        }

        var color: Color {
            switch self {
            case .general: return .primary
            case .security: return .red
            case .authentication: return .orange
            case .network: return .blue
            case .database: return .green
            case .ui: return .purple
            case .performance: return .yellow
            case .lifecycle: return .gray
            }
        }
    }

    // MARK: - Log Levels
    enum LogLevel: String, CaseIterable, Comparable, Codable {
        case trace = "trace"
        case debug = "debug"
        case info = "info"
        case warning = "warning"
        case error = "error"
        case critical = "critical"

        var osLogType: OSLogType {
            switch self {
            case .trace, .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }

        var emoji: String {
            switch self {
            case .trace: return "👀"
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }

        var priority: Int {
            switch self {
            case .trace: return 0
            case .debug: return 1
            case .info: return 2
            case .warning: return 3
            case .error: return 4
            case .critical: return 5
            }
        }

        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            return lhs.priority < rhs.priority
        }
    }

    // MARK: - Log Entry Structure
    struct LogEntry: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let level: LogLevel
        let category: LogCategory
        let message: String
        let file: String
        let function: String
        let line: Int
        let threadName: String
        let metadata: [String: String]

        var fileName: String {
            URL(fileURLWithPath: file).lastPathComponent
        }

        var formattedTimestamp: String {
            DateFormatter.logFormatter.string(from: timestamp)
        }

        init(timestamp: Date = Date(), level: LogLevel, category: LogCategory, message: String, file: String, function: String, line: Int, threadName: String, metadata: [String: String] = [:]) {
            self.id = UUID()
            self.timestamp = timestamp
            self.level = level
            self.category = category
            self.message = message
            self.file = file
            self.function = function
            self.line = line
            self.threadName = threadName
            self.metadata = metadata
        }
    }

    // MARK: - Performance Metrics
    struct PerformanceMetric: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let name: String
        let value: Double
        let unit: String
        let category: String
        let metadata: [String: String]

        init(timestamp: Date = Date(), name: String, value: Double, unit: String, category: String, metadata: [String: String] = [:]) {
            self.id = UUID()
            self.timestamp = timestamp
            self.name = name
            self.value = value
            self.unit = unit
            self.category = category
            self.metadata = metadata
        }
    }

    // MARK: - Logging Methods

    /// Log a trace message (most verbose)
    func trace(
        _ message: String,
        category: LogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .trace, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    /// Log a debug message
    func debug(
        _ message: String,
        category: LogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        log(message, level: .debug, category: category, metadata: metadata, file: file, function: function, line: line)
        #endif
    }

    /// Log an info message
    func info(
        _ message: String,
        category: LogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    /// Log a warning message
    func warning(
        _ message: String,
        category: LogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    /// Log an error message
    func error(
        _ message: String,
        category: LogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    /// Log a critical message
    func critical(
        _ message: String,
        category: LogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .critical, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    /// Log an error object
    func error(
        _ error: Error,
        category: LogCategory = .general,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let message = "Error: \(error.localizedDescription)"
        var errorMetadata = metadata
        errorMetadata["error_type"] = String(describing: type(of: error))

        log(message, level: .error, category: category, metadata: errorMetadata, file: file, function: function, line: line)
    }

    // MARK: - Specialized Logging Methods

    /// Log network requests
    func networkRequest(
        method: String,
        url: String,
        statusCode: Int? = nil,
        duration: TimeInterval? = nil,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var networkMetadata = metadata
        networkMetadata["http_method"] = method
        networkMetadata["url"] = sanitizeURL(url)
        if let statusCode = statusCode {
            networkMetadata["status_code"] = String(statusCode)
        }
        if let duration = duration {
            networkMetadata["duration_ms"] = String(format: "%.2f", duration * 1000)
        }

        let level: LogLevel = statusCode.map { $0 >= 400 ? .error : .info } ?? .info
        let message = "Network \(method) \(sanitizeURL(url))"

        log(message, level: level, category: .network, metadata: networkMetadata, file: file, function: function, line: line)
    }

    /// Log database operations
    func databaseOperation(
        operation: String,
        table: String? = nil,
        duration: TimeInterval? = nil,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var dbMetadata = metadata
        dbMetadata["operation"] = operation
        if let table = table {
            dbMetadata["table"] = table
        }
        if let duration = duration {
            dbMetadata["duration_ms"] = String(format: "%.2f", duration * 1000)
        }

        let message = "Database \(operation)" + (table.map { " on \($0)" } ?? "")
        log(message, level: .info, category: .database, metadata: dbMetadata, file: file, function: function, line: line)
    }

    /// Log UI events
    func userInteraction(
        action: String,
        screen: String? = nil,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var uiMetadata = metadata
        uiMetadata["action"] = action
        if let screen = screen {
            uiMetadata["screen"] = screen
        }

        let message = "User \(action)" + (screen.map { " on \($0)" } ?? "")
        log(message, level: .info, category: .ui, metadata: uiMetadata, file: file, function: function, line: line)
    }

    // MARK: - Performance Monitoring

    /// Track performance metrics
    func trackPerformance(
        name: String,
        value: Double,
        unit: String = "ms",
        category: String = "performance",
        metadata: [String: String] = [:]
    ) {
        guard LoggingConfig.enablePerformanceTracking else { return }

        let metric = PerformanceMetric(
            timestamp: Date(),
            name: name,
            value: value,
            unit: unit,
            category: category,
            metadata: metadata
        )

        performanceMetrics.append(metric)

        // Keep only recent metrics
        if performanceMetrics.count > LoggingConfig.maxPerformanceMetrics {
            performanceMetrics.removeFirst()
        }

        info("Performance: \(name) = \(String(format: "%.2f", value))\(unit)",
             category: .performance,
             metadata: metadata)
    }

    /// Measure execution time
    func measureTime<T>(
        _ name: String,
        category: String = "performance",
        operation: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 // Convert to ms

        trackPerformance(name: name, value: timeElapsed, category: category)
        return result
    }

    /// Measure async execution time
    func measureTime<T>(
        _ name: String,
        category: String = "performance",
        operation: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let timeElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        trackPerformance(name: name, value: timeElapsed, category: category)
        return result
    }

    // MARK: - Core Logging Implementation

    private func log(
        _ message: String,
        level: LogLevel,
        category: LogCategory,
        metadata: [String: String],
        file: String,
        function: String,
        line: Int
    ) {
        let sanitizedMessage = sanitizeMessage(message)
        let threadName = Thread.current.name ?? Thread.current.description

        let logEntry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: sanitizedMessage,
            file: file,
            function: function,
            line: line,
            threadName: threadName,
            metadata: metadata
        )

        // Add to recent logs for debug view
        recentLogs.append(logEntry)

        // Keep only recent logs
        if recentLogs.count > LoggingConfig.maxRecentLogs {
            recentLogs.removeFirst()
        }

        // Log to OSLog
        if let osLog = loggers[category] {
            let formattedMessage = formatMessage(logEntry)
            os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)
        }

        // Console output in debug
        #if DEBUG
        let consoleMessage = formatConsoleMessage(logEntry)
        print(consoleMessage)
        #endif

        // Write to file
        Task {
            await self.writeToFileAsync(logEntry)
        }
    }

    // MARK: - Message Formatting

    private func formatMessage(_ entry: LogEntry) -> String {
        let metadataString = entry.metadata.isEmpty ? "" : " | \(formatMetadata(entry.metadata))"
        return "[\(entry.fileName):\(entry.line)] \(entry.function) - \(entry.message)\(metadataString)"
    }

    private func formatConsoleMessage(_ entry: LogEntry) -> String {
        let timestamp = entry.formattedTimestamp
        let levelEmoji = entry.level.emoji
        let categoryEmoji = entry.category.emoji
        let metadataString = entry.metadata.isEmpty ? "" : " | \(formatMetadata(entry.metadata))"

        return "\(timestamp) \(levelEmoji)\(categoryEmoji) [\(entry.fileName):\(entry.line)] \(entry.function) - \(entry.message)\(metadataString)"
    }

    private func formatMetadata(_ metadata: [String: String]) -> String {
        return metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    }

    // MARK: - Message Sanitization

    private func sanitizeMessage(_ message: String) -> String {
        return SecureLogger.shared.sanitizePublic(message)
    }

    private func sanitizeURL(_ url: String) -> String {
        // Remove query parameters and sensitive path components
        guard let urlComponents = URLComponents(string: url) else { return url }

        var sanitizedURL = urlComponents
        sanitizedURL.query = nil
        sanitizedURL.fragment = nil

        return sanitizedURL.string ?? url
    }

    // MARK: - File Logging

    private func setupFileLogging() {
        guard LoggingConfig.enableFileLogging else { return }

        logQueue.async {
            Task {
                await AdvancedLogger.shared.createLogFile()
                await AdvancedLogger.shared.cleanupOldLogs()
            }
        }
    }

    private func writeToFileAsync(_ entry: LogEntry) async {
        guard LoggingConfig.enableFileLogging else { return }

        await withCheckedContinuation { continuation in
            logQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                self.writeToFile(entry)
                continuation.resume()
            }
        }
    }

    private func createLogFile() async {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let logsDirectory = documentsPath.appendingPathComponent("Logs")

        do {
            try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())

            let logFile = logsDirectory.appendingPathComponent("globe-\(dateString).log")

            if !fileManager.fileExists(atPath: logFile.path) {
                fileManager.createFile(atPath: logFile.path, contents: nil)
            }

            logFileHandle = try FileHandle(forWritingTo: logFile)
            logFileHandle?.seekToEndOfFile()

        } catch {
            print("Failed to setup file logging: \(error)")
        }
    }

    private nonisolated func writeToFile(_ entry: LogEntry) {
        Task { @MainActor in
            guard let handle = self.logFileHandle else { return }

            let logLine = self.formatFileLogEntry(entry)

            if let data = logLine.data(using: .utf8) {
                handle.write(data)
            }
        }
    }

    private nonisolated func formatFileLogEntry(_ entry: LogEntry) -> String {
        let timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
        let metadataJSON = try? JSONSerialization.data(withJSONObject: entry.metadata)
        let metadataString = metadataJSON.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let fileName = URL(fileURLWithPath: entry.file).lastPathComponent

        return "\(timestamp) [\(entry.level.rawValue.uppercased())] [\(entry.category.rawValue)] [\(fileName):\(entry.line)] \(entry.function) - \(entry.message) \(metadataString)\n"
    }

    private func cleanupOldLogs() async {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let logsDirectory = documentsPath.appendingPathComponent("Logs")
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -LoggingConfig.logRetentionDays, to: Date())!

        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: [.creationDateKey])

            for logFile in logFiles {
                let creationDate = try logFile.resourceValues(forKeys: [.creationDateKey]).creationDate
                if let creationDate = creationDate, creationDate < cutoffDate {
                    try fileManager.removeItem(at: logFile)
                }
            }
        } catch {
            print("Failed to cleanup old logs: \(error)")
        }
    }

    // MARK: - System Monitoring

    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                await AdvancedLogger.shared.collectSystemMetrics()
            }
        }
    }

    private func collectSystemMetrics() async {
        let memoryInfo = readMachTaskInfo()
        let memoryUsage = Double(memoryInfo.resident_size) / 1024 / 1024 // MB

        trackPerformance(name: "memory_usage", value: memoryUsage, unit: "MB", category: "system")
    }

    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                AdvancedLogger.shared.warning("Received memory warning", category: .lifecycle)
            }
        }
    }

    // MARK: - Debug UI Control

    func toggleDebugView() {
        isDebugViewVisible.toggle()
    }

    func clearLogs() {
        recentLogs.removeAll()
        performanceMetrics.removeAll()
    }

    func exportLogs() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(recentLogs)
            return String(data: data, encoding: .utf8) ?? "Failed to encode logs"
        } catch {
            return "Failed to export logs: \(error)"
        }
    }

    deinit {
        logFileHandle?.closeFile()
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - System Info Helper

private func readMachTaskInfo() -> mach_task_basic_info {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    _ = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }

    return info
}
