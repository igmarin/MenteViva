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
        Self.lock.lock(); Self.requests.append(request); Self.lock.unlock()
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
        return JevService(proxyURL: url ?? self.url, proxySecret: secret,
                          session: URLSession(configuration: config), defaults: defaults)
    }

    /// stroop ranks first; one answer has an unknown type and one lacks a field.
    private let goodJSON = Data("""
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
}
