import Foundation

enum Rank: String {
    case s = "S"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
}

enum ScoreCalculator {
    /// Mirrors the prototype: round(wpm * (acc/100)^2 * (1 + combo/20))
    static func score(wpm: Int, accuracyPercent: Int, combo: Int) -> Int {
        let accF = Double(accuracyPercent) / 100.0
        let raw = Double(wpm) * (accF * accF) * (1.0 + Double(combo) / 20.0)
        return Int((raw).rounded())
    }

    static func rank(for score: Int) -> Rank {
        switch score {
        case 300...: return .s
        case 200..<300: return .a
        case 120..<200: return .b
        case 60..<120: return .c
        default: return .d
        }
    }
}
