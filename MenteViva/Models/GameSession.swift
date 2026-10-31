import Foundation
import OSLog
import SwiftData

/// The saved games' model. Always the newest schema's copy: views and services never name a
/// version (#419).
typealias GameSession = SchemaV1.GameSession

/// Today's model, frozen as version 1 (#419). A store opens only with a model it matches, so with
/// a migration plan an edited model leaves every saved store unopenable and play falls back to
/// memory on every launch (#124). Never edit `SchemaV1.GameSession`: to change the model, add
/// `SchemaV2` with its own nested copy holding the change, point the `GameSession` alias at it, and
/// add V2 plus a stage to `SessionMigrationPlan`. V1 stays as it is, so old stores still open.
nonisolated enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [GameSession.self] }

    /// CloudKit mirroring audit: no unique constraints, no relationships, and
    /// every property has a default — satisfies SwiftData + CloudKit constraints.
    ///
    /// Uniform semantics (#58), same for every game:
    /// - `rounds`: rounds/items the session was made of (Memory: pairs), not taps.
    /// - `attempts`: answers or picks the player made (Memory: moves).
    /// - `correct`: how many of those attempts were right.
    /// Sessions saved before these fields existed have `attempts == 0` and are
    /// skipped when averaging (`accuracy` is nil), never counted as 0%.
    @Model
    final class GameSession {
        var gameID: String = ""
        var score: Int = 0
        var rounds: Int = 0
        var durationSeconds: Int = 0
        var correct: Int = 0
        var attempts: Int = 0
        var playedAt: Date = Date.now
        /// Difficulty the game was played at (#107); -1 for sessions saved before
        /// it was recorded, which never count toward a level trend. Kept for old
        /// rows only: new sessions write `level` (#197, lightweight migration).
        var difficulty: Int = -1
        /// Level the game was played at, 1...10; 0 means not recorded, so rows
        /// saved before levels existed keep reading through `difficulty`.
        var level: Int = 0

        /// 0...1, or nil when the session predates accuracy tracking.
        var accuracy: Double? {
            attempts > 0 ? min(Double(correct) / Double(attempts), 1) : nil
        }

        /// The level this session counts as: the recorded level when present,
        /// else a migrated legacy value (easy/medium/hard read as 2/4/6), else
        /// nil for sessions saved before any difficulty was recorded (#197).
        /// Used by `PlayerStateSummary.recentAccuracies` and `LevelPolicy.shouldOffer`
        /// to decide offers, and fed by `PlanStore.storedDifficulty` / `LevelMigration`.
        var resolvedLevel: Difficulty? {
            if level > 0 { return Difficulty(level: level) }
            guard (0...2).contains(difficulty) else { return nil }
            return Difficulty(level: [2, 4, 6][difficulty])
        }

        /// The game this session belongs to; "memory" is Memory Lane's pre-#57 ID.
        var game: GameID? { GameID(rawValue: gameID) ?? (gameID == "memory" ? .memoryMatch : nil) }

        init(
            gameID: GameID, score: Int = 0, rounds: Int, durationSeconds: Int,
            correct: Int = 0, attempts: Int = 0, difficulty: Difficulty? = nil
        ) {
            self.gameID = gameID.rawValue
            self.score = score
            self.rounds = rounds
            self.durationSeconds = durationSeconds
            self.correct = correct
            self.attempts = attempts
            self.level = difficulty?.level ?? 0
            self.playedAt = .now
        }
    }
}

extension Sequence<GameSession> {
    /// Mean accuracy of the sessions that recorded one; nil when none did (#122).
    nonisolated var meanAccuracy: Double? {
        let values = compactMap(\.accuracy)
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
}

extension ModelContext {
    /// Inserts and saves at once (#106): a finished game must survive the app
    /// being closed before SwiftData's periodic autosave runs. A failed save is
    /// logged, never shown — play is never interrupted. A game in its warm-up (#213) settles its
    /// level here, so the next session, even the same day, starts where it should.
    func record(_ session: GameSession) {
        insert(session)
        do {
            try HotPath.measure("session.save") { try save() }
        } catch {
            Logger(subsystem: "com.igmarin.MenteViva", category: "store")
                .error("Could not save session: \(String(describing: error), privacy: .public)")
        }
        if let game = session.game {
            WarmUpStore.sessionFinished(game: game, accuracy: session.accuracy, today: PlanStore.dayStamp())
        }
    }

    /// Every game with at least one saved session, ever, so a new start pace leaves it alone (#419).
    /// Nil when the store can't be read: the caller then changes nothing.
    func playedGames() -> Set<GameID>? {
        var all = FetchDescriptor<GameSession>()
        all.propertiesToFetch = [\.gameID]
        return (try? fetch(all)).map { Set($0.compactMap(\.game)) }
    }
}

/// Every model version in order, and how to move between them. One version so far, so no stages.
nonisolated enum SessionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
