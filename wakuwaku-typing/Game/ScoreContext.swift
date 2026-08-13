import Foundation

/// Game Center の context (64bit Int) にラウンド統計をビットパックする。
/// 他プレイヤーのエントリからも WPM・正確率などを復元できるようにするための型。
///
/// ビットレイアウト（LSB から）:
/// version(4) | wpm(10) | acc(7) | combo(10) | words(10) | time(10) = 51 bits
/// context=0（過去の送信分・未対応クライアント）は「統計情報なし」として decode で nil を返す。
nonisolated struct ScoreContext: Equatable {
    let wpm: Int
    let acc: Int
    let combo: Int
    let words: Int
    let time: Int

    private static let version = 1

    private enum Field {
        static let wpm    = (shift: 4,  bits: 10)
        static let acc    = (shift: 14, bits: 7)
        static let combo  = (shift: 21, bits: 10)
        static let words  = (shift: 31, bits: 10)
        static let time   = (shift: 41, bits: 10)
    }

    init(wpm: Int, acc: Int, combo: Int, words: Int, time: Int) {
        self.wpm = Self.clamp(wpm, bits: Field.wpm.bits)
        self.acc = min(Self.clamp(acc, bits: Field.acc.bits), 100)
        self.combo = Self.clamp(combo, bits: Field.combo.bits)
        self.words = Self.clamp(words, bits: Field.words.bits)
        self.time = Self.clamp(time, bits: Field.time.bits)
    }

    init?(decoding raw: Int) {
        guard raw & 0xF == Self.version else { return nil }
        self.init(
            wpm: Self.extract(raw, Field.wpm),
            acc: Self.extract(raw, Field.acc),
            combo: Self.extract(raw, Field.combo),
            words: Self.extract(raw, Field.words),
            time: Self.extract(raw, Field.time)
        )
    }

    var encoded: Int {
        Self.version
            | wpm << Field.wpm.shift
            | acc << Field.acc.shift
            | combo << Field.combo.shift
            | words << Field.words.shift
            | time << Field.time.shift
    }

    private static func clamp(_ value: Int, bits: Int) -> Int {
        min(max(value, 0), (1 << bits) - 1)
    }

    private static func extract(_ raw: Int, _ field: (shift: Int, bits: Int)) -> Int {
        (raw >> field.shift) & ((1 << field.bits) - 1)
    }
}
