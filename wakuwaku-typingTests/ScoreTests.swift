import Testing
@testable import wakuwaku_typing

struct ScoreTests {
    @Test func zeroAccuracyZeroScore() {
        #expect(ScoreCalculator.score(wpm: 100, accuracyPercent: 0, combo: 50) == 0)
    }

    @Test func perfectAccuracyNoCombo() {
        // 60 wpm × 1.0² × 1.0 = 60
        #expect(ScoreCalculator.score(wpm: 60, accuracyPercent: 100, combo: 0) == 60)
    }

    @Test func perfectAccuracyWithCombo20() {
        // 60 × 1 × (1 + 20/20) = 120
        #expect(ScoreCalculator.score(wpm: 60, accuracyPercent: 100, combo: 20) == 120)
    }

    @Test func partialAccuracy() {
        // 80 × 0.81 × 1.5 = 97.2 → 97
        #expect(ScoreCalculator.score(wpm: 80, accuracyPercent: 90, combo: 10) == 97)
    }

    @Test func rankBoundaries() {
        #expect(ScoreCalculator.rank(for: 300) == .s)
        #expect(ScoreCalculator.rank(for: 299) == .a)
        #expect(ScoreCalculator.rank(for: 200) == .a)
        #expect(ScoreCalculator.rank(for: 199) == .b)
        #expect(ScoreCalculator.rank(for: 120) == .b)
        #expect(ScoreCalculator.rank(for: 119) == .c)
        #expect(ScoreCalculator.rank(for: 60) == .c)
        #expect(ScoreCalculator.rank(for: 59) == .d)
        #expect(ScoreCalculator.rank(for: 0) == .d)
    }
}
