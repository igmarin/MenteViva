import XCTest

@testable import MenteViva

/// #143: Number Trail's operators as difficulty steps.
final class NumberTrailQuestionTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private static let draws = 500

    /// Many questions at one level, across the whole streak curve.
    private func questions(_ difficulty: Difficulty, seed: UInt64 = 42) -> [NumberTrailQuestion] {
        var generator = SeededGenerator(state: seed)
        return (0..<Self.draws).map { index in
            NumberTrailQuestion.make(difficulty: difficulty, streak: index % 12, using: &generator)
        }
    }

    private func expected(_ q: NumberTrailQuestion) -> Int {
        switch q.operation {
        case .plus: q.left + q.right
        case .minus: q.left - q.right
        case .times: q.left * q.right
        case .dividedBy: q.left / q.right
        }
    }

    func testGivenEasyWhenManyQuestionsThenOnlyAddition() {
        XCTAssertEqual(Set(questions(Difficulty(level: 2)).map(\.operation)), [.plus])
    }

    func testGivenMediumWhenManyQuestionsThenAddAndSubtractOnlyAndNeverBelowZero() {
        let medium = questions(Difficulty(level: 4))
        XCTAssertEqual(Set(medium.map(\.operation)), [.plus, .minus])
        for q in medium {
            XCTAssertGreaterThanOrEqual(q.answer, 0, q.text)
            if q.operation == .minus { XCTAssertGreaterThan(q.left, q.right, q.text) }
        }
    }

    func testGivenHardWhenManyQuestionsThenAllFourOperatorsAppear() {
        XCTAssertEqual(Set(questions(Difficulty(level: 6)).map(\.operation)), Set(NumberTrailQuestion.Operation.allCases))
    }

    func testGivenHardWhenDivisionThenAlwaysExactWithNonzeroDivisor() {
        let divisions = questions(Difficulty(level: 6)).filter { $0.operation == .dividedBy }
        XCTAssertFalse(divisions.isEmpty)
        for q in divisions {
            XCTAssertNotEqual(q.right, 0, q.text)
            XCTAssertEqual(q.left % q.right, 0, q.text)
            XCTAssertEqual(q.right * q.answer, q.left, q.text)
        }
    }

    func testGivenAnyDifficultyWhenManyQuestionsThenEveryAnswerIsCorrectAndPositive() {
        for difficulty in [Difficulty(level: 2), Difficulty(level: 4), Difficulty(level: 6)] {
            for q in questions(difficulty, seed: 7) {
                XCTAssertEqual(q.answer, expected(q), q.text)
                XCTAssertGreaterThan(q.answer, 0, q.text)
            }
        }
    }

    func testGivenHardWhenTimesOrDivideThenFactorsStayInTheTimesTables() {
        for q in questions(Difficulty(level: 6)) where q.operation == .times || q.operation == .dividedBy {
            let factors = q.operation == .times ? [q.left, q.right] : [q.right, q.answer]
            XCTAssertTrue(factors.allSatisfy { (2...10).contains($0) }, q.text)
        }
    }

    func testGivenAnyAnswerWhenOptionsDealtThenFourDistinctPositiveIncludingTheAnswer() {
        var generator = SeededGenerator(state: 3)
        for answer in 1...100 {
            let options = NumberTrailQuestion.options(for: answer, using: &generator)
            XCTAssertEqual(options.count, 4)
            XCTAssertEqual(Set(options).count, 4)
            XCTAssertTrue(options.contains(answer))
            XCTAssertTrue(options.allSatisfy { $0 > 0 })
        }
    }

    func testGivenEachOperatorWhenShownAndSpokenThenRealSignAndLocalizedWord() {
        let q = NumberTrailQuestion(left: 7, operation: .minus, right: 3, answer: 4)
        XCTAssertEqual(q.text, "7 \u{2212} 3")
        XCTAssertEqual(q.spoken(localize: { "<\($0)>" }), "7 <game.math.operator.minus> 3")
        XCTAssertEqual(
            NumberTrailQuestion.Operation.allCases.map(\.symbol), ["+", "\u{2212}", "\u{00D7}", "\u{00F7}"])
    }

    func testGivenSpanishWhenSpokenThenOperatorWordsAreSpanish() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        AppLanguage.apply("es", to: defaults)
        let words = NumberTrailQuestion.Operation.allCases.map { AppLanguage.localized($0.spokenKey, defaults: defaults) }
        XCTAssertEqual(words, ["más", "menos", "por", "entre"])
    }
}
