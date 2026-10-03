import SwiftUI
import SwiftData
import OSLog

@main
struct MenteVivaApp: App {
    /// CloudKit sync is a **compile-time** choice. The generator passes
    /// `LOCAL_ONLY` for `--local-only` builds, because iCloud entitlements need
    /// the paid Developer Program and enabling CloudKit in a build without the
    /// entitlement traps inside CloudKit's mirroring setup — an uncatchable
    /// EXC_BREAKPOINT, not a Swift error we could fall back from.
    init() {
        // Must happen before any view resolves a string, so the stored language
        // choice wins on this launch rather than the next one.
        AppLanguage.apply(UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue)
    }
    private let modelContainer: ModelContainer = {
        let schema = Schema([GameSession.self])
        #if LOCAL_ONLY
        let stores = [ModelConfiguration(schema: schema)]
        #else
        let stores = [ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.igmarin.MenteViva")),
                      ModelConfiguration(schema: schema)]
        #endif
        return makeContainer(trying: stores, schema: schema)
    }()

    /// The first store that opens, in order. If none does (a failed migration,
    /// a damaged file), an in-memory store (#124): this launch's games aren't
    /// kept, but the app opens and play goes on. Logged, never shown.
    static func makeContainer(trying stores: [ModelConfiguration], schema: Schema) -> ModelContainer {
        let log = Logger(subsystem: "com.igmarin.MenteViva", category: "store")
        for store in stores {
            do {
                return try ModelContainer(for: schema, configurations: [store])
            } catch {
                log.error("Store did not open: \(String(describing: error), privacy: .public)")
            }
        }
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        } catch {
            fatalError("Could not create even an in-memory store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}

/// Decides what a launch shows: onboarding for a stranger, the games for
/// someone who's been here before. Also applies the bigger-text choice.
private struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("biggerText") private var biggerText = false

    var body: some View {
        Group {
            if hasSeenOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        // A range, never a fixed size (#117): off follows the device's text
        // setting; on raises the floor to xxxLarge but keeps larger system sizes.
        .dynamicTypeSize(biggerText ? .xxxLarge ... .accessibility5 : .xSmall ... .accessibility5)
        .environment(\.locale, AppLanguage.locale(for: appLanguage))
    }
}
