import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView()
                .tabItem {
                    Label("Khám phá", systemImage: selectedTab == 0 ? "map.fill" : "map")
                }
                .tag(0)

            MatchView()
                .tabItem {
                    Label("Match", systemImage: selectedTab == 1 ? "heart.fill" : "heart")
                }
                .tag(1)

            ChatListView()
                .tabItem {
                    Label("Chat", systemImage: selectedTab == 2 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Tôi", systemImage: selectedTab == 3 ? "person.fill" : "person")
                }
                .tag(3)
        }
        .tint(Color(hex: "6C5CE7"))
    }
}
