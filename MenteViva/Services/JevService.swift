import Foundation

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
}

nonisolated enum Difficulty: Int, Codable {
    case easy = 0, medium = 1, hard = 2

    init(jevScore: Double) {
        let clamped = min(max(jevScore, 0), 2)
        self = Difficulty(rawValue: Int(clamped.rounded())) ?? .medium
    }
}

nonisolated struct DailyPlan: Codable {
    let dayStamp: String              // local "yyyy-MM-dd"; valid only for its day
    let games: [GameID]               // recommended mix, best first
    let difficulty: [GameID: Difficulty]

    /// Deterministic fallback: day-of-year rotation, current difficulty unchanged.
    static func fallback(current: [GameID: Difficulty], dayStamp: String) -> DailyPlan {
        let all = GameID.allCases
        let offset = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        let rotated = (0..<all.count).map { all[($0 + offset) % all.count] }
        return DailyPlan(dayStamp: dayStamp, games: Array(rotated.prefix(3)), difficulty: current)
    }
}

/// Aggregated, anonymized gameplay stats — the entire state that leaves the device:
/// counts and ratios only, no identifiers, no dates, English field names.
nonisolated struct PlayerStateSummary: Codable {
    struct GameStats: Codable {
        let sessionsLast14Days: Int
        let meanAccuracy: Double      // 0...1
        let meanRoundsCompleted: Double
        let daysSinceLastPlayed: Int
        let currentDifficulty: Difficulty
    }
    let games: [String: GameStats]    // keyed by GameID.rawValue
}

enum JevServiceError: Error {
    case badResponse(Int)
}

actor JevService {
    static let shared = JevService()

    private let proxyURL: URL?
    private let session: URLSession
    private let cacheKey = "jev.dailyPlan"

    /// Below this confidence a difficulty Score is ignored and yesterday's
    /// difficulty is kept. Wrong difficulty is the high-stakes error here, so
    /// the gate sits above the docs' 0.5 "genuinely unsure" floor.
    private let difficultyConfidenceThreshold = 0.6
    private let gamesPerDay = 3

    init(proxyURL: URL? = Bundle.main.infoDictionary?["JEV_PROXY_URL"]
            .flatMap { $0 as? String }
            .flatMap { $0.isEmpty ? nil : $0 }
            .flatMap(URL.init(string:)),
         session: URLSession = .shared) {
        self.proxyURL = proxyURL
        self.session = session
    }

    // MARK: - Public API

    /// Today's plan: cache first, otherwise one Jev request, fallback on any failure.
    func dailyPlan(state: PlayerStateSummary,
                   currentDifficulty: [GameID: Difficulty]) async -> DailyPlan {
        let stamp = Self.dayStamp()
        if let cached = cachedPlan(), cached.dayStamp == stamp { return cached }

        let fallback = DailyPlan.fallback(current: currentDifficulty, dayStamp: stamp)
        guard let proxyURL else { return fallback }

        do {
            let answers = try await ask(state: state, proxyURL: proxyURL)
            let plan = Self.makePlan(from: answers,
                                     current: currentDifficulty,
                                     dayStamp: stamp,
                                     gamesPerDay: gamesPerDay,
                                     confidenceFloor: difficultyConfidenceThreshold)
            cache(plan)
            return plan
        } catch {
            return fallback
        }
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
        return DailyPlan(dayStamp: dayStamp, games: Array(ranked.prefix(gamesPerDay)), difficulty: difficulty)
    }

    // MARK: - Cache (UserDefaults, per local day)

    private func cachedPlan() -> DailyPlan? {
        UserDefaults.standard.data(forKey: cacheKey)
            .flatMap { try? JSONDecoder().decode(DailyPlan.self, from: $0) }
    }

    private func cache(_ plan: DailyPlan) {
        if let data = try? JSONEncoder().encode(plan) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    nonisolated static func dayStamp(_ date: Date = .now) -> String {
        let f = DateFormatter()
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

