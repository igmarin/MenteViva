import XCTest

@testable import MenteViva

/// URLProtocol stub: the only "network" these tests see.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (Int, Data))?
    nonisolated(unsafe) static var requests: [URLRequest] = []
    private static let lock = NSLock()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
    override func startLoading() {
        Self.lock.lock()
        Self.requests.append(request)
        Self.lock.unlock()
        let (status, data) = Self.handler?(request) ?? (500, Data())
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}

final class JevServiceTests: XCTestCase {
    private let url = URL(string: "https://proxy.example/jev")!
    private var defaults: UserDefaults!
    private let state = PlayerStateSummary(games: [:])
    private let medium = Dictionary(uniqueKeysWithValues: GameID.allCases.map { ($0, Difficulty.medium) })

    override func setUp() {
        defaults = UserDefaults(suiteName: "JevServiceTests")!
        defaults.removePersistentDomain(forName: "JevServiceTests")
        StubURLProtocol.requests = []
        StubURLProtocol.handler = nil
    }

    private func service(secret: String = "", url: URL? = nil) -> JevService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return JevService(
            proxyURL: url ?? self.url, proxySecret: secret,
            session: URLSession(configuration: config), defaults: defaults)
    }

    /// stroop ranks first; one answer has an unknown type and one lacks a field.
    private let goodJSON = Data(
        """
        {"answers": {
          "include_stroop": {"type": "noul", "noul": 0.99},
          "include_quick_eyes": {"type": "mystery", "x": 1},
          "difficulty_stroop": {"type": "score", "score": 1.9, "confidence": 0.9},
          "difficulty_quick_eyes": {"type": "score", "score": 1.9}
        }}
        """.utf8)

    func testGivenHalfGoodResponseWhenPlanThenGoodAnswersStillCount() async {
        StubURLProtocol.handler = { _ in (200, self.goodJSON) }
        let plan = await service().dailyPlan(state: state, currentDifficulty: medium)
        XCTAssertEqual(plan.games.first, .stroop)
        XCTAssertEqual(plan.difficulty[.stroop], .hard)
        XCTAssertEqual(plan.difficulty[.quickEyes], .medium)
    }

    func testGivenCachedPlanForTodayWhenPlanThenNoNetworkCall() async {
        StubURLProtocol.handler = { _ in (200, self.goodJSON) }
        let svc = service()
        _ = await svc.dailyPlan(state: state, currentDifficulty: medium)
        _ = await svc.dailyPlan(state: state, currentDifficulty: medium)
        XCTAssertEqual(StubURLProtocol.requests.count, 1)
    }

    func testGivenCachedPlanFromYesterdayWhenPlanThenAsksAgain() async {
        StubURLProtocol.handler = { _ in (200, self.goodJSON) }
        let svc = service()
        let yesterday = Date.now.addingTimeInterval(-86_400 * 2)
        _ = await svc.dailyPlan(state: state, currentDifficulty: medium, now: yesterday)
        _ = await svc.dailyPlan(state: state, currentDifficulty: medium)
        XCTAssertEqual(StubURLProtocol.requests.count, 2)
    }

    func testGivenServerErrorWhenPlanThenFallbackIsCachedAndNotRetried() async {
        StubURLProtocol.handler = { _ in (503, Data()) }
        let svc = service()
        let first = await svc.dailyPlan(state: state, currentDifficulty: medium)
        let second = await svc.dailyPlan(state: state, currentDifficulty: medium)
        XCTAssertEqual(first.games.count, 3)
        XCTAssertEqual(first.games, second.games)
        XCTAssertEqual(StubURLProtocol.requests.count, 1)
    }

    func testGivenConcurrentCallsWhenPlanThenOneRequest() async {
        StubURLProtocol.handler = { _ in (200, self.goodJSON) }
        let svc = service()
        async let a = svc.dailyPlan(state: state, currentDifficulty: medium)
        async let b = svc.dailyPlan(state: state, currentDifficulty: medium)
        _ = await (a, b)
        XCTAssertEqual(StubURLProtocol.requests.count, 1)
    }

    func testGivenSecretWhenPlanThenHeaderSentAndOmittedWhenEmpty() async {
        StubURLProtocol.handler = { _ in (200, self.goodJSON) }
        _ = await service(secret: "s3cret").dailyPlan(state: state, currentDifficulty: medium)
        XCTAssertEqual(StubURLProtocol.requests.last?.value(forHTTPHeaderField: "X-MenteViva-Key"), "s3cret")

        defaults.removePersistentDomain(forName: "JevServiceTests")
        _ = await service().dailyPlan(state: state, currentDifficulty: medium)
        XCTAssertNil(StubURLProtocol.requests.last?.value(forHTTPHeaderField: "X-MenteViva-Key"))
    }

    // MARK: - Archived live pairs (docs/jev-json/011, 014): pin the real wire contract

    private func archived(_ name: String) throws -> Data {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: root.appendingPathComponent("docs/jev-json/\(name)"))
    }

    func testGivenArchivedLiveResponseWhenPlanThenMixAndDifficultyMatchJevsAnswers() async throws {
        let response = try archived("011-daily-plan.response.json")
        StubURLProtocol.handler = { _ in (200, response) }
        let plan = await service().dailyPlan(state: state, currentDifficulty: medium)
        // Noul: quick_eyes .75, category_fluency .73, memory_match .63 lead the ranking.
        XCTAssertEqual(plan.games, [.quickEyes, .categoryFluency, .memoryMatch])
        XCTAssertEqual(plan.difficulty[.stroop], .easy)  // 0.07 @ 0.89
        XCTAssertEqual(plan.difficulty[.mathStreaks], .easy)  // 0.18 @ 0.73
        XCTAssertEqual(plan.difficulty[.categoryFluency], .medium)
        XCTAssertEqual(plan.difficulty[.memoryMatch], .medium)
        XCTAssertEqual(plan.difficulty[.quickEyes], .medium)  // 0.70 @ 0.52 is under the 0.6 gate
    }

    func testGivenAppRequestWhenSentThenQuestionKeysMatchArchivedLiveRequest() async throws {
        let archivedRequest = try JSONSerialization.jsonObject(with: archived("014-daily-plan.request.json")) as? [String: Any]
        let archivedKeys = Set((archivedRequest?["questions"] as? [String: Any] ?? [:]).keys)
        StubURLProtocol.handler = { _ in (200, Data("{\"answers\":{}}".utf8)) }
        _ = await service().dailyPlan(state: state, currentDifficulty: medium)
        let req = try XCTUnwrap(StubURLProtocol.requests.first)
        let body = try XCTUnwrap(
            req.httpBody
                ?? req.httpBodyStream.map { s -> Data in
                    s.open()
                    defer { s.close() }
                    var d = Data()
                    var buf = [UInt8](repeating: 0, count: 4096)
                    while s.hasBytesAvailable {
                        let n = s.read(&buf, maxLength: 4096)
                        if n <= 0 { break }
                        d.append(buf, count: n)
                    }
                    return d
                })
        let sent = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        // 014 is the current contract: include_ for all six games, difficulty_ only for the
        // five with levels (Remember Together has none), so 11 keys and no compensation here.
        XCTAssertEqual(Set((sent?["questions"] as? [String: Any] ?? [:]).keys), archivedKeys)
        XCTAssertEqual(archivedKeys.count, 11)
        XCTAssertEqual(sent?["model"] as? String, "jev-latest")
    }
}

/// With no proxy the service is pure on-device policy (#101): no request, hold recorded.
final class JevServiceOnDeviceTests: XCTestCase {
    func testGivenNoProxyWhenPlanThenPolicyPlanNoRequestAndChangeRecorded() async {
        let defaults = UserDefaults(suiteName: "JevServiceOnDeviceTests")!
        defaults.removePersistentDomain(forName: "JevServiceOnDeviceTests")
        StubURLProtocol.requests = []
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let service = JevService(
            proxyURL: nil, proxySecret: "",
            session: URLSession(configuration: config), defaults: defaults)
        let struggling = PlayerStateSummary.GameStats(
            sessionsLast14Days: 2, meanAccuracy: 0.4,
            meanRoundsCompleted: 10, daysSinceLastPlayed: 1, currentDifficulty: .medium)
        let state = PlayerStateSummary(games: [GameID.stroop.rawValue: struggling])
        let medium = Dictionary(uniqueKeysWithValues: GameID.allCases.map { ($0, Difficulty.medium) })

        let plan = await service.dailyPlan(
            state: state, currentDifficulty: medium,
            now: Date(timeIntervalSince1970: 1_790_000_000))

        XCTAssertEqual(plan.difficulty[.stroop], .easy)
        XCTAssertEqual(plan, DailyPolicy.plan(state: state, dayStamp: plan.dayStamp))
        XCTAssertTrue(StubURLProtocol.requests.isEmpty, "no proxy URL means no network request")
        XCTAssertEqual(PlanStore.storedDifficulty(defaults: defaults)[.stroop], .easy)
        XCTAssertEqual(PlanStore.lastDifficultyChange(defaults: defaults)[.stroop], plan.dayStamp)
        XCTAssertNil(PlanStore.lastDifficultyChange(defaults: defaults)[.memoryMatch])
    }
}
