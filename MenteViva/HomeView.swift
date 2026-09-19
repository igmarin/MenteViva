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
                NavigationLink(String(localized: "game.quickeyes.title")) {
                    QuickEyesView()
                }
            }
            .navigationTitle(String(localized: "app.title"))
        }
    }
}

#Preview {
    HomeView()
}
