import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
            #if DEBUG
            .debugOverlay() // デバッグオーバーレイは開発時のみ
            #endif
            .onAppear {
                // ContentView表示時にログ出力
                ConsoleLogger.shared.forceLog("ContentView appeared")
                SecureLogger.shared.info("ContentView displayed")
            }
    }
}

#Preview {
    ContentView()
}
