import SwiftUI
import os.log

@main
struct GlobeApp: App {
    init() {
        // ConsoleLoggerを初期化（本番は静かに）
        let consoleLogger = ConsoleLogger.shared
        #if DEBUG
        consoleLogger.forceLog("=== GLOBE APP INITIALIZATION STARTED ===")
        consoleLogger.forceLog("App Info: Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"), Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")")
        consoleLogger.forceLog("Device: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)")
        // 軽量なテストログのみ（重い生成はしない）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            consoleLogger.forceLog("Initialization heartbeat")
        }
        consoleLogger.forceLog("=== GLOBE APP INITIALIZATION COMPLETED ===")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
