import Foundation

/// ローマ字入力モードのマッチャー。ASCII 打鍵を 1 文字ずつ受け取り、
/// かな課題語への前方一致で確定していく状態機械。
/// 表示用 API（target / done / isComplete / progress）は KanaMatcher と揃えている。
///
/// `done` 位置から始まる「現在セグメント」の候補綴り集合 `live` を持ち、
/// 1 打鍵ごとに前方一致でフィルタ。候補を打ち切ったらそのかな数を確定して
/// 次セグメントの候補を生成する。ミス打鍵は状態を変えない。
nonisolated struct RomajiMatcher {
    let target: String
    private let targetChars: [Character]

    private(set) var kanaDone: Int = 0
    private(set) var typed: String = ""
    private var live: [Candidate] = []

    struct Candidate: Equatable {
        let spelling: String
        let kanaCount: Int
    }

    enum InputResult: Equatable {
        case progress                      // セグメント途中の正しい 1 打鍵
        case correct(kanaCommitted: Int)   // セグメント確定
        case complete(kanaCommitted: Int)  // 語クリア
        case wrong
    }

    init(target: String) {
        self.target = target
        self.targetChars = Array(target)
        self.live = Self.candidates(in: targetChars, at: 0)
    }

    var done: String { String(targetChars.prefix(kanaDone)) }
    var isComplete: Bool { kanaDone >= targetChars.count }
    var progress: Double {
        targetChars.isEmpty ? 1 : Double(kanaDone) / Double(targetChars.count)
    }

    /// 現在セグメントの残り綴り + 後続セグメントの優先綴り（表示ヒント用）
    var remainingRomaji: String {
        guard !isComplete, let first = live.first else { return "" }
        var out = String(first.spelling.dropFirst(typed.count))
        var i = kanaDone + first.kanaCount
        while i < targetChars.count {
            guard let c = Self.candidates(in: targetChars, at: i).first else { break }
            out += c.spelling
            i += c.kanaCount
        }
        return out
    }

    @discardableResult
    mutating func ingest(_ input: Character) -> InputResult {
        guard !isComplete else { return .complete(kanaCommitted: 0) }
        guard let c = Self.normalize(input) else { return .wrong }
        let idx = typed.count
        let matched = live.filter { candidate in
            let s = Array(candidate.spelling)
            return s.count > idx && s[idx] == c
        }
        if matched.isEmpty { return .wrong }
        typed.append(c)
        if let hit = matched.first(where: { $0.spelling.count == typed.count }) {
            kanaDone += hit.kanaCount
            typed = ""
            if isComplete {
                live = []
                return .complete(kanaCommitted: hit.kanaCount)
            }
            live = Self.candidates(in: targetChars, at: kanaDone)
            return .correct(kanaCommitted: hit.kanaCount)
        }
        live = matched
        return .progress
    }

    private static func normalize(_ ch: Character) -> Character? {
        let lowered = ch.lowercased()
        guard lowered.count == 1, let c = lowered.first,
              c.isASCII, c.isLetter else { return nil }
        return c
    }

    /// index 位置から始まるセグメントの候補綴り（先頭が優先綴り）。
    /// internal: テストが接頭辞不変条件を直接検証する。
    static func candidates(in chars: [Character], at index: Int) -> [Candidate] {
        guard index < chars.count else { return [] }
        switch chars[index] {
        case "ん":
            // 単独 n は「n + 次ユニット綴り」の結合候補として先頭に置く
            // （表示ヒントが最短の "nko" 形になる）。次綴りが母音・n・y 始まりだと
            // な行・にゃ行等と衝突するため除外 → その場合や語末は nn / xn のみ。
            var result: [Candidate] = []
            for next in baseCandidates(in: chars, at: index + 1) {
                guard let head = next.spelling.first, !"aiueony".contains(head) else { continue }
                result.append(Candidate(spelling: "n" + next.spelling, kanaCount: 1 + next.kanaCount))
            }
            result.append(Candidate(spelling: "nn", kanaCount: 1))
            result.append(Candidate(spelling: "xn", kanaCount: 1))
            return result
        case "っ":
            // 重ね子音（次ユニット綴りの先頭文字 1 打で っ を即確定）を優先表示。
            // 母音と n は重ねられない（n は ん と衝突する）ため xtu 系のみ。
            var result: [Candidate] = []
            var seen = Set<Character>()
            for next in baseCandidates(in: chars, at: index + 1) {
                guard let head = next.spelling.first,
                      !"aiueon".contains(head), !seen.contains(head) else { continue }
                seen.insert(head)
                result.append(Candidate(spelling: String(head), kanaCount: 1))
            }
            result.append(Candidate(spelling: "xtu", kanaCount: 1))
            result.append(Candidate(spelling: "ltu", kanaCount: 1))
            result.append(Candidate(spelling: "ltsu", kanaCount: 1))
            return result
        default:
            return baseCandidates(in: chars, at: index)
        }
    }

    /// ん・っ 以外の「基本ユニット」候補（拗音 2 文字 or 単独かな。
    /// 単独かな候補も常に含めるので、き + xya の分割入力が拗音のフォールバックになる）
    private static func baseCandidates(in chars: [Character], at index: Int) -> [Candidate] {
        guard index < chars.count else { return [] }
        var result: [Candidate] = []
        if index + 1 < chars.count,
           let combos = RomajiTable.youon[String(chars[index...index + 1])] {
            result += combos.map { Candidate(spelling: $0, kanaCount: 2) }
        }
        if let singles = RomajiTable.kana[chars[index]] {
            result += singles.map { Candidate(spelling: $0, kanaCount: 1) }
        }
        return result
    }
}
