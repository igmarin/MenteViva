import SwiftUI
import SwiftData

@main
struct MenteVivaApp: App {
    /// Private-database CloudKit sync so dad's history mirrors across his
    /// devices and the family share lives under his iCloud account. If the
    /// container can't be created (e.g. signed-out iCloud), we fall back to
    /// a local-only store — offline must never break.
    private let modelContainer: ModelContainer = {
        let schema = Schema([GameSession.self])
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.com.igmarin.MenteViva")
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema)]
                )
            } catch {
                fatalError("Could not create any ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(modelContainer)
    }
}
