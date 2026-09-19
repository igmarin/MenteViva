import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(String(localized: "game.memory.title")) {
                    MemoryMatchView()
                }
                NavigationLink(String(localized: "game.colorclash.title")) {
                    ColorClashView()
                }
                NavigationLink(String(localized: "game.category.title")) {
                    CategoryFluencyView()
                }
                NavigationLink(String(localized: "game.math.title")) {
                    MathStreakView()
                }
            }
            .navigationTitle(String(localized: "app.title"))
        }
    }
}

#Preview {
    HomeView()
}
