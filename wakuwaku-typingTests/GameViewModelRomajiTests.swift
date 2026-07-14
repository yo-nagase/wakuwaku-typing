import Testing
@testable import wakuwaku_typing

@MainActor
struct GameViewModelRomajiTests {
    /// 単語選択を決定的にするため単一エントリのパックを使う
    private func makeVM(entry: String) -> GameViewModel {
        let pack = WordPack(id: "t", jp: "テスト", en: "TEST", sample: "", desc: "", entries: [entry])
        return GameViewModel(pack: pack, duration: 30, difficulty: .normal, inputMode: .romaji)
    }

    @Test func scoresPerKanaOnCommitOnly() {
        let vm = makeVM(entry: "ねこ")
        vm.handleAscii("n")
        #expect(vm.stats.score == 0)          // セグメント途中は加点なし
        #expect(vm.stats.combo == 0)
        vm.handleAscii("e")
        #expect(vm.stats.score == 1)          // combo1 → 1pt
        #expect(vm.stats.combo == 1)
        vm.handleAscii("k")
        vm.handleAscii("o")
        #expect(vm.stats.score == 2)          // combo2 → 1pt
        #expect(vm.stats.words == 1)
        #expect(vm.stats.correctChars == 2)   // かな単位でカウント
        vm.quit()
    }

    @Test func multiKanaCommitAwardsEachKana() {
        let vm = makeVM(entry: "んこ")
        vm.handleAscii("n")
        vm.handleAscii("k")
        vm.handleAscii("o")                   // ん+こ を一括確定
        #expect(vm.stats.combo == 2)
        #expect(vm.stats.score == 2)
        #expect(vm.stats.words == 1)
        #expect(vm.stats.correctChars == 2)
        vm.quit()
    }

    @Test func wrongKeyResetsComboWithoutDeduction() {
        let vm = makeVM(entry: "ねこ")
        vm.handleAscii("n")
        vm.handleAscii("e")
        vm.handleAscii("q")                   // miss
        #expect(vm.stats.combo == 0)
        #expect(vm.stats.wrongChars == 1)
        #expect(vm.stats.score == 1)          // 減点はしない
        vm.quit()
    }

    @Test func courseStringMarksRomajiMode() {
        let vm = makeVM(entry: "ねこ")
        #expect(vm.currentResult().course.hasSuffix(" / R"))
    }

    @Test func flickModeCourseStringUnchanged() {
        let pack = WordPack(id: "t", jp: "テスト", en: "TEST", sample: "", desc: "", entries: ["ねこ"])
        let vm = GameViewModel(pack: pack, duration: 30, difficulty: .normal, inputMode: .flick)
        #expect(vm.currentResult().course == "テスト / 30s")
    }

    @Test func displayAccessorsExposeMatcherState() {
        let vm = makeVM(entry: "ねこ")
        #expect(vm.targetText == "ねこ")
        #expect(vm.doneText == "")
        #expect(vm.romajiRemaining == "neko")
        vm.handleAscii("n")
        #expect(vm.romajiTyped == "n")
        #expect(vm.romajiRemaining == "eko")
        vm.handleAscii("e")
        #expect(vm.doneText == "ね")
        #expect(vm.romajiTyped == "")
        vm.quit()
    }

    @Test func asciiInputStartsTheGame() {
        let vm = makeVM(entry: "ねこ")
        #expect(vm.started == false)
        vm.handleAscii("n")
        #expect(vm.started == true)
        vm.quit()
    }
}
