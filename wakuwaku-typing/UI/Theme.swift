import SwiftUI

struct Theme: Equatable {
    let id: ThemeID
    let name: String
    let jp: String
    let bg: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let accent: Color
    let text: Color
    let textDim: Color
    let correct: Color
    let wrong: Color
    let grid: Color

    static let neon = Theme(
        id: .neon,
        name: "NEON",
        jp: "ネオン",
        bg: Color(hex: "0a0014"),
        surface: Color(hex: "1a0930"),
        primary: Color(hex: "ff2a8a"),
        secondary: Color(hex: "9d4edd"),
        accent: Color(hex: "ffd60a"),
        text: Color(hex: "fff5fb"),
        textDim: Color(hex: "a878b8"),
        correct: Color(hex: "39ff14"),
        wrong: Color(hex: "ff003c"),
        grid: Color(hex: "ff2a8a", opacity: 0.08)
    )

    static let matrix = Theme(
        id: .matrix,
        name: "MATRIX",
        jp: "マトリクス",
        bg: Color(hex: "000800"),
        surface: Color(hex: "001a08"),
        primary: Color(hex: "00ff66"),
        secondary: Color(hex: "33cc55"),
        accent: Color(hex: "ccff00"),
        text: Color(hex: "d4ffd4"),
        textDim: Color(hex: "3d7a3d"),
        correct: Color(hex: "ccff00"),
        wrong: Color(hex: "ff3030"),
        grid: Color(hex: "00ff66", opacity: 0.08)
    )

    static let sunset = Theme(
        id: .sunset,
        name: "SUNSET",
        jp: "サンセット",
        bg: Color(hex: "1a0a00"),
        surface: Color(hex: "2d1408"),
        primary: Color(hex: "ff6b1a"),
        secondary: Color(hex: "ff3d6e"),
        accent: Color(hex: "ffe600"),
        text: Color(hex: "fff0e0"),
        textDim: Color(hex: "a06544"),
        correct: Color(hex: "ffe600"),
        wrong: Color(hex: "ff003c"),
        grid: Color(hex: "ff6b1a", opacity: 0.08)
    )

    static func forID(_ id: ThemeID) -> Theme {
        switch id {
        case .neon: return .neon
        case .matrix: return .matrix
        case .sunset: return .sunset
        }
    }
}
