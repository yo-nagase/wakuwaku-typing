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

enum InputMode: String, Codable, CaseIterable {
    case flick
    case romaji
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
    var inputMode: InputMode

    init(name: String, onboarded: Bool, theme: ThemeID, duration: RoundDuration,
         packID: String, difficulty: Difficulty, soundOn: Bool, hapticsOn: Bool,
         inputMode: InputMode = .flick) {
        self.name = name
        self.onboarded = onboarded
        self.theme = theme
        self.duration = duration
        self.packID = packID
        self.difficulty = difficulty
        self.soundOn = soundOn
        self.hapticsOn = hapticsOn
        self.inputMode = inputMode
    }

    // inputMode が無い旧バージョンの保存データでもデコードを失敗させない。
    // （デコード失敗は Persistence.load() の nil 化 = 履歴・累積スコアの全消去につながる）
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        onboarded = try c.decode(Bool.self, forKey: .onboarded)
        theme = try c.decode(ThemeID.self, forKey: .theme)
        duration = try c.decode(RoundDuration.self, forKey: .duration)
        packID = try c.decode(String.self, forKey: .packID)
        difficulty = try c.decode(Difficulty.self, forKey: .difficulty)
        soundOn = try c.decode(Bool.self, forKey: .soundOn)
        hapticsOn = try c.decode(Bool.self, forKey: .hapticsOn)
        inputMode = try c.decodeIfPresent(InputMode.self, forKey: .inputMode) ?? .flick
    }

    static let `default` = AppSettings(
        name: "",
        onboarded: false,
        theme: .neon,
        duration: .thirty,
        packID: "kotowaza",
        difficulty: .normal,
        soundOn: true,
        hapticsOn: true,
        inputMode: .flick
    )
}
