import Testing
@testable import wakuwaku_typing

struct RomajiMatcherTests {
    @discardableResult
    private func type(_ s: String, into m: inout RomajiMatcher) -> [RomajiMatcher.InputResult] {
        s.map { m.ingest($0) }
    }

    // MARK: - 基本

    @Test func basicWord() {
        var m = RomajiMatcher(target: "ねこ")
        #expect(m.ingest("n") == .progress)
        #expect(m.done == "")
        #expect(m.ingest("e") == .correct(kanaCommitted: 1))
        #expect(m.done == "ね")
        #expect(m.ingest("k") == .progress)
        #expect(m.ingest("o") == .complete(kanaCommitted: 1))
        #expect(m.isComplete)
        #expect(m.done == "ねこ")
    }

    @Test func uppercaseIsAccepted() {
        var m = RomajiMatcher(target: "ねこ")
        let results = type("NEKO", into: &m)
        #expect(m.isComplete)
        #expect(!results.contains(.wrong))
    }

    @Test func nonLettersAreWrong() {
        var m = RomajiMatcher(target: "ねこ")
        #expect(m.ingest("1") == .wrong)
        #expect(m.ingest(" ") == .wrong)
        #expect(m.done == "")
    }

    @Test func progressFraction() {
        var m = RomajiMatcher(target: "ねこ")
        #expect(m.progress == 0)
        type("ne", into: &m)
        #expect(m.progress == 0.5)
        type("ko", into: &m)
        #expect(m.progress == 1)
    }

    // MARK: - 綴りバリエーション

    @Test(arguments: [
        ("し", "shi"), ("し", "si"),
        ("ち", "chi"), ("ち", "ti"),
        ("つ", "tsu"), ("つ", "tu"),
        ("ふ", "fu"), ("ふ", "hu"),
        ("じ", "ji"), ("じ", "zi"),
        ("ぢ", "di"), ("づ", "du"),
        ("を", "wo"), ("が", "ga"), ("ぱ", "pa"),
    ])
    func spellingVariants(target: String, romaji: String) {
        var m = RomajiMatcher(target: target)
        let results = type(romaji, into: &m)
        #expect(results.last == .complete(kanaCommitted: 1), "\(target) via \(romaji)")
        #expect(!results.contains(.wrong), "\(target) via \(romaji)")
    }

    // MARK: - 拗音

    @Test func youonAsSingleUnit() {
        var m = RomajiMatcher(target: "きゃく")
        #expect(m.ingest("k") == .progress)
        #expect(m.ingest("y") == .progress)
        #expect(m.ingest("a") == .correct(kanaCommitted: 2))
        #expect(m.done == "きゃ")
        type("ku", into: &m)
        #expect(m.isComplete)
    }

    @Test(arguments: [
        ("しゃ", "sha"), ("しゃ", "sya"),
        ("ちょ", "cho"), ("ちょ", "tyo"),
        ("じゃ", "ja"), ("じゃ", "jya"), ("じゃ", "zya"),
        ("ぎょ", "gyo"), ("りゅ", "ryu"),
    ])
    func youonSpellings(target: String, romaji: String) {
        var m = RomajiMatcher(target: target)
        let results = type(romaji, into: &m)
        #expect(results.last == .complete(kanaCommitted: 2), "\(target) via \(romaji)")
        #expect(!results.contains(.wrong), "\(target) via \(romaji)")
    }

    @Test func youonSplitInput() {
        var m = RomajiMatcher(target: "きゃ")
        #expect(type("ki", into: &m).last == .correct(kanaCommitted: 1))
        #expect(m.done == "き")
        #expect(type("xya", into: &m).last == .complete(kanaCommitted: 1))

        var m2 = RomajiMatcher(target: "きゃ")
        let results = type("kilya", into: &m2)
        #expect(m2.isComplete)
        #expect(!results.contains(.wrong))
    }

    // MARK: - 促音 っ

    @Test func sokuonByConsonantDoubling() {
        // っ は重ね子音の 1 打鍵目で即確定し、次のかなは通常どおり打つ
        var m = RomajiMatcher(target: "っこ")
        #expect(m.ingest("k") == .correct(kanaCommitted: 1))
        #expect(m.done == "っ")
        #expect(m.ingest("k") == .progress)
        #expect(m.ingest("o") == .complete(kanaCommitted: 1))
    }

    @Test(arguments: [
        ("っこ", "kko"), ("っこ", "xtuko"), ("っこ", "ltuko"), ("っこ", "ltsuko"),
        ("っち", "cchi"), ("っち", "tti"),
        ("っしゃ", "ssha"), ("っしゃ", "ssya"),
        ("っぱ", "ppa"),
    ])
    func sokuonSpellings(target: String, romaji: String) {
        var m = RomajiMatcher(target: target)
        let results = type(romaji, into: &m)
        #expect(m.isComplete, "\(target) via \(romaji)")
        #expect(!results.contains(.wrong), "\(target) via \(romaji)")
    }

    // MARK: - ん

    @Test func nnSingleBeforeConsonantCommitsTogether() {
        // 単独 n は次ユニットと結合した候補として扱い、次ユニット確定時にまとめて確定
        var m = RomajiMatcher(target: "んこ")
        #expect(m.ingest("n") == .progress)
        #expect(m.ingest("k") == .progress)
        #expect(m.ingest("o") == .complete(kanaCommitted: 2))
    }

    @Test func nnDoubleAlwaysWorks() {
        var m = RomajiMatcher(target: "んこ")
        #expect(m.ingest("n") == .progress)
        #expect(m.ingest("n") == .correct(kanaCommitted: 1))
        #expect(m.done == "ん")
        let results = type("ko", into: &m)
        #expect(results.last == .complete(kanaCommitted: 1))
    }

    @Test func wordFinalNRequiresDoubleN() {
        var m = RomajiMatcher(target: "ほん")
        type("ho", into: &m)
        #expect(m.ingest("n") == .progress)
        #expect(!m.isComplete)                 // "hon" では未完
        #expect(m.ingest("n") == .complete(kanaCommitted: 1))
    }

    @Test func nBeforeVowelRequiresDoubleN() {
        // んあ: "na" は な になってしまうので 'a' はミス。"nn"+"a" で完走
        var m = RomajiMatcher(target: "んあ")
        #expect(m.ingest("n") == .progress)
        #expect(m.ingest("a") == .wrong)
        #expect(m.ingest("n") == .correct(kanaCommitted: 1))
        #expect(m.ingest("a") == .complete(kanaCommitted: 1))
    }

    @Test func nBeforeYRequiresDoubleN() {
        // こんやく: や の前は nn 必須（"nya" は にゃ の綴りになるため 'y' はミス）
        var m = RomajiMatcher(target: "こんやく")
        type("ko", into: &m)
        #expect(m.ingest("n") == .progress)
        #expect(m.ingest("y") == .wrong)
        #expect(m.ingest("n") == .correct(kanaCommitted: 1))
        let results = type("yaku", into: &m)
        #expect(m.isComplete)
        #expect(!results.contains(.wrong))
    }

    @Test func nBeforeNaRowRequiresDoubleN() {
        // こんにちは: に の前も nn 必須 → "konnnichiha"
        var m = RomajiMatcher(target: "こんにちは")
        let results = type("konnnichiha", into: &m)
        #expect(m.isComplete)
        #expect(!results.contains(.wrong))
    }

    // MARK: - ミスは状態を壊さない

    @Test func wrongKeyKeepsTypedPrefix() {
        var m = RomajiMatcher(target: "しか")
        #expect(m.ingest("s") == .progress)
        #expect(m.ingest("k") == .wrong)   // "sk" はどの綴りにも合致しない
        #expect(m.ingest("h") == .progress)
        #expect(m.ingest("i") == .correct(kanaCommitted: 1))
        #expect(m.done == "し")
    }

    // MARK: - 表示ヒント

    @Test func remainingRomajiShowsPreferredSpellings() {
        #expect(RomajiMatcher(target: "ねこ").remainingRomaji == "neko")
        #expect(RomajiMatcher(target: "っこ").remainingRomaji == "kko")
        #expect(RomajiMatcher(target: "んこ").remainingRomaji == "nko")
        #expect(RomajiMatcher(target: "こんにちは").remainingRomaji == "konnnichiha")
        #expect(RomajiMatcher(target: "きゃく").remainingRomaji == "kyaku")
    }

    @Test func remainingRomajiFollowsTypedPath() {
        // し を "s" まで打ったら残りは優先綴り "shi" の続き
        var m = RomajiMatcher(target: "し")
        m.ingest("s")
        #expect(m.remainingRomaji == "hi")
        // 訓令式 "si" に分岐したら追従して "i" だけになる… は分岐後の 1 打で確定するため
        // typed 追従は sh 系で確認する
        var m2 = RomajiMatcher(target: "しゃ")
        m2.ingest("s")
        m2.ingest("y")
        #expect(m2.remainingRomaji == "a")
    }

    // MARK: - 候補集合の不変条件

    /// 同一候補集合内で、ある綴りが別の綴りの真の接頭辞だと早期確定が長い綴りを潰す。
    /// 全アクティブパックの全確定位置でそれが起きないことを検証する。
    @Test func noCandidateIsStrictPrefixOfAnother() {
        for pack in WordPacks.active {
            for entry in pack.entries {
                let chars = Array(entry)
                var i = 0
                while i < chars.count {
                    let cands = RomajiMatcher.candidates(in: chars, at: i)
                    #expect(!cands.isEmpty, "no candidates for \(entry) at \(i)")
                    for a in cands {
                        for b in cands where a.spelling != b.spelling {
                            #expect(!b.spelling.hasPrefix(a.spelling),
                                    "\(entry)@\(i): '\(a.spelling)' is prefix of '\(b.spelling)'")
                        }
                    }
                    i += cands.first.map(\.kanaCount) ?? 1
                }
            }
        }
    }
}
