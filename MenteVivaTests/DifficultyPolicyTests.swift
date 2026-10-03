import XCTest

@testable import MenteViva

/// Policy: a Jev score is a continuous 0...2 signal that we clamp and round
/// into the discrete Difficulty the games understand.
final class DifficultyPolicyTests: XCTestCase {

    func testGivenScoreBelowHalfWhenMappedThenRoundsDownToEasy() {
        XCTAssertEqual(Difficulty(jevScore: 0.49), .easy)
    }

    func testGivenScoreAtHalfWhenMappedThenRoundsUpToMedium() {
        XCTAssertEqual(Difficulty(jevScore: 0.5), .medium)
    }

    func testGivenScoreJustBelowOnePointFiveWhenMappedThenStaysMedium() {
        XCTAssertEqual(Difficulty(jevScore: 1.49), .medium)
    }

    func testGivenScoreAtOnePointFiveWhenMappedThenRoundsUpToHard() {
        XCTAssertEqual(Difficulty(jevScore: 1.5), .hard)
    }

    func testGivenScoreAboveRangeWhenMappedThenClampsToHard() {
        XCTAssertEqual(Difficulty(jevScore: 9), .hard)
    }

    func testGivenNegativeScoreWhenMappedThenClampsToEasy() {
        XCTAssertEqual(Difficulty(jevScore: -1), .easy)
    }
}
