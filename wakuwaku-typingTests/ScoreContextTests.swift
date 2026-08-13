import Testing
@testable import wakuwaku_typing

struct ScoreContextTests {
    @Test func roundTripPreservesAllStats() {
        let ctx = ScoreContext(wpm: 142, acc: 99, combo: 48, words: 71, time: 60)
        let decoded = ScoreContext(decoding: ctx.encoded)
        #expect(decoded == ctx)
    }

    @Test func allZeroStatsStillRoundTrip() {
        // 統計が全部0でも「情報あり」として復元できる（バージョンビットが立つため）
        let ctx = ScoreContext(wpm: 0, acc: 0, combo: 0, words: 0, time: 0)
        let decoded = ScoreContext(decoding: ctx.encoded)
        #expect(decoded == ctx)
    }

    @Test func zeroContextDecodesToNil() {
        // 過去の送信分は context=0 → 統計情報なし
        #expect(ScoreContext(decoding: 0) == nil)
    }

    @Test func garbageContextDecodesToNil() {
        #expect(ScoreContext(decoding: -1) == nil)
        #expect(ScoreContext(decoding: Int.min) == nil)
    }

    @Test func outOfRangeValuesAreClamped() {
        let ctx = ScoreContext(wpm: 5000, acc: 250, combo: -5, words: 2000, time: 100_000)
        #expect(ctx.wpm == 1023)
        #expect(ctx.acc == 100)
        #expect(ctx.combo == 0)
        #expect(ctx.words == 1023)
        #expect(ctx.time == 1023)
        // クランプ後の値で正しく往復できる
        #expect(ScoreContext(decoding: ctx.encoded) == ctx)
    }

    @Test func maxValuesFitInPositiveInt() {
        let ctx = ScoreContext(wpm: 1023, acc: 100, combo: 1023, words: 1023, time: 1023)
        #expect(ctx.encoded > 0)
        #expect(ScoreContext(decoding: ctx.encoded) == ctx)
    }
}
