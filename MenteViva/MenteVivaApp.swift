import SwiftUI
import SwiftData

@main
struct MenteVivaApp: App {
    /// CloudKit sync is opt-in at build time (`swift tools/generate_project.swift`
    /// writes CloudKitEnabled; `--local-only` writes NO). Needed because iCloud
    /// entitlements require the paid Developer Program — a free Apple ID can't
    /// provision them, and the playtest must be installable with a free account.
    /// Local-only mode still keeps everything working: the store is on-device.
    private let modelContainer: ModelContainer = {
        let schema = Schema([GameSession.self])
        let cloudKitEnabled = (Bundle.main.object(forInfoDictionaryKey: "CloudKitEnabled") as? String) != "NO"

        let config = cloudKitEnabled
            ? ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.igmarin.MenteViva"))
            : ModelConfiguration(schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Signed-out iCloud or missing entitlement: never break play.
            do {
                return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
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
