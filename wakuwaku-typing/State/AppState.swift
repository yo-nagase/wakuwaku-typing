import Foundation
import Observation

enum Screen: String, Equatable {
    case onboarding, home, game, results, leaderboard, modes, settings
}

@Observable
@MainActor
final class AppState {
    var settings: AppSettings
    var history: [HistoryEntry]
    private(set) var bestScore: Int
    private(set) var bestWpm: Int
    private(set) var cumulativeScore: Int
    private(set) var totalGames: Int

    var currentScreen: Screen
    var lastResult: GameResult?

    let gameCenter = GameCenterManager()

    init() {
        if ProcessInfo.processInfo.environment["WT_RESET"] == "1" {
            Persistence.reset()
        }
        let loadedSettings: AppSettings
        let loadedHistory: [HistoryEntry]
        let loadedCumulative: Int
        let loadedGames: Int
        if let storage = Persistence.load() {
            loadedSettings = storage.settings
            loadedHistory = storage.history
            // Migration: pre-cumulative builds didn't persist these. Seed from history
            // (best estimate; loses anything beyond the 50-entry cap).
            loadedCumulative = storage.cumulativeScore ?? loadedHistory.reduce(0) { $0 + $1.score }
            loadedGames = storage.totalGames ?? loadedHistory.count
        } else {
            loadedSettings = .default
            loadedHistory = []
            loadedCumulative = 0
            loadedGames = 0
        }
        self.settings = loadedSettings
        self.history = loadedHistory
        self.bestScore = loadedHistory.map(\.score).max() ?? 0
        self.bestWpm = loadedHistory.map(\.wpm).max() ?? 0
        self.cumulativeScore = loadedCumulative
        self.totalGames = loadedGames
        self.currentScreen = loadedSettings.onboarded ? .home : .onboarding
    }

    func updateSettings(_ patch: (inout AppSettings) -> Void) {
        var copy = settings
        patch(&copy)
        settings = copy
        save()
    }

    func recordResult(_ result: GameResult) {
        let score = result.score
        let entry = HistoryEntry(
            date: Date(),
            wpm: result.wpm,
            acc: result.acc,
            combo: result.combo,
            words: result.words,
            time: result.time,
            course: result.course,
            score: score
        )
        history.insert(entry, at: 0)
        if history.count > 50 { history = Array(history.prefix(50)) }
        bestScore = max(bestScore, score)
        bestWpm = max(bestWpm, result.wpm)
        cumulativeScore += score
        totalGames += 1
        lastResult = result
        save()

        // Game Center には単発スコアと累積スコアを送信。GC 側で自動的に最高値が保持される。
        // context にラウンド統計をパックし、リーダーボード表示時に他プレイヤーの WPM 等も復元できるようにする。
        let context = ScoreContext(
            wpm: result.wpm,
            acc: result.acc,
            combo: result.combo,
            words: result.words,
            time: result.time
        ).encoded
        gameCenter.submitScore(score, duration: result.time, context: context)
        gameCenter.submitCumulativeScore(cumulativeScore)
    }

    func resetAll() {
        Persistence.reset()
        settings = .default
        history = []
        bestScore = 0
        bestWpm = 0
        cumulativeScore = 0
        totalGames = 0
        lastResult = nil
        currentScreen = .onboarding
    }

    private func save() {
        Persistence.save(.init(
            settings: settings,
            history: history,
            cumulativeScore: cumulativeScore,
            totalGames: totalGames
        ))
    }
}
