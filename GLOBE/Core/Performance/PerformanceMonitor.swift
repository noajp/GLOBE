//======================================================================
// MARK: - PerformanceMonitor.swift
// Purpose: Comprehensive performance monitoring and analytics system
// Path: GLOBE/Core/Performance/PerformanceMonitor.swift
//======================================================================

import Foundation
import SwiftUI
import Combine
import os.log

@MainActor
final class PerformanceMonitor: ObservableObject {

    static let shared = PerformanceMonitor()

    // MARK: - Published Properties
    @Published var currentFrameRate: Double = 60.0
    @Published var memoryUsage: MemoryUsage = MemoryUsage()
    @Published var networkStats: NetworkStats = NetworkStats()
    @Published var appLifecycleMetrics: AppLifecycleMetrics = AppLifecycleMetrics()
    @Published var userInteractionMetrics: [UserInteractionMetric] = []

    // MARK: - Configuration
    private struct MonitoringConfig {
        static let updateInterval: TimeInterval = 1.0
        static let frameRateUpdateInterval: TimeInterval = 0.1
        static let maxStoredMetrics = 1000
        static let enableDetailedMemoryTracking = true
        static let enableNetworkMonitoring = true
        static let enableUserInteractionTracking = true
    }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var frameRateTimer: Timer?
    private var memoryTimer: Timer?
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount = 0
    private let logger = AdvancedLogger.shared

    // Performance tracking
    private var pendingOperations: [String: Date] = [:]
    private var completedOperations: [PerformanceMetric] = []

    private init() {
        setupMonitoring()
        setupAppLifecycleObservers()
    }

    // MARK: - Data Structures

    struct MemoryUsage: Codable {
        var resident: UInt64 = 0        // Physical memory in use
        var virtual: UInt64 = 0         // Virtual memory size
        var peak: UInt64 = 0            // Peak memory usage
        var available: UInt64 = 0       // Available physical memory
        var pressure: MemoryPressure = .normal

        var residentMB: Double {
            return Double(resident) / 1024 / 1024
        }

        var virtualMB: Double {
            return Double(virtual) / 1024 / 1024
        }

        var peakMB: Double {
            return Double(peak) / 1024 / 1024
        }
    }

    enum MemoryPressure: String, Codable, CaseIterable {
        case normal = "normal"
        case warning = "warning"
        case urgent = "urgent"
        case critical = "critical"

        var color: Color {
            switch self {
            case .normal: return .green
            case .warning: return .yellow
            case .urgent: return .orange
            case .critical: return .red
            }
        }
    }

    struct NetworkStats: Codable {
        var requestsInFlight = 0
        var totalRequests = 0
        var failedRequests = 0
        var averageResponseTime: TimeInterval = 0
        var bytesReceived: UInt64 = 0
        var bytesSent: UInt64 = 0
        var lastUpdateTime = Date()

        var successRate: Double {
            guard totalRequests > 0 else { return 1.0 }
            return Double(totalRequests - failedRequests) / Double(totalRequests)
        }
    }

    struct AppLifecycleMetrics: Codable {
        var launchTime: TimeInterval = 0
        var foregroundTime: TimeInterval = 0
        var backgroundTime: TimeInterval = 0
        var crashCount = 0
        var memoryWarningsCount = 0
        var thermalStateChanges = 0
        var batteryLevel: Float = 1.0
        var lowPowerModeEnabled = false
    }

    struct UserInteractionMetric: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let action: String
        let screen: String
        let duration: TimeInterval?
        let metadata: [String: String]

        init(action: String, screen: String, duration: TimeInterval? = nil, metadata: [String: String] = [:]) {
            self.id = UUID()
            self.timestamp = Date()
            self.action = action
            self.screen = screen
            self.duration = duration
            self.metadata = metadata
        }
    }

    struct PerformanceMetric: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let operation: String
        let duration: TimeInterval
        let category: String
        let success: Bool
        let metadata: [String: String]

        init(operation: String, duration: TimeInterval, category: String, success: Bool, metadata: [String: String] = [:]) {
            self.id = UUID()
            self.timestamp = Date()
            self.operation = operation
            self.duration = duration
            self.category = category
            self.success = success
            self.metadata = metadata
        }
    }

    // MARK: - Setup Methods

    private func setupMonitoring() {
        // Frame rate monitoring
        frameRateTimer = Timer.scheduledTimer(withTimeInterval: MonitoringConfig.frameRateUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateFrameRate()
            }
        }

        // Memory monitoring
        memoryTimer = Timer.scheduledTimer(withTimeInterval: MonitoringConfig.updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
                self?.updateSystemMetrics()
            }
        }

        // Network monitoring
        if MonitoringConfig.enableNetworkMonitoring {
            setupNetworkMonitoring()
        }
    }

    private func setupAppLifecycleObservers() {
        // App lifecycle notifications
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppBecomeActive()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppEnterBackground()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)

        // Thermal state monitoring
        NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.handleThermalStateChange()
            }
            .store(in: &cancellables)

        // Battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryInfo()
            }
            .store(in: &cancellables)

        // Power state change notification is not universally available; rely on battery + low power polling
    }

    private func setupNetworkMonitoring() {
        // This would integrate with your network layer to track requests
        // For now, we'll create a simple tracking system
        logger.info("Network monitoring enabled", category: .performance)
    }

    // MARK: - Frame Rate Monitoring

    private func updateFrameRate() {
        let currentTime = CACurrentMediaTime()

        if lastFrameTime > 0 {
            let deltaTime = currentTime - lastFrameTime
            if deltaTime > 0 {
                let fps = 1.0 / deltaTime
                currentFrameRate = min(fps, 60.0) // Cap at 60 FPS
            }
        }

        lastFrameTime = currentTime
        frameCount += 1

        // Log frame rate drops
        if currentFrameRate < 50 {
            logger.warning("Low frame rate detected: \(String(format: "%.1f", currentFrameRate)) FPS", category: .performance)
        }

        // Track frame rate performance
        if frameCount % 60 == 0 { // Every 60 frames
            logger.trackPerformance(
                name: "frame_rate",
                value: currentFrameRate,
                unit: "fps",
                category: "rendering"
            )
        }
    }

    // MARK: - Memory Monitoring

    private func updateMemoryUsage() {
        let info = readMachTaskInfo()
        let previousResident = memoryUsage.resident

        memoryUsage.resident = UInt64(info.resident_size)
        memoryUsage.virtual = UInt64(info.virtual_size)
        memoryUsage.peak = max(memoryUsage.peak, memoryUsage.resident)

        // Get available memory
        if let availableMemory = getAvailableMemory() {
            memoryUsage.available = availableMemory
        }

        // Determine memory pressure
        memoryUsage.pressure = calculateMemoryPressure()

        // Log memory changes
        if memoryUsage.resident > previousResident + (10 * 1024 * 1024) { // 10MB increase
            logger.warning("Memory usage increased significantly: \(memoryUsage.residentMB) MB", category: .performance)
        }

        // Track memory metrics
        logger.trackPerformance(
            name: "memory_resident",
            value: memoryUsage.residentMB,
            unit: "MB",
            category: "memory"
        )
    }

    private func getAvailableMemory() -> UInt64? {
        var pagesize: vm_size_t = 0
        let host_port = mach_host_self()
        var host_size = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(host_port, &pagesize)

        var vm_stat = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vm_stat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                host_statistics(host_port, HOST_VM_INFO, $0, &host_size)
            }
        }

        let free_memory = UInt64(vm_stat.free_count) * UInt64(pagesize)
        return free_memory
    }

    private func calculateMemoryPressure() -> MemoryPressure {
        let usageRatio = Double(memoryUsage.resident) / Double(memoryUsage.available + memoryUsage.resident)

        switch usageRatio {
        case 0..<0.7: return .normal
        case 0.7..<0.85: return .warning
        case 0.85..<0.95: return .urgent
        default: return .critical
        }
    }

    // MARK: - System Metrics

    private func updateSystemMetrics() {
        // CPU Usage (simplified)
        let cpuUsage = getCurrentCPUUsage()
        logger.trackPerformance(
            name: "cpu_usage",
            value: cpuUsage,
            unit: "%",
            category: "system"
        )

        // Disk usage
        if let diskUsage = getDiskUsage() {
            logger.trackPerformance(
                name: "disk_usage",
                value: diskUsage,
                unit: "%",
                category: "system"
            )
        }
    }

    private func getCurrentCPUUsage() -> Double {
        // Simplified stub: precise CPU usage collection via host_processor_info can be fragile across SDKs.
        // For now, return 0 and rely on higher-level performance metrics.
        return 0.0
    }

    private func getDiskUsage() -> Double? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        do {
            let values = try documentsPath.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey])
            guard let available = values.volumeAvailableCapacity,
                  let total = values.volumeTotalCapacity else {
                return nil
            }

            let used = total - available
            return Double(used) / Double(total) * 100.0
        } catch {
            return nil
        }
    }

    // MARK: - Network Monitoring

    func trackNetworkRequest(
        method: String,
        url: String,
        startTime: Date,
        endTime: Date,
        success: Bool,
        bytesReceived: Int = 0,
        bytesSent: Int = 0
    ) {
        let duration = endTime.timeIntervalSince(startTime)

        // Update network stats
        networkStats.totalRequests += 1
        if !success {
            networkStats.failedRequests += 1
        }

        // Update average response time
        networkStats.averageResponseTime = (networkStats.averageResponseTime * Double(networkStats.totalRequests - 1) + duration) / Double(networkStats.totalRequests)

        networkStats.bytesReceived += UInt64(bytesReceived)
        networkStats.bytesSent += UInt64(bytesSent)
        networkStats.lastUpdateTime = Date()

        // Log network performance
        logger.networkRequest(
            method: method,
            url: url,
            statusCode: success ? 200 : 500,
            duration: duration
        )

        // Track performance metric
        logger.trackPerformance(
            name: "network_request",
            value: duration * 1000, // Convert to ms
            unit: "ms",
            category: "network",
            metadata: [
                "method": method,
                "success": String(success)
            ]
        )
    }

    // MARK: - User Interaction Tracking

    func trackUserInteraction(
        action: String,
        screen: String,
        duration: TimeInterval? = nil,
        metadata: [String: String] = [:]
    ) {
        guard MonitoringConfig.enableUserInteractionTracking else { return }

        let metric = UserInteractionMetric(
            action: action,
            screen: screen,
            duration: duration,
            metadata: metadata
        )

        userInteractionMetrics.append(metric)

        // Keep only recent metrics
        if userInteractionMetrics.count > MonitoringConfig.maxStoredMetrics {
            userInteractionMetrics.removeFirst()
        }

        logger.userInteraction(action: action, screen: screen, metadata: metadata)
    }

    // MARK: - Performance Operation Tracking

    func startOperation(_ name: String) {
        pendingOperations[name] = Date()
    }

    func endOperation(_ name: String, success: Bool = true, metadata: [String: String] = [:]) {
        guard let startTime = pendingOperations.removeValue(forKey: name) else {
            logger.warning("Attempted to end operation '\(name)' that was not started", category: .performance)
            return
        }

        let duration = Date().timeIntervalSince(startTime)

        let metric = PerformanceMetric(
            operation: name,
            duration: duration,
            category: "operation",
            success: success,
            metadata: metadata
        )

        completedOperations.append(metric)

        // Keep only recent operations
        if completedOperations.count > MonitoringConfig.maxStoredMetrics {
            completedOperations.removeFirst()
        }

        logger.trackPerformance(
            name: name,
            value: duration * 1000, // Convert to ms
            unit: "ms",
            category: "operation",
            metadata: metadata
        )
    }

    // MARK: - App Lifecycle Handlers

    private func handleAppBecomeActive() {
        appLifecycleMetrics.foregroundTime = Date().timeIntervalSince1970
        logger.info("App became active", category: .lifecycle)
    }

    private func handleAppEnterBackground() {
        let backgroundTime = Date().timeIntervalSince1970
        if appLifecycleMetrics.foregroundTime > 0 {
            let sessionDuration = backgroundTime - appLifecycleMetrics.foregroundTime
            logger.trackPerformance(
                name: "app_session_duration",
                value: sessionDuration,
                unit: "seconds",
                category: "lifecycle"
            )
        }
        appLifecycleMetrics.backgroundTime = backgroundTime
        logger.info("App entered background", category: .lifecycle)
    }

    private func handleMemoryWarning() {
        appLifecycleMetrics.memoryWarningsCount += 1
        logger.warning("Memory warning received (count: \(appLifecycleMetrics.memoryWarningsCount))", category: .lifecycle)

        // Force memory usage update
        updateMemoryUsage()
    }

    private func handleThermalStateChange() {
        appLifecycleMetrics.thermalStateChanges += 1
        let thermalState = ProcessInfo.processInfo.thermalState

        var stateDescription: String
        switch thermalState {
        case .nominal: stateDescription = "nominal"
        case .fair: stateDescription = "fair"
        case .serious: stateDescription = "serious"
        case .critical: stateDescription = "critical"
        @unknown default: stateDescription = "unknown"
        }

        logger.warning("Thermal state changed to: \(stateDescription)", category: .performance)
    }

    private func updateBatteryInfo() {
        appLifecycleMetrics.batteryLevel = UIDevice.current.batteryLevel
        logger.trackPerformance(
            name: "battery_level",
            value: Double(appLifecycleMetrics.batteryLevel * 100),
            unit: "%",
            category: "system"
        )
    }

    private func updatePowerState() {
        appLifecycleMetrics.lowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        if appLifecycleMetrics.lowPowerModeEnabled {
            logger.warning("Low power mode enabled", category: .performance)
        }
    }

    // MARK: - Public Interface

    func generatePerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            timestamp: Date(),
            frameRate: currentFrameRate,
            memoryUsage: memoryUsage,
            networkStats: networkStats,
            lifecycleMetrics: appLifecycleMetrics,
            recentOperations: Array(completedOperations.suffix(100)),
            userInteractions: Array(userInteractionMetrics.suffix(100))
        )
    }

    func resetMetrics() {
        userInteractionMetrics.removeAll()
        completedOperations.removeAll()
        pendingOperations.removeAll()

        networkStats = NetworkStats()
        appLifecycleMetrics = AppLifecycleMetrics()

        logger.info("Performance metrics reset", category: .performance)
    }

    deinit {
        frameRateTimer?.invalidate()
        memoryTimer?.invalidate()
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
}

// MARK: - Performance Report

struct PerformanceReport: Codable {
    let timestamp: Date
    let frameRate: Double
    let memoryUsage: PerformanceMonitor.MemoryUsage
    let networkStats: PerformanceMonitor.NetworkStats
    let lifecycleMetrics: PerformanceMonitor.AppLifecycleMetrics
    let recentOperations: [PerformanceMonitor.PerformanceMetric]
    let userInteractions: [PerformanceMonitor.UserInteractionMetric]

    var summary: String {
        return """
        Performance Report - \(DateFormatter.reportFormatter.string(from: timestamp))

        Frame Rate: \(String(format: "%.1f", frameRate)) FPS
        Memory Usage: \(String(format: "%.1f", memoryUsage.residentMB)) MB
        Memory Pressure: \(memoryUsage.pressure.rawValue)
        Network Success Rate: \(String(format: "%.1f", networkStats.successRate * 100))%
        Memory Warnings: \(lifecycleMetrics.memoryWarningsCount)
        Battery Level: \(String(format: "%.0f", lifecycleMetrics.batteryLevel * 100))%
        Recent Operations: \(recentOperations.count)
        User Interactions: \(userInteractions.count)
        """
    }
}

private extension DateFormatter {
    static let reportFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}

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
