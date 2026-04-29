import Testing
@testable import wakuwaku_typing

struct KanaMatcherTests {
    @Test func directKanaMatch() {
        var m = KanaMatcher(target: "ねこ")
        #expect(m.expectedNext == "ね")
        #expect(m.ingest("ね") == .correct)
        #expect(m.done == "ね")
        #expect(m.expectedNext == "こ")
        #expect(m.ingest("こ") == .complete)
        #expect(m.isComplete)
    }

    @Test func wrongKanaOutsideCycle() {
        var m = KanaMatcher(target: "ねこ")
        #expect(m.ingest("か") == .wrong)
        #expect(m.done == "")
        #expect(m.pending == nil)
    }

    @Test func dakutenViaPendingThenModifier() {
        // target: が — type か, then modifier
        var m = KanaMatcher(target: "が")
        #expect(m.ingest("か") == .pending)
        #expect(m.pending == "か")
        #expect(m.done == "")
        #expect(m.applyModifier() == .complete)
        #expect(m.done == "が")
        #expect(m.pending == nil)
    }

    @Test func tsuSmallSokuonViaModifier() {
        // target: っ — type つ, modifier (つ→づ), modifier (づ→っ)
        var m = KanaMatcher(target: "っ")
        #expect(m.ingest("つ") == .pending)
        #expect(m.applyModifier() == .pending)  // づ
        #expect(m.pending == "づ")
        #expect(m.applyModifier() == .complete)  // っ matches
        #expect(m.done == "っ")
    }

    @Test func handakutenForPa() {
        // target: ぱ — type は, modifier (は→ば), modifier (ば→ぱ)
        var m = KanaMatcher(target: "ぱ")
        #expect(m.ingest("は") == .pending)
        #expect(m.applyModifier() == .pending)  // ば
        #expect(m.pending == "ば")
        #expect(m.applyModifier() == .complete)  // ぱ matches
        #expect(m.done == "ぱ")
    }

    @Test func nekoNiKoban() {
        // ねこにこばん
        var m = KanaMatcher(target: "ねこにこばん")
        #expect(m.ingest("ね") == .correct)
        #expect(m.ingest("こ") == .correct)
        #expect(m.ingest("に") == .correct)
        #expect(m.ingest("こ") == .correct)
        // ば: type は, then modifier
        #expect(m.ingest("は") == .pending)
        #expect(m.applyModifier() == .correct)  // ば matches
        #expect(m.ingest("ん") == .complete)
        #expect(m.isComplete)
    }

    @Test func gakkou() {
        // がっこう
        var m = KanaMatcher(target: "がっこう")
        // が
        #expect(m.ingest("か") == .pending)
        #expect(m.applyModifier() == .correct)
        // っ
        #expect(m.ingest("つ") == .pending)
        #expect(m.applyModifier() == .pending)  // づ
        #expect(m.applyModifier() == .correct)  // っ
        // こ
        #expect(m.ingest("こ") == .correct)
        // う
        #expect(m.ingest("う") == .complete)
    }

    @Test func shippai() {
        // しっぱい
        var m = KanaMatcher(target: "しっぱい")
        #expect(m.ingest("し") == .correct)
        // っ
        #expect(m.ingest("つ") == .pending)
        #expect(m.applyModifier() == .pending)  // づ
        #expect(m.applyModifier() == .correct)  // っ
        // ぱ
        #expect(m.ingest("は") == .pending)
        #expect(m.applyModifier() == .pending)  // ば
        #expect(m.applyModifier() == .correct)  // ぱ
        // い
        #expect(m.ingest("い") == .complete)
    }

    @Test func juyo() {
        // じゅう (in 「じゅうにんといろ」)
        var m = KanaMatcher(target: "じゅう")
        #expect(m.ingest("し") == .pending)
        #expect(m.applyModifier() == .correct)  // じ
        // ゅ
        #expect(m.ingest("ゆ") == .pending)
        #expect(m.applyModifier() == .correct)  // ゅ
        // う
        #expect(m.ingest("う") == .complete)
    }

    @Test func wrongInputDoesNotAdvance() {
        var m = KanaMatcher(target: "ねこ")
        #expect(m.ingest("ね") == .correct)
        #expect(m.ingest("か") == .wrong)
        #expect(m.done == "ね")
        #expect(m.expectedNext == "こ")
    }

    @Test func modifierWithNoPendingIsIgnored() {
        var m = KanaMatcher(target: "ねこ")
        #expect(m.applyModifier() == .ignored)
        #expect(m.done == "")
    }

    @Test func abandonedPendingClearsOnNewInput() {
        // target = なる: ingest さ (out-of-cycle wrong) — just .wrong
        // target = が: ingest か (.pending), then ingest さ (different cycle, wrong)
        var m = KanaMatcher(target: "が")
        #expect(m.ingest("か") == .pending)
        #expect(m.pending == "か")
        // Now ingest something completely unrelated — abandons pending
        #expect(m.ingest("さ") == .wrong)
        #expect(m.pending == nil)
        #expect(m.done == "")
    }
}
