import Foundation

struct FlickKey: Equatable {
    let center: Character
    let left: Character?
    let up: Character?
    let right: Character?
    let down: Character?

    init(_ center: Character, left: Character? = nil, up: Character? = nil, right: Character? = nil, down: Character? = nil) {
        self.center = center
        self.left = left
        self.up = up
        self.right = right
        self.down = down
    }

    func kana(for direction: FlickDirection) -> Character? {
        switch direction {
        case .center: return center
        case .left: return left
        case .up: return up
        case .right: return right
        case .down: return down
        }
    }
}

enum FlickDirection {
    case center, left, up, right, down
}

enum SpecialKey: Equatable {
    case modifier            // 「゛゜小」
    case punctuation         // 「、。?!」
    case delete              // ⌫
    case enter               // 改行
    case space               // 空白
}

enum KeyContent: Equatable {
    case kana(FlickKey)
    case special(SpecialKey)
}

enum KanaKeyboardModel {
    /// 4 rows × 3 columns of the central kana grid.
    /// Convention from `flick-keyboard.jsx`: array of [center, left, up, right, down].
    static let rows: [[KeyContent]] = [
        [.kana(FlickKey("あ", left: "い", up: "う", right: "え", down: "お")),
         .kana(FlickKey("か", left: "き", up: "く", right: "け", down: "こ")),
         .kana(FlickKey("さ", left: "し", up: "す", right: "せ", down: "そ"))],

        [.kana(FlickKey("た", left: "ち", up: "つ", right: "て", down: "と")),
         .kana(FlickKey("な", left: "に", up: "ぬ", right: "ね", down: "の")),
         .kana(FlickKey("は", left: "ひ", up: "ふ", right: "へ", down: "ほ"))],

        [.kana(FlickKey("ま", left: "み", up: "む", right: "め", down: "も")),
         .kana(FlickKey("や", up: "ゆ", down: "よ")),
         .kana(FlickKey("ら", left: "り", up: "る", right: "れ", down: "ろ"))],

        [.special(.modifier),
         .kana(FlickKey("わ", left: "を", up: "ん", right: "ー", down: "〜")),
         .special(.punctuation)],
    ]

    /// All directly-typeable kana (without modifier).
    static var typeableKana: Set<Character> {
        var set: Set<Character> = []
        for row in rows {
            for cell in row {
                if case .kana(let k) = cell {
                    set.insert(k.center)
                    if let c = k.left { set.insert(c) }
                    if let c = k.up { set.insert(c) }
                    if let c = k.right { set.insert(c) }
                    if let c = k.down { set.insert(c) }
                }
            }
        }
        return set
    }

    /// All kana reachable from the keyboard (direct + via modifier cycle).
    static var reachableKana: Set<Character> {
        var set = typeableKana
        for kana in typeableKana {
            if let cycle = KanaModifier.cycle(containing: kana) {
                set.formUnion(cycle)
            }
        }
        return set
    }

    /// Returns the FlickKey whose center matches, or which contains this kana on a flick direction.
    static func key(producing kana: Character) -> (key: FlickKey, direction: FlickDirection)? {
        for row in rows {
            for cell in row {
                if case .kana(let k) = cell {
                    if k.center == kana { return (k, .center) }
                    if k.left == kana { return (k, .left) }
                    if k.up == kana { return (k, .up) }
                    if k.right == kana { return (k, .right) }
                    if k.down == kana { return (k, .down) }
                }
            }
        }
        return nil
    }
}
