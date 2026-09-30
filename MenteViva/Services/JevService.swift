import Foundation
import os

/// Minimal TypeSafe/Jev client for MenteViva. See docs/jev-integration.md.
///
/// Jev is seasoning: it ranks today's game mix and nudges per-game difficulty.
/// Everything degrades to deterministic fallbacks — no network, no proxy, bad
/// response, low confidence: the app behaves identically, just unseasoned.
///
/// The API key never lives on device. Requests go to a tiny proxy
/// (JEV_PROXY_URL in Info.plist) that adds `Authorization: Bearer` server-side
/// and forwards the body verbatim to https://api.typesafe.ai/v1/systemone.

nonisolated enum GameID: String, CaseIterable, Codable {
    case memoryMatch = "memory_match"
    case stroop = "stroop"
    case categoryFluency = "category_fluency"
    case mathStreaks = "math_streaks"
    case quickEyes = "quick_eyes"

    var emoji: String {
        switch self {
        case .memoryMatch: "🧩"
        case .stroop: "🎨"
        case .categoryFluency: "🐾"
        case .mathStreaks: "🔢"
        case .quickEyes: "👀"
        }
    }

    var title: String.LocalizationValue {
        switch self {
        case .memoryMatch: "game.memory.title"
        case .stroop: "game.colorclash.title"
        case .categoryFluency: "game.category.title"
        case .mathStreaks: "game.math.title"
        case .quickEyes: "game.quickeyes.title"
        }
    }
}

nonisolated enum Difficulty: Int, Codable {
    case easy = 0, medium = 1, hard = 2

    init(jevScore: Double) {
        let clamped = min(max(jevScore, 0), 2)
        self = Difficulty(rawValue: Int(clamped.rounded())) ?? .medium
    }

    /// Today's difficulty for a game: medium until Jev has said otherwise. Games
    /// read it once when they open, so it never shifts under the player mid-game.
    static func stored(_ game: GameID) -> Difficulty {
        JevService.storedDifficulty()[game] ?? .medium
    }

    /// Picks the easy/medium/hard value of a per-game knob.
    func pick<T>(_ easy: T, _ medium: T, _ hard: T) -> T {
        switch self {
        case .easy: easy
        case .medium: medium
        case .hard: hard
        }
    }
}

nonisolated struct DailyPlan: Codable, Equatable {
    let dayStamp: String              // local "yyyy-MM-dd"; valid only for its day
    let games: [GameID]               // recommended mix, best first
    let difficulty: [GameID: Difficulty]
}

/// Aggregated, anonymized gameplay stats — the entire state that leaves the device:
/// counts and ratios only, no identifiers, no dates, English field names.
nonisolated struct PlayerStateSummary: Codable {
    struct GameStats: Codable {
        let sessionsLast14Days: Int
        let meanAccuracy: Double?     // 0...1; omitted when no session recorded accuracy
        let meanRoundsCompleted: Double
        let daysSinceLastPlayed: Int
        let currentDifficulty: Difficulty
    }
    let games: [String: GameStats]    // keyed by GameID.rawValue

    /// Builds the summary from recent sessions: sessions older than 14 days are
    /// ignored; a game never played in the window reports 0 sessions and 14 days.
    static func build(from sessions: [GameSession],
                      difficulty: [GameID: Difficulty],
                      now: Date = .now,
                      calendar: Calendar = .current) -> PlayerStateSummary {
        let window = 14
        var games: [String: GameStats] = [:]
        for game in GameID.allCases {
            let mine = sessions.filter {
                $0.gameID == game.rawValue
                    && (calendar.dateComponents([.day], from: $0.playedAt, to: now).day ?? window) < window
            }
            let accuracies = mine.compactMap(\.accuracy)
            let last = mine.map(\.playedAt).max()
            games[game.rawValue] = GameStats(
                sessionsLast14Days: mine.count,
                meanAccuracy: accuracies.isEmpty ? nil : accuracies.reduce(0, +) / Double(accuracies.count),
                meanRoundsCompleted: mine.isEmpty ? 0 : Double(mine.map(\.rounds).reduce(0, +)) / Double(mine.count),
                daysSinceLastPlayed: last.flatMap { calendar.dateComponents([.day], from: $0, to: now).day } ?? window,
                currentDifficulty: difficulty[game] ?? .medium)
        }
        return PlayerStateSummary(games: games)
    }
}

enum JevServiceError: Error {
    case badResponse(Int)
}

actor JevService {
    static let shared = JevService()

    private let proxyURL: URL?
    private let proxySecret: String
    private let session: URLSession
    private let defaults: UserDefaults
    private var inFlight: Task<DailyPlan, Never>?
    private nonisolated static let log = Logger(subsystem: "com.igmarin.MenteViva", category: "jev")
    private let cacheKey = "jev.dailyPlan"
    private nonisolated static let difficultyKey = "jev.difficulty"
    private nonisolated static let changeKey = "jev.difficultyChangedOn"

    /// Below this confidence a difficulty Score is ignored and yesterday's
    /// difficulty is kept. A poor difficulty match is the high-stakes concern
    /// here, so the gate sits above the docs' 0.5 "genuinely unsure" floor.
    private let difficultyConfidenceThreshold = 0.6
    private let gamesPerDay = 3

    init(proxyURL: URL? = Bundle.main.infoDictionary?["JEV_PROXY_URL"]
            .flatMap { $0 as? String }
            .flatMap { $0.isEmpty ? nil : $0 }
            .flatMap(URL.init(string:)),
         proxySecret: String = Bundle.main.infoDictionary?["JEV_PROXY_SECRET"] as? String ?? "",
         session: URLSession = .shared,
         defaults: UserDefaults = .standard) {
        self.proxyURL = proxyURL
        self.proxySecret = proxySecret
        self.session = session
        self.defaults = defaults
    }

    // MARK: - Public API

    /// Today's plan: cache first, otherwise the on-device DailyPolicy (overridden by Jev when a proxy is set).
    /// The plan is cached too, so a failing network is tried once per day, and
    /// concurrent callers share one in-flight request.
    func dailyPlan(state: PlayerStateSummary,
                   currentDifficulty: [GameID: Difficulty],
                   now: Date = .now) async -> DailyPlan {
        let stamp = Self.dayStamp(now)
        if let cached = cachedPlan(), cached.dayStamp == stamp { return cached }
        if let inFlight { return await inFlight.value }

        let task = Task { await self.fetchPlan(state: state, current: currentDifficulty, stamp: stamp) }
        inFlight = task
        let plan = await task.value
        inFlight = nil
        return plan
    }

    private func fetchPlan(state: PlayerStateSummary,
                           current: [GameID: Difficulty],
                           stamp: String) async -> DailyPlan {
        var plan = DailyPolicy.plan(state: state,
                                    lastChange: Self.lastDifficultyChange(defaults: defaults),
                                    dayStamp: stamp)
        if let proxyURL {
            do {
                let answers = try await ask(state: state, proxyURL: proxyURL)
                plan = Self.makePlan(from: answers,
                                     current: current,
                                     dayStamp: stamp,
                                     gamesPerDay: gamesPerDay,
                                     confidenceFloor: difficultyConfidenceThreshold)
            } catch {
                Self.log.info("Jev unavailable, using the on-device plan: \(String(describing: error), privacy: .public)")
            }
        }
        cache(plan)
        return plan
    }

    // MARK: - Jev request (one call, 8 questions: 4 Noul + 4 Score)

    private func ask(state: PlayerStateSummary, proxyURL: URL) async throws -> [String: JevAnswer] {
        var questions: [String: JevQuestion] = [:]
        for game in GameID.allCases {
            questions["include_\(game.rawValue)"] = .noul(
                instructions: "Should \(game.rawValue) be in today's recommended mix for this player?",
                criteria: [
                    "true": "Keeps the day varied, matches recent engagement, or the game has been rested too long",
                    "false": "Played very recently and repeatedly, or the player consistently disengages from it"
                ])
            questions["difficulty_\(game.rawValue)"] = .score(
                instructions: "What difficulty should \(game.rawValue) be set to today?",
                criteria: [
                    "Easy — player is struggling or accuracy dropped recently; reduce cognitive load",
                    "Medium — player is steady; maintain current challenge",
                    "Hard — player consistently succeeds quickly; increase challenge"
                ])
        }

        let body = JevRequest(state: state, model: "jev-latest", questions: questions)
        var urlRequest = URLRequest(url: proxyURL, timeoutInterval: 10)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !proxySecret.isEmpty {
            urlRequest.setValue(proxySecret, forHTTPHeaderField: "X-MenteViva-Key")
        }
        urlRequest.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw JevServiceError.badResponse((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return try JSONDecoder().decode(JevResponse.self, from: data).answers
    }


    // MARK: - Policy in code: answers -> plan

    nonisolated static func makePlan(from answers: [String: JevAnswer],
                         current: [GameID: Difficulty],
                         dayStamp: String,
                         gamesPerDay: Int,
                         confidenceFloor: Double) -> DailyPlan {
        // Mix: rank by P(include). Missing answers sort last; prefix() keeps the
        // mix non-empty even if every probability is low.
        let ranked = GameID.allCases.sorted {
            (answers["include_\($0.rawValue)"]?.noul ?? -1) > (answers["include_\($1.rawValue)"]?.noul ?? -1)
        }
        // Difficulty: apply only confident scores; otherwise keep current.
        var difficulty = current
        for game in GameID.allCases {
            if case let .score(score, confidence)? = answers["difficulty_\(game.rawValue)"],
               confidence >= confidenceFloor {
                difficulty[game] = Difficulty(jevScore: score)
            }
        }
        let count = min(max(gamesPerDay, 0), ranked.count)
        return DailyPlan(dayStamp: dayStamp, games: Array(ranked.prefix(count)), difficulty: difficulty)
    }

    // MARK: - Cache (UserDefaults, per local day)

    private func cachedPlan() -> DailyPlan? {
        defaults.data(forKey: cacheKey)
            .flatMap { try? JSONDecoder().decode(DailyPlan.self, from: $0) }
    }

    private func cache(_ plan: DailyPlan) {
        if let data = try? JSONEncoder().encode(plan) {
            defaults.set(data, forKey: cacheKey)
        }
        let before = Self.storedDifficulty(defaults: defaults)
        var changed = Self.lastDifficultyChange(defaults: defaults)
        for (game, level) in plan.difficulty where before[game] != level { changed[game] = plan.dayStamp }
        if let data = try? JSONEncoder().encode(Dictionary(uniqueKeysWithValues: changed.map { ($0.key.rawValue, $0.value) })) {
            defaults.set(data, forKey: Self.changeKey)
        }
        if let data = try? JSONEncoder().encode(Dictionary(uniqueKeysWithValues: plan.difficulty.map { ($0.key.rawValue, $0.value.rawValue) })) {
            defaults.set(data, forKey: Self.difficultyKey)
        }
    }

    /// Last difficulty Jev set per game (medium for a new player). Read by the
    /// games and by Home; only changes when a new daily plan is cached.
    nonisolated static func storedDifficulty(defaults: UserDefaults = .standard) -> [GameID: Difficulty] {
        let raw = defaults.data(forKey: difficultyKey)
            .flatMap { try? JSONDecoder().decode([String: Int].self, from: $0) } ?? [:]
        return Dictionary(uniqueKeysWithValues: GameID.allCases.map { game in
            (game, raw[game.rawValue].flatMap(Difficulty.init(rawValue:)) ?? .medium)
        })
    }

    /// Day stamp of each game's last difficulty change; DailyPolicy holds it for a week.
    nonisolated static func lastDifficultyChange(defaults: UserDefaults = .standard) -> [GameID: String] {
        let raw = defaults.data(forKey: changeKey)
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
        return Dictionary(uniqueKeysWithValues: raw.compactMap { key, stamp in GameID(rawValue: key).map { ($0, stamp) } })
    }

    nonisolated static func dayStamp(_ date: Date = .now) -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - Wire models (mirror https://api.typesafe.ai/v1/systemone)

nonisolated private struct JevRequest: Encodable {
    let state: PlayerStateSummary   // JSON-object state
    let model: String
    let questions: [String: JevQuestion]
}

nonisolated private enum JevQuestion: Encodable {
    case noul(instructions: String, criteria: [String: String])
    case score(instructions: String, criteria: [String])

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .noul(instructions, criteria):
            try c.encode("noul", forKey: .type)
            try c.encode(instructions, forKey: .instructions)
            try c.encode(criteria, forKey: .criteria)
        case let .score(instructions, criteria):
            try c.encode("score", forKey: .type)
            try c.encode(instructions, forKey: .instructions)
            try c.encode(criteria, forKey: .criteria)
        }
    }

    private enum CodingKeys: String, CodingKey { case type, instructions, criteria }
}

nonisolated private struct JevResponse: Decodable {
    let answers: [String: JevAnswer]

    /// One answer we cannot read (unknown type, missing field) is dropped, not
    /// fatal: the rest still count and the missing one falls back per question.
    private struct Lossy: Decodable {
        let value: JevAnswer?
        init(from decoder: Decoder) throws { value = try? JevAnswer(from: decoder) }
    }

    private enum CodingKeys: String, CodingKey { case answers }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        answers = try c.decode([String: Lossy].self, forKey: .answers).compactMapValues(\.value)
    }
}

nonisolated enum JevAnswer: Decodable {
    case noul(probability: Double)
    case score(score: Double, confidence: Double)
    case choice(choice: String, confidence: Double)   // unused today; decoded for completeness

    var noul: Double? {
        if case let .noul(p) = self { return p }
        return nil
    }

    private enum CodingKeys: String, CodingKey { case type, noul, score, confidence, choice }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(String.self, forKey: .type) {
        case "noul":
            self = .noul(probability: try c.decode(Double.self, forKey: .noul))
        case "score":
            self = .score(score: try c.decode(Double.self, forKey: .score),
                          confidence: try c.decode(Double.self, forKey: .confidence))
        case "choice":
            self = .choice(choice: try c.decode(String.self, forKey: .choice),
                           confidence: try c.decode(Double.self, forKey: .confidence))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: c,
                                                   debugDescription: "unknown answer type")
        }
    }
}
