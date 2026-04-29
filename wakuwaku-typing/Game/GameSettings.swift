import Foundation

enum ThemeID: String, Codable, CaseIterable {
    case neon
    case matrix
    case sunset
}

enum Difficulty: String, Codable, CaseIterable {
    case easy
    case normal
    case hard
}

enum RoundDuration: Int, Codable, CaseIterable {
    case fifteen = 15
    case thirty = 30
    case sixty = 60
}

struct AppSettings: Codable, Equatable {
    var name: String
    var onboarded: Bool
    var theme: ThemeID
    var duration: RoundDuration
    var packID: String
    var difficulty: Difficulty
    var soundOn: Bool
    var hapticsOn: Bool

    static let `default` = AppSettings(
        name: "",
        onboarded: false,
        theme: .neon,
        duration: .thirty,
        packID: "kotowaza",
        difficulty: .normal,
        soundOn: true,
        hapticsOn: true
    )
}
