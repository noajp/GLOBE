//======================================================================
// MARK: - DebugConsoleView.swift
// Purpose: In-app debug console for development and troubleshooting
// Path: GLOBE/Views/Debug/DebugConsoleView.swift
//======================================================================

import SwiftUI
import Charts

struct DebugConsoleView: View {
    @StateObject private var logger = AdvancedLogger.shared
    @State private var selectedCategory: AdvancedLogger.LogCategory = .general
    @State private var selectedLogLevel: AdvancedLogger.LogLevel = .debug
    @State private var searchText = ""
    @State private var showingExportSheet = false
    @State private var showingPerformanceChart = false
    @State private var autoScroll = true

    // MARK: - Computed Properties

    private var filteredLogs: [AdvancedLogger.LogEntry] {
        logger.recentLogs
            .filter { entry in
                (selectedCategory == .general || entry.category == selectedCategory) &&
                entry.level >= selectedLogLevel &&
                (searchText.isEmpty || entry.message.localizedCaseInsensitiveContains(searchText) ||
                 entry.fileName.localizedCaseInsensitiveContains(searchText) ||
                 entry.function.localizedCaseInsensitiveContains(searchText))
            }
            .suffix(1000) // Limit for performance
    }

    private var logCounts: [AdvancedLogger.LogLevel: Int] {
        var counts: [AdvancedLogger.LogLevel: Int] = [:]
        for level in AdvancedLogger.LogLevel.allCases {
            counts[level] = logger.recentLogs.filter { $0.level == level }.count
        }
        return counts
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Control Panel
                controlPanel

                Divider()

                // Main Content
                TabView {
                    // Logs Tab
                    logsView
                        .tabItem {
                            Image(systemName: "list.bullet.rectangle")
                            Text("Logs")
                        }

                    // Performance Tab
                    performanceView
                        .tabItem {
                            Image(systemName: "speedometer")
                            Text("Performance")
                        }

                    // System Info Tab
                    systemInfoView
                        .tabItem {
                            Image(systemName: "info.circle")
                            Text("System")
                        }
                }
            }
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        logger.clearLogs()
                    }

                    Button("Export") {
                        showingExportSheet = true
                    }

                    Button("Close") {
                        logger.toggleDebugView()
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            exportView
        }
    }

    // MARK: - Control Panel

    @ViewBuilder
    private var controlPanel: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                }
            }

            // Filters
            HStack {
                // Category Filter
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag(AdvancedLogger.LogCategory.general)
                    ForEach(AdvancedLogger.LogCategory.allCases, id: \.self) { category in
                        Label(category.rawValue.capitalized, systemImage: "circle.fill")
                            .foregroundColor(category.color)
                            .tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Spacer()

                // Level Filter
                Picker("Level", selection: $selectedLogLevel) {
                    ForEach(AdvancedLogger.LogLevel.allCases, id: \.self) { level in
                        Label(level.rawValue.capitalized, systemImage: "circle.fill")
                            .tag(level)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Spacer()

                // Auto Scroll Toggle
                Toggle("Auto Scroll", isOn: $autoScroll)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }

            // Log Level Summary
            HStack(spacing: 16) {
                ForEach(AdvancedLogger.LogLevel.allCases, id: \.self) { level in
                    VStack {
                        Text(level.emoji)
                            .font(.title2)
                        Text("\(logCounts[level] ?? 0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Logs View

    @ViewBuilder
    private var logsView: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(filteredLogs) { entry in
                    LogEntryRow(entry: entry)
                        .id(entry.id)
                }
            }
            .listStyle(PlainListStyle())
            .onChange(of: filteredLogs.count) { _ in
                if autoScroll, let lastEntry = filteredLogs.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Performance View

    @ViewBuilder
    private var performanceView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Memory Usage Chart
                if !logger.performanceMetrics.isEmpty {
                    performanceChart
                }

                // Performance Metrics List
                ForEach(logger.performanceMetrics.suffix(50), id: \.id) { metric in
                    PerformanceMetricRow(metric: metric)
                }
            }
            .padding()
        }
    }

    // MARK: - System Info View

    @ViewBuilder
    private var systemInfoView: some View {
        List {
            Section("App Information") {
                InfoRow(title: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
                InfoRow(title: "Version", value: Bundle.main.appVersion)
                InfoRow(title: "Build", value: Bundle.main.appBuild)
                InfoRow(title: "Target", value: Bundle.main.isDebug ? "Debug" : "Release")
            }

            Section("Device Information") {
                InfoRow(title: "Model", value: UIDevice.current.model)
                InfoRow(title: "System", value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                InfoRow(title: "Locale", value: Locale.current.identifier)
                InfoRow(title: "Time Zone", value: TimeZone.current.identifier)
            }

            Section("Runtime Information") {
                InfoRow(title: "Logs Count", value: "\(logger.recentLogs.count)")
                InfoRow(title: "Performance Metrics", value: "\(logger.performanceMetrics.count)")
                InfoRow(title: "Memory Usage", value: memoryUsage)
                InfoRow(title: "Thread Count", value: "\(ProcessInfo.processInfo.processorCount)")
            }
        }
    }

    // MARK: - Performance Chart

    @ViewBuilder
    private var performanceChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Memory Usage (MB)")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(logger.performanceMetrics.filter { $0.name == "memory_usage" }.suffix(50), id: \.id) { metric in
                    LineMark(
                        x: .value("Time", metric.timestamp),
                        y: .value("Memory", metric.value)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    // MARK: - Export View

    @ViewBuilder
    private var exportView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Debug Information")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("This will export all current logs and performance metrics in JSON format.")
                        .foregroundColor(.secondary)

                    Text(logger.exportLogs())
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var memoryUsage: String {
        let info = readMachTaskInfo()
        let memoryMB = Double(info.resident_size) / 1024 / 1024
        return String(format: "%.1f MB", memoryMB)
    }
}

// MARK: - Supporting Views

struct LogEntryRow: View {
    let entry: AdvancedLogger.LogEntry
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Level and Category Indicators
                HStack(spacing: 4) {
                    Text(entry.level.emoji)
                        .font(.caption)
                    Text(entry.category.emoji)
                        .font(.caption)
                }

                // Timestamp
                Text(entry.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // File and Line
                Text("\(entry.fileName):\(entry.line)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Message
            Text(entry.message)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(isExpanded ? nil : 3)

            // Function name
            if isExpanded {
                Text(entry.function)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)

                // Metadata
                if !entry.metadata.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Metadata:")
                            .font(.caption2)
                            .fontWeight(.semibold)

                        ForEach(entry.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(key)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(value)
                                    .font(.caption2)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
}

struct PerformanceMetricRow: View {
    let metric: AdvancedLogger.PerformanceMetric

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.name)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(metric.category)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.2f", metric.value)) \(metric.unit)")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text(DateFormatter.shortTime.string(from: metric.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Extensions

private extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var appBuild: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

private extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
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

// MARK: - Debug Console Integration

#if DEBUG
struct DebugConsoleModifier: ViewModifier {
    @StateObject private var logger = AdvancedLogger.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            // Debug trigger button (only in debug builds)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        logger.toggleDebugView()
                    }) {
                        Image(systemName: "ladybug.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $logger.isDebugViewVisible) {
            DebugConsoleView()
        }
    }
}

extension View {
    func debugConsole() -> some View {
        modifier(DebugConsoleModifier())
    }
}
#else
extension View {
    func debugConsole() -> some View {
        self
    }
}
#endif
