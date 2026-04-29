import Foundation

enum KanaModifier {
    static let cycles: [[Character]] = [
        ["あ", "ぁ"], ["い", "ぃ"], ["う", "ぅ"], ["え", "ぇ"], ["お", "ぉ"],
        ["か", "が"], ["き", "ぎ"], ["く", "ぐ"], ["け", "げ"], ["こ", "ご"],
        ["さ", "ざ"], ["し", "じ"], ["す", "ず"], ["せ", "ぜ"], ["そ", "ぞ"],
        ["た", "だ"], ["ち", "ぢ"], ["つ", "づ", "っ"],
        ["て", "で"], ["と", "ど"],
        ["は", "ば", "ぱ"], ["ひ", "び", "ぴ"], ["ふ", "ぶ", "ぷ"],
        ["へ", "べ", "ぺ"], ["ほ", "ぼ", "ぽ"],
        ["や", "ゃ"], ["ゆ", "ゅ"], ["よ", "ょ"],
        ["わ", "ゎ"],
    ]

    private static let positionByChar: [Character: (cycleIndex: Int, position: Int)] = {
        var index: [Character: (Int, Int)] = [:]
        for (ci, cycle) in cycles.enumerated() {
            for (pi, c) in cycle.enumerated() {
                index[c] = (ci, pi)
            }
        }
        return index
    }()

    static func cycle(containing kana: Character) -> [Character]? {
        positionByChar[kana].map { cycles[$0.cycleIndex] }
    }

    static func cycleNext(_ kana: Character) -> Character {
        guard let (ci, pi) = positionByChar[kana] else { return kana }
        let cycle = cycles[ci]
        return cycle[(pi + 1) % cycle.count]
    }

    static func hiraToKata(_ hira: String) -> String {
        String(hira.unicodeScalars.map { scalar -> Character in
            let v = scalar.value
            if v >= 0x3041 && v <= 0x3096, let s = Unicode.Scalar(v + 0x60) {
                return Character(s)
            }
            return Character(scalar)
        })
    }
}
