import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
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
