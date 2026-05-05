import Testing
@testable import wakuwaku_typing

struct ScoreTests {
    @Test func pointsTier1() {
        #expect(ScoreCalculator.points(forCombo: 0) == 1)
        #expect(ScoreCalculator.points(forCombo: 1) == 1)
        #expect(ScoreCalculator.points(forCombo: 4) == 1)
    }

    @Test func pointsTier2() {
        #expect(ScoreCalculator.points(forCombo: 5) == 2)
        #expect(ScoreCalculator.points(forCombo: 9) == 2)
    }

    @Test func pointsTier3() {
        #expect(ScoreCalculator.points(forCombo: 10) == 3)
        #expect(ScoreCalculator.points(forCombo: 19) == 3)
    }

    @Test func pointsTier4() {
        #expect(ScoreCalculator.points(forCombo: 20) == 4)
        #expect(ScoreCalculator.points(forCombo: 29) == 4)
    }

    @Test func pointsTier5() {
        #expect(ScoreCalculator.points(forCombo: 30) == 5)
        #expect(ScoreCalculator.points(forCombo: 100) == 5)
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
