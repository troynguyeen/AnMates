import SwiftUI

@main
struct AnMatesApp: App {
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(theme)
                .preferredColorScheme(.dark)
                .tint(theme.mode.accent)
                .onAppear { theme.refreshIfNeeded() }
        }
    }
}
