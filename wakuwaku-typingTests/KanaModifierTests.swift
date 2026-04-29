import Testing
@testable import wakuwaku_typing

struct KanaModifierTests {
    @Test func twoCycleDakuten() {
        #expect(KanaModifier.cycleNext("か") == "が")
        #expect(KanaModifier.cycleNext("が") == "か")
        #expect(KanaModifier.cycleNext("し") == "じ")
        #expect(KanaModifier.cycleNext("じ") == "し")
        #expect(KanaModifier.cycleNext("た") == "だ")
        #expect(KanaModifier.cycleNext("で") == "て")
    }

    @Test func threeCycleHaRow() {
        #expect(KanaModifier.cycleNext("は") == "ば")
        #expect(KanaModifier.cycleNext("ば") == "ぱ")
        #expect(KanaModifier.cycleNext("ぱ") == "は")
        #expect(KanaModifier.cycleNext("ふ") == "ぶ")
        #expect(KanaModifier.cycleNext("ぶ") == "ぷ")
        #expect(KanaModifier.cycleNext("ぷ") == "ふ")
    }

    @Test func tsuHasThreeCycle() {
        // つ → づ → っ → つ
        #expect(KanaModifier.cycleNext("つ") == "づ")
        #expect(KanaModifier.cycleNext("づ") == "っ")
        #expect(KanaModifier.cycleNext("っ") == "つ")
    }

    @Test func smallVariantsForYa() {
        #expect(KanaModifier.cycleNext("や") == "ゃ")
        #expect(KanaModifier.cycleNext("ゃ") == "や")
        #expect(KanaModifier.cycleNext("ゆ") == "ゅ")
        #expect(KanaModifier.cycleNext("よ") == "ょ")
    }

    @Test func vowelSmallCycles() {
        #expect(KanaModifier.cycleNext("あ") == "ぁ")
        #expect(KanaModifier.cycleNext("ぁ") == "あ")
    }

    @Test func unknownCharStaysSame() {
        #expect(KanaModifier.cycleNext("ん") == "ん")
        #expect(KanaModifier.cycleNext("ー") == "ー")
        #expect(KanaModifier.cycleNext("a") == "a")
    }

    @Test func cycleContaining() {
        #expect(KanaModifier.cycle(containing: "は") == ["は", "ば", "ぱ"])
        #expect(KanaModifier.cycle(containing: "ば") == ["は", "ば", "ぱ"])
        #expect(KanaModifier.cycle(containing: "ぱ") == ["は", "ば", "ぱ"])
        #expect(KanaModifier.cycle(containing: "つ") == ["つ", "づ", "っ"])
        #expect(KanaModifier.cycle(containing: "ん") == nil)
    }

    @Test func hiraToKataConversion() {
        #expect(KanaModifier.hiraToKata("こーひー") == "コーヒー")
        #expect(KanaModifier.hiraToKata("にゅーよーく") == "ニューヨーク")
        #expect(KanaModifier.hiraToKata("ABC") == "ABC")
    }
}
