import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(String(localized: "game.memory.title")) {
                    MemoryMatchView()
                }
            }
            .navigationTitle(String(localized: "app.title"))
        }
    }
}

#Preview {
    HomeView()
}
