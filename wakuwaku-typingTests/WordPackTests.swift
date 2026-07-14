import Testing
@testable import wakuwaku_typing

struct WordPackTests {
    @Test func kotowazaPackExists() {
        let pack = WordPacks.kotowaza
        #expect(pack.id == "kotowaza")
        #expect(!pack.isLocked)
        #expect(pack.entries.count >= 20)
    }

    @Test func allEntriesAreHiraganaOnly() {
        for entry in WordPacks.kotowaza.entries {
            for ch in entry {
                let isHiragana = ch.unicodeScalars.allSatisfy { $0.value >= 0x3041 && $0.value <= 0x3096 }
                let isLongMark = ch == "ー"
                #expect(isHiragana || isLongMark, "Entry '\(entry)' contains non-hiragana char '\(ch)'")
            }
        }
    }

    @Test func everyKanaIsReachableFromKeyboard() {
        let reachable = KanaKeyboardModel.reachableKana
        for entry in WordPacks.kotowaza.entries {
            for ch in entry {
                let isLongMark = ch == "ー"
                #expect(reachable.contains(ch) || isLongMark, "Char '\(ch)' in '\(entry)' is not reachable from the flick keyboard")
            }
        }
    }

    @Test func allActivePackEntriesAreRomajiTypable() {
        // 表示ヒントに従って打てば全エントリが完走できる = 全かなが RomajiMatcher で入力可能
        for pack in WordPacks.active {
            for entry in pack.entries {
                var m = RomajiMatcher(target: entry)
                var steps = 0
                while !m.isComplete, steps < 300 {
                    guard let ch = m.remainingRomaji.first else { break }
                    #expect(m.ingest(ch) != .wrong, "entry: \(entry)")
                    steps += 1
                }
                #expect(m.isComplete, "entry '\(entry)' is not typable in romaji mode")
            }
        }
    }

    @Test func activeListExcludesLocked() {
        #expect(WordPacks.active.count == 1)
        #expect(WordPacks.active.first?.id == "kotowaza")
    }

    @Test func packLookup() {
        #expect(WordPacks.pack(id: "kotowaza").id == "kotowaza")
        // Unknown ID falls back to kotowaza
        #expect(WordPacks.pack(id: "nope").id == "kotowaza")
    }
}
