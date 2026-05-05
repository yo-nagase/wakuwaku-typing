import Foundation

enum Rank: String {
    case s = "S"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
}

enum ScoreCalculator {
    /// 正答1文字あたりの獲得点（= 倍率）。`combo` はインクリメント後の値（最初の正答で 1）。
    /// 段階表: 0–2 → 1x / 3–7 → 2x / 8–14 → 3x / 15–24 → 4x / 25–39 → 5x / 40+ → 6x。
    static func points(forCombo combo: Int) -> Int {
        switch combo {
        case ..<3:    return 1
        case 3..<8:   return 2
        case 8..<15:  return 3
        case 15..<25: return 4
        case 25..<40: return 5
        default:      return 6
        }
    }

    /// UI 表示用エイリアス。意味は `points(forCombo:)` と同じ（1 文字あたりの倍率）。
    static func multiplier(forCombo combo: Int) -> Int {
        points(forCombo: combo)
    }

    /// 次の倍率階層に到達する combo 閾値。最高層 (6x) では nil。
    static func nextThreshold(forCombo combo: Int) -> Int? {
        switch combo {
        case ..<3:   return 3
        case ..<8:   return 8
        case ..<15:  return 15
        case ..<25:  return 25
        case ..<40:  return 40
        default:     return nil
        }
    }

    /// 現在の倍率階層が始まる combo（進捗バー計算用）。
    static func currentTierStart(forCombo combo: Int) -> Int {
        switch combo {
        case ..<3:   return 0
        case ..<8:   return 3
        case ..<15:  return 8
        case ..<25:  return 15
        case ..<40:  return 25
        default:     return 40
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
