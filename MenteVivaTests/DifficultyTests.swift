import XCTest

@testable import MenteViva

/// Levels 1–10 base (#197): the level type, one-way migration, bridge bands.
final class DifficultyTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "DifficultyTests")
        defaults.removePersistentDomain(forName: "DifficultyTests")
    }

    func testGivenLegacyDifficultyRawValuesWhenReadThenLevelsAreTwoFourSix() {
        let easy = GameSession(gameID: .stroop, score: 0, rounds: 1, durationSeconds: 1)
        easy.difficulty = 0
        let medium = GameSession(gameID: .stroop, score: 0, rounds: 1, durationSeconds: 1)
        medium.difficulty = 1
        let hard = GameSession(gameID: .stroop, score: 0, rounds: 1, durationSeconds: 1)
        hard.difficulty = 2
        let unrecorded = GameSession(gameID: .stroop, score: 0, rounds: 1, durationSeconds: 1)
        unrecorded.difficulty = -1
        XCTAssertEqual(easy.resolvedLevel, Difficulty(level: 2))
        XCTAssertEqual(medium.resolvedLevel, Difficulty(level: 4))
        XCTAssertEqual(hard.resolvedLevel, Difficulty(level: 6))
        XCTAssertNil(unrecorded.resolvedLevel)
    }

    func testGivenNewSessionWhenRecordedThenLevelIsStored() {
        let session = GameSession(
            gameID: .stroop, score: 0, rounds: 1, durationSeconds: 1,
            difficulty: Difficulty(level: 7))
        XCTAssertEqual(session.level, 7)
        XCTAssertEqual(session.resolvedLevel, Difficulty(level: 7))
    }

    func testGivenOldPinKeyWhenPinnedReadThenMigratedOnceToNewKey() {
        defaults.set(2, forKey: "difficulty.pin.quick_eyes")
        LevelMigration.runOnce(defaults: defaults)
        XCTAssertEqual(FamilySettings.pinned(defaults: defaults), [.quickEyes: Difficulty(level: 6)])
        XCTAssertEqual(defaults.integer(forKey: FamilySettings.pinKey(.quickEyes)), 6)
        // Migrated once: later changes under the old key no longer apply.
        defaults.set(0, forKey: "difficulty.pin.quick_eyes")
        LevelMigration.runOnce(defaults: defaults)
        XCTAssertEqual(FamilySettings.pinned(defaults: defaults), [.quickEyes: Difficulty(level: 6)])
    }

    func testGivenOldPlanKeyWhenStoredDifficultyReadThenMigratedToNewKey() {
        defaults.set(
            try! JSONEncoder().encode(["quick_eyes": 2]), forKey: "jev.difficulty")
        LevelMigration.runOnce(defaults: defaults)
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.quickEyes], Difficulty(level: 6))
        XCTAssertEqual(
            PlanStore.storedDifficulty(defaults: defaults)[.stroop], Difficulty(level: 4),
            "games without a saved level start at 4")
    }

    func testGivenOutOfRangeLevelWhenCreatedThenClampedToOneThroughTen() {
        XCTAssertEqual(Difficulty(level: 0).level, 1)
        XCTAssertEqual(Difficulty(level: -40).level, 1)
        XCTAssertEqual(Difficulty(level: 11).level, 10)
        XCTAssertEqual(Difficulty(level: 400).level, 10)
        XCTAssertEqual(Difficulty(level: 1).level, 1)
        XCTAssertEqual(Difficulty(level: 10).level, 10)
    }

    func testGivenLevelsOneToTenWhenBridgedThenEasyMediumHardBands() {
        let bands = (1...10).map { Difficulty(level: $0).pick("easy", "medium", "hard") }
        XCTAssertEqual(
            bands,
            ["easy", "easy", "easy", "medium", "medium"] + Array(repeating: "hard", count: 5))
    }

    func testGivenTenValueTableWhenValuesThenPicksByLevel() {
        let table = Array(1...10)
        for level in 1...10 {
            XCTAssertEqual(Difficulty(level: level).values(table), level)
        }
    }

    func testGivenLegacyKeysWhenRunOnceTwiceThenMigratedOnce() {
        defaults.set(1, forKey: "difficulty.pin.quick_eyes")
        defaults.set(1, forKey: "difficulty.pin.stroop")
        defaults.set(try! JSONEncoder().encode(["quick_eyes": 1, "stroop": 2]), forKey: "jev.difficulty")
        LevelMigration.runOnce(defaults: defaults)
        XCTAssertEqual(
            FamilySettings.pinned(defaults: defaults),
            [
                .quickEyes: Difficulty(level: 4), .stroop: Difficulty(level: 4),
            ])
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.quickEyes], Difficulty(level: 4))
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.stroop], Difficulty(level: 6))
        XCTAssertTrue(defaults.bool(forKey: LevelMigration.doneKey))
        // Second run changes nothing, even if legacy keys change underneath.
        defaults.set(0, forKey: "difficulty.pin.quick_eyes")
        defaults.set(try! JSONEncoder().encode(["quick_eyes": 0]), forKey: "jev.difficulty")
        LevelMigration.runOnce(defaults: defaults)
        XCTAssertEqual(FamilySettings.pinned(defaults: defaults)[.quickEyes], Difficulty(level: 4))
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.quickEyes], Difficulty(level: 4))
    }

    func testGivenMigratedStoreWhenPinnedReadThenNoWrites() {
        defaults.set(6, forKey: FamilySettings.pinKey(.quickEyes))
        defaults.set(true, forKey: LevelMigration.doneKey)
        let keysBefore = Set(defaults.dictionaryRepresentation().keys)
        _ = FamilySettings.pinned(defaults: defaults)
        _ = PlanStore.storedDifficulty(defaults: defaults)
        let keysAfter = Set(defaults.dictionaryRepresentation().keys)
        XCTAssertEqual(keysBefore, keysAfter, "reads must not create new keys after migration")
    }

    func testGivenDifficultyLevelKeyWhenCatalogReadThenItHasEnglishAndSpanish() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(json["strings"] as? [String: Any])
        let entry = try XCTUnwrap(strings["difficulty.level"] as? [String: Any])
        let localizations = try XCTUnwrap(entry["localizations"] as? [String: [String: [String: String]]])
        XCTAssertEqual(localizations["en"]?["stringUnit"]?["value"], "Level %lld")
        XCTAssertEqual(localizations["es"]?["stringUnit"]?["value"], "Nivel %lld")
    }
}
