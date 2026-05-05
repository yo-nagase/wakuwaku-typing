import Testing
@testable import wakuwaku_typing

struct ScoreTests {
    @Test func pointsTier1() {
        #expect(ScoreCalculator.points(forCombo: 0) == 1)
        #expect(ScoreCalculator.points(forCombo: 1) == 1)
        #expect(ScoreCalculator.points(forCombo: 2) == 1)
    }

    @Test func pointsTier2() {
        #expect(ScoreCalculator.points(forCombo: 3) == 2)
        #expect(ScoreCalculator.points(forCombo: 7) == 2)
    }

    @Test func pointsTier3() {
        #expect(ScoreCalculator.points(forCombo: 8) == 3)
        #expect(ScoreCalculator.points(forCombo: 14) == 3)
    }

    @Test func pointsTier4() {
        #expect(ScoreCalculator.points(forCombo: 15) == 4)
        #expect(ScoreCalculator.points(forCombo: 24) == 4)
    }

    @Test func pointsTier5() {
        #expect(ScoreCalculator.points(forCombo: 25) == 5)
        #expect(ScoreCalculator.points(forCombo: 39) == 5)
    }

    @Test func pointsTier6() {
        #expect(ScoreCalculator.points(forCombo: 40) == 6)
        #expect(ScoreCalculator.points(forCombo: 100) == 6)
    }

    @Test func multiplierMatchesPoints() {
        for combo in [0, 2, 3, 7, 8, 14, 15, 24, 25, 39, 40, 100] {
            #expect(ScoreCalculator.multiplier(forCombo: combo) == ScoreCalculator.points(forCombo: combo))
        }
    }

    @Test func nextThresholdBoundaries() {
        #expect(ScoreCalculator.nextThreshold(forCombo: 0) == 3)
        #expect(ScoreCalculator.nextThreshold(forCombo: 2) == 3)
        #expect(ScoreCalculator.nextThreshold(forCombo: 3) == 8)
        #expect(ScoreCalculator.nextThreshold(forCombo: 7) == 8)
        #expect(ScoreCalculator.nextThreshold(forCombo: 8) == 15)
        #expect(ScoreCalculator.nextThreshold(forCombo: 14) == 15)
        #expect(ScoreCalculator.nextThreshold(forCombo: 15) == 25)
        #expect(ScoreCalculator.nextThreshold(forCombo: 24) == 25)
        #expect(ScoreCalculator.nextThreshold(forCombo: 25) == 40)
        #expect(ScoreCalculator.nextThreshold(forCombo: 39) == 40)
        #expect(ScoreCalculator.nextThreshold(forCombo: 40) == nil)
        #expect(ScoreCalculator.nextThreshold(forCombo: 999) == nil)
    }

    @Test func currentTierStartBoundaries() {
        #expect(ScoreCalculator.currentTierStart(forCombo: 0) == 0)
        #expect(ScoreCalculator.currentTierStart(forCombo: 2) == 0)
        #expect(ScoreCalculator.currentTierStart(forCombo: 3) == 3)
        #expect(ScoreCalculator.currentTierStart(forCombo: 7) == 3)
        #expect(ScoreCalculator.currentTierStart(forCombo: 8) == 8)
        #expect(ScoreCalculator.currentTierStart(forCombo: 14) == 8)
        #expect(ScoreCalculator.currentTierStart(forCombo: 15) == 15)
        #expect(ScoreCalculator.currentTierStart(forCombo: 24) == 15)
        #expect(ScoreCalculator.currentTierStart(forCombo: 25) == 25)
        #expect(ScoreCalculator.currentTierStart(forCombo: 39) == 25)
        #expect(ScoreCalculator.currentTierStart(forCombo: 40) == 40)
        #expect(ScoreCalculator.currentTierStart(forCombo: 999) == 40)
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

    /// 各閾値の直前と直後で multiplier が +1 ジャンプすることを確認。
    @Test func multiplierJumpsAtEachThreshold() {
        let transitions: [(before: Int, after: Int)] = [
            (2, 3),   // 1x → 2x
            (7, 8),   // 2x → 3x
            (14, 15), // 3x → 4x
            (24, 25), // 4x → 5x
            (39, 40), // 5x → 6x
        ]
        for t in transitions {
            let beforePts = ScoreCalculator.points(forCombo: t.before)
            let afterPts = ScoreCalculator.points(forCombo: t.after)
            #expect(afterPts == beforePts + 1)
        }
    }

    /// 階層内で multiplier が一定であることを確認。
    @Test func multiplierStableWithinTier() {
        let tiers: [ClosedRange<Int>] = [0...2, 3...7, 8...14, 15...24, 25...39]
        for range in tiers {
            let first = ScoreCalculator.points(forCombo: range.lowerBound)
            for c in range {
                #expect(ScoreCalculator.points(forCombo: c) == first)
            }
        }
    }

    /// 最高層 (40+) の挙動が任意の大きな combo でも安定していることを確認。
    @Test func topTierStability() {
        for combo in [40, 41, 50, 100, 999, 10_000] {
            #expect(ScoreCalculator.points(forCombo: combo) == 6)
            #expect(ScoreCalculator.multiplier(forCombo: combo) == 6)
            #expect(ScoreCalculator.nextThreshold(forCombo: combo) == nil)
            #expect(ScoreCalculator.currentTierStart(forCombo: combo) == 40)
        }
    }

    /// 各階層内のすべての combo について不変条件を確認:
    /// - currentTierStart(c) <= c
    /// - nextThreshold(c) があれば c < nextThreshold(c)
    /// - currentTierStart(c) で再計算しても同じ階層始点
    @Test func tierHelpersInvariants() {
        for combo in 0...50 {
            let start = ScoreCalculator.currentTierStart(forCombo: combo)
            #expect(start <= combo)
            #expect(ScoreCalculator.currentTierStart(forCombo: start) == start)
            if let next = ScoreCalculator.nextThreshold(forCombo: combo) {
                #expect(combo < next)
                #expect(start < next)
                // 次の閾値へ進めば階層始点も更新される
                #expect(ScoreCalculator.currentTierStart(forCombo: next) == next)
                // 次の閾値で multiplier が真に増える
                #expect(ScoreCalculator.points(forCombo: next) > ScoreCalculator.points(forCombo: combo))
            }
        }
    }

    /// nextThreshold が nil なのは最高層に到達したときだけであることを確認。
    @Test func nextThresholdNilOnlyAtTopTier() {
        for combo in 0..<40 {
            #expect(ScoreCalculator.nextThreshold(forCombo: combo) != nil)
        }
        #expect(ScoreCalculator.nextThreshold(forCombo: 40) == nil)
    }

    /// ミスで combo=0 にリセットしたときの multiplier が 1x であることを確認。
    /// （combo は GameViewModel で 0 にリセットされ、`points(forCombo: 0)` が呼ばれる経路）
    @Test func multiplierResetsToOneOnMiss() {
        #expect(ScoreCalculator.multiplier(forCombo: 0) == 1)
        #expect(ScoreCalculator.points(forCombo: 0) == 1)
        #expect(ScoreCalculator.nextThreshold(forCombo: 0) == 3)
    }

    /// 連続正解 N 回での累積スコアを再計算し、ランドマークでの値を確認。
    /// `combo` は increment 後の値で `points` に渡されるので、N 回目の正答は `points(forCombo: N)` を加算する。
    @Test func cumulativeScoreLandmarks() {
        // Helper: Σ points(forCombo: i) for i in 1...n
        func cumulative(_ n: Int) -> Int {
            (1...n).map { ScoreCalculator.points(forCombo: $0) }.reduce(0, +)
        }
        // 1..2: 1x×2 = 2
        #expect(cumulative(2) == 2)
        // 1..3: 2 + 2 = 4 (combo 3 は 2x になる)
        #expect(cumulative(3) == 4)
        // 1..7: 1+1+2+2+2+2+2 = 12
        #expect(cumulative(7) == 12)
        // 1..8: 12 + 3 = 15 (combo 8 で 3x)
        #expect(cumulative(8) == 15)
        // 1..14: 15 + 3*6 = 33
        #expect(cumulative(14) == 33)
        // 1..15: 33 + 4 = 37 (combo 15 で 4x)
        #expect(cumulative(15) == 37)
        // 1..24: 37 + 4*9 = 73
        #expect(cumulative(24) == 73)
        // 1..25: 73 + 5 = 78 (combo 25 で 5x)
        #expect(cumulative(25) == 78)
        // 1..39: 78 + 5*14 = 148
        #expect(cumulative(39) == 148)
        // 1..40: 148 + 6 = 154 (combo 40 で 6x)
        #expect(cumulative(40) == 154)
        // 1..50: 154 + 6*10 = 214 (40+ は永続 6x)
        #expect(cumulative(50) == 214)
    }

    /// 進捗バー比率の計算: progress = (combo - tierStart) / (next - tierStart)。
    /// tier 境界、tier 中間、最高層を確認。
    @Test func progressRatioWithinTier() {
        func progress(forCombo combo: Int) -> Double {
            guard let next = ScoreCalculator.nextThreshold(forCombo: combo) else { return 1.0 }
            let start = ScoreCalculator.currentTierStart(forCombo: combo)
            return Double(combo - start) / Double(next - start)
        }
        // tier 開始時は 0.0
        #expect(progress(forCombo: 0) == 0.0)
        #expect(progress(forCombo: 3) == 0.0)
        #expect(progress(forCombo: 8) == 0.0)
        #expect(progress(forCombo: 15) == 0.0)
        #expect(progress(forCombo: 25) == 0.0)
        // tier 中間 (例: combo 5 は 3..<8 のちょうど中間 +1)
        // (5-3)/(8-3) = 2/5 = 0.4
        #expect(progress(forCombo: 5) == 0.4)
        // 最高層は常に 1.0
        #expect(progress(forCombo: 40) == 1.0)
        #expect(progress(forCombo: 100) == 1.0)
    }
}
