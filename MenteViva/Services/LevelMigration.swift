import Foundation

/// One-time upgrade of pre-level storage (#197) — batched so reads stay pure (#264).
///
/// Two legacy stores used 0/1/2 for easy/medium/hard:
/// - pins: `difficulty.pin.<game>` → `level.pin.<game>` (2/4/6)
/// - plan levels: `jev.difficulty` (map String → Int) → `level.byGame`
///
/// `LevelMigration.runOnce` calls both migrations and marks itself done under a
/// single key. `MenteVivaApp` calls it at launch, before any view reads levels.
/// After that, `FamilySettings.pinned()` and `PlanStore.storedDifficulty()` are
/// pure reads (no writes). The underlying migrations remain idempotent: they
/// skip when the new key already exists.
nonisolated enum LevelMigration {
    /// Marker that the one-time migration has run. One key for both migrations,
    /// so a second launch does not even check legacy keys.
    static let doneKey = "level.migration.done"

    /// Runs both legacy migrations once. Safe to call on every launch; the
    /// second call is a no-op.
    static func runOnce(defaults: UserDefaults = .standard) {
        if defaults.bool(forKey: doneKey) { return }
        FamilySettings.migrateLegacyPins(defaults: defaults)
        PlanStore.migrateLegacyLevels(defaults: defaults)
        defaults.set(true, forKey: doneKey)
    }
}
