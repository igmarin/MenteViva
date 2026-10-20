import Foundation

/// One Number Trail question (#143). Operators arrive as difficulty steps, not a
/// random mix: easy adds, medium also subtracts (never below one), hard also
/// multiplies and divides (always exact, small factors).
nonisolated struct NumberTrailQuestion: Equatable {
    enum Operation: CaseIterable {
        case plus
        case minus
        case times
        case dividedBy

        /// What the screen shows: the real minus, times and division signs.
        var symbol: String {
            switch self {
            case .plus: "+"
            case .minus: "\u{2212}"
            case .times: "\u{00D7}"
            case .dividedBy: "\u{00F7}"
            }
        }

        /// The word VoiceOver and the speaker button say, in EN or ES.
        var spokenKey: String {
            switch self {
            case .plus: "game.math.operator.plus"
            case .minus: "game.math.operator.minus"
            case .times: "game.math.operator.times"
            case .dividedBy: "game.math.operator.dividedBy"
            }
        }
    }

    let left: Int
    let operation: Operation
    let right: Int
    let answer: Int

    var text: String { "\(left) \(operation.symbol) \(right)" }

    /// "7 minus 3" / "7 menos 3": symbols alone are not read reliably in Spanish.
    func spoken(localize: (String) -> String) -> String {
        "\(left) \(localize(operation.spokenKey)) \(right)"
    }

    /// Same, in the app's chosen language. `AppLanguage` is main-actor isolated.
    @MainActor
    func spoken() -> String {
        spoken(localize: { AppLanguage.localized($0) })
    }

    static func operations(for difficulty: Difficulty) -> [Operation] {
        difficulty.pick([.plus], [.plus, .minus], Operation.allCases)
    }

    /// Largest sum (and largest number subtracted from): easy stays small, hard
    /// starts bigger; medium is the original curve. Grows gently with the streak.
    static func maxSum(streak: Int, difficulty: Difficulty) -> Int {
        let start = difficulty.pick(10, 10, 20)
        let cap = difficulty.pick(20, 50, 50)
        return min(start + streak * 5, cap)
    }

    /// Largest factor for × and ÷: the times tables, from 5 up to 10 with the streak.
    static func maxFactor(streak: Int) -> Int {
        min(5 + streak, 10)
    }

    static func make<G: RandomNumberGenerator>(
        difficulty: Difficulty, streak: Int, using generator: inout G
    ) -> NumberTrailQuestion {
        let operation = operations(for: difficulty).randomElement(using: &generator) ?? .plus
        switch operation {
        case .plus, .minus:
            let total = maxSum(streak: streak, difficulty: difficulty)
            let a = Int.random(in: 1...(total - 1), using: &generator)
            let b = Int.random(in: 1...(total - a), using: &generator)
            // Subtraction is the sum backwards, so the larger number comes first.
            return operation == .plus
                ? NumberTrailQuestion(left: a, operation: .plus, right: b, answer: a + b)
                : NumberTrailQuestion(left: a + b, operation: .minus, right: b, answer: a)
        case .times, .dividedBy:
            let factors = 2...maxFactor(streak: streak)
            let a = Int.random(in: factors, using: &generator)
            let b = Int.random(in: factors, using: &generator)
            // Division is built from a product, so it is always exact and never by zero.
            return operation == .times
                ? NumberTrailQuestion(left: a, operation: .times, right: b, answer: a * b)
                : NumberTrailQuestion(left: a * b, operation: .dividedBy, right: b, answer: a)
        }
    }

    /// The answer plus three near neighbours (±1 to 3), all above zero, shuffled.
    static func options<G: RandomNumberGenerator>(for answer: Int, using generator: inout G) -> [Int] {
        var pool = [answer]
        while pool.count < 4 {
            let offset = Int.random(in: 1...3, using: &generator) * (Bool.random(using: &generator) ? 1 : -1)
            let candidate = answer + offset
            if candidate > 0, !pool.contains(candidate) { pool.append(candidate) }
        }
        return pool.shuffled(using: &generator)
    }
}
