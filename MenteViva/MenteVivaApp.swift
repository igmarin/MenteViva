import SwiftUI
import SwiftData

@main
struct MenteVivaApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: GameSession.self)
    }
}
