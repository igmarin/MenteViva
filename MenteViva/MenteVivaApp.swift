import OSLog
import SwiftData
import SwiftUI

@main
struct MenteVivaApp: App {
    /// CloudKit sync is a **compile-time** choice. The generator passes
    /// `LOCAL_ONLY` for `--local-only` builds, because iCloud entitlements need
    /// the paid Developer Program and enabling CloudKit in a build without the
    /// entitlement traps inside CloudKit's mirroring setup — an uncatchable
    /// EXC_BREAKPOINT, not a Swift error we could fall back from.
    private let modelContainer: ModelContainer = {
        let schema = Schema([GameSession.self])
        #if LOCAL_ONLY
            let stores = [ModelConfiguration(schema: schema)]
        #else
            let stores = [
                ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.igmarin.MenteViva")),
                ModelConfiguration(schema: schema),
            ]
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
            return try ModelContainer(
                for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
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
    @AppStorage(OnboardingView.seenKey) private var hasSeenOnboarding = false
    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.system.rawValue
    @AppStorage(SettingsView.biggerTextKey) private var biggerText = false

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
        // Card Table theme: icon teal as the tint; each game re-tints its
        // own screen with its ink. (Rounded type is set per text, not here:
        // a root .fontDesign doesn't reach text that sets its own .font.)
        .tint(.brand)
    }
}
