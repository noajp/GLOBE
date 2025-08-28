import SwiftUI
import os.log

@main
struct GlobeApp: App {
    init() {
        // ConsoleLoggerを最初に初期化（確実にログが出る）
        let consoleLogger = ConsoleLogger.shared
        consoleLogger.forceLog("=== GLOBE APP INITIALIZATION STARTED ===")
        
        // 複数の方法でログ出力をテスト
        print("🔥 DIRECT PRINT: GLOBE app initializing...")
        NSLog("🔥 NSLOG: GLOBE app initializing...")
        debugPrint("🔥 DEBUG PRINT: GLOBE app initializing...")
        fputs("🔥 STDERR: GLOBE app initializing...\n", stderr)
        
        // OSLogでも出力
        if #available(iOS 10.0, *) {
            os_log("🔥 OSLOG: GLOBE app initializing...", type: .info)
        }
        
        // DebugLoggerも初期化
        let debugLogger = DebugLogger.shared
        debugLogger.forceConsoleOutput("GLOBE app starting initialization...")
        
        consoleLogger.forceLog("App Info: Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"), Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")")
        consoleLogger.forceLog("Device: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)")
        
        // テストログも即座に生成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            consoleLogger.forceLog("Delayed test log - 1 second after init")
            debugLogger.generateTestLogs()
        }
        
        consoleLogger.forceLog("=== GLOBE APP INITIALIZATION COMPLETED ===")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}