import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
            .debugOverlay() // デバッグオーバーレイを追加
            .onAppear {
                // ContentView表示時にログ出力
                ConsoleLogger.shared.forceLog("ContentView appeared")
                DebugLogger.shared.info("ContentView displayed", category: "UI")
            }
    }
}

#Preview {
    ContentView()
}