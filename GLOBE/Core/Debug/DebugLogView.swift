//======================================================================
// MARK: - DebugLogView.swift
// Purpose: Debug log viewer UI component
// Path: GLOBE/Core/Debug/DebugLogView.swift
//======================================================================
import SwiftUI

/// デバッグログ表示画面
struct DebugLogView: View {
    @ObservedObject private var logger = DebugLogger.shared
    @State private var selectedLevel: LogLevel? = nil
    @State private var searchText = ""
    @State private var autoScroll = true
    
    var filteredLogs: [LogEntry] {
        var logs = logger.logs
        
        // レベルフィルター
        if let selectedLevel = selectedLevel {
            logs = logs.filter { $0.level == selectedLevel }
        }
        
        // 検索フィルター
        if !searchText.isEmpty {
            logs = logs.filter { 
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return logs
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // フィルターとコントロール
                VStack(spacing: 8) {
                    // レベルフィルター
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterButton(for: nil, title: "All")
                            
                            ForEach(LogLevel.allCases, id: \.self) { level in
                                filterButton(for: level, title: "\(level.rawValue)")
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 検索バー
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search logs...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // コントロールボタン
                    HStack {
                        Button(action: { logger.clearLogs() }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear")
                            }
                        }
                        .foregroundColor(.red)
                        
                        Button(action: { 
                            logger.generateTestLogs()
                            logger.forceConsoleOutput("Test logs generated!")
                        }) {
                            HStack {
                                Image(systemName: "flask")
                                Text("Test")
                            }
                        }
                        .foregroundColor(.green)
                        
                        Spacer()
                        
                        Toggle("Auto Scroll", isOn: $autoScroll)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        Spacer()
                        
                        Button(action: shareLog) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .font(.caption)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // ログリスト
                if filteredLogs.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No logs available")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Logs will appear here when generated")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredLogs) { entry in
                            LogEntryRow(entry: entry)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Debug Logs (\(filteredLogs.count))")
            .navigationBarItems(trailing: 
                Button("Done") {
                    // Dismiss logic would go here
                }
            )
        }
        .onChange(of: logger.logs.count) { _, _ in
            if autoScroll && !filteredLogs.isEmpty {
                // Auto scroll to bottom when new logs arrive
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Scroll implementation would go here
                }
            }
        }
    }
    
    private func filterButton(for level: LogLevel?, title: String) -> some View {
        Button(action: {
            selectedLevel = selectedLevel == level ? nil : level
        }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedLevel == level ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(selectedLevel == level ? .white : .primary)
                .cornerRadius(16)
        }
    }
    
    private func shareLog() {
        let logText = logger.exportLogs()
        let activityView = UIActivityViewController(activityItems: [logText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityView, animated: true)
        }
    }
}

/// ログエントリ行コンポーネント
struct LogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // ログレベルアイコン
                Text(entry.level.rawValue)
                    .font(.system(size: 16))
                
                // タイムスタンプ
                Text(entry.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .monospaced()
                
                Spacer()
                
                // カテゴリ
                Text(entry.category)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // メッセージ
            Text(entry.message)
                .font(.system(.body, design: .monospaced))
                .fixedSize(horizontal: false, vertical: true)
            
            // 詳細情報（展開可能）
            if let details = entry.details, !details.isEmpty {
                Button(action: { isExpanded.toggle() }) {
                    HStack {
                        Text(isExpanded ? "Hide Details" : "Show Details")
                            .font(.caption)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(details.keys.sorted()), id: \.self) { key in
                            HStack(alignment: .top) {
                                Text("\(key):")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .bold()
                                Text(String(describing: details[key] ?? ""))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .monospaced()
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 4)
        .background(backgroundColor(for: entry.level))
        .cornerRadius(8)
    }
    
    private func backgroundColor(for level: LogLevel) -> Color {
        switch level {
        case .error:
            return Color.red.opacity(0.1)
        case .warning:
            return Color.orange.opacity(0.1)
        case .success:
            return Color.green.opacity(0.1)
        case .auth:
            return Color.purple.opacity(0.1)
        case .network:
            return Color.blue.opacity(0.1)
        case .database:
            return Color.brown.opacity(0.1)
        default:
            return Color.clear
        }
    }
}

#Preview {
    DebugLogView()
}