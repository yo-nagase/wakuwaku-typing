import Foundation

enum Rank: String {
    case s = "S"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
}

enum ScoreCalculator {
    /// 正答1文字あたりの獲得点。`combo` はインクリメント後の値（最初の正答で 1）。
    /// 段階表: 0–4 → 1pt / 5–9 → 2pt / 10–19 → 3pt / 20–29 → 4pt / 30+ → 5pt。
    static func points(forCombo combo: Int) -> Int {
        switch combo {
        case ..<5:    return 1
        case 5..<10:  return 2
        case 10..<20: return 3
        case 20..<30: return 4
        default:      return 5
        }
    }

    static func rank(for score: Int) -> Rank {
        switch score {
        case 300...:     return .s
        case 200..<300:  return .a
        case 120..<200:  return .b
        case 60..<120:   return .c
        default:         return .d
        }
    }
}
