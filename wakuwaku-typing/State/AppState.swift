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

    var currentScreen: Screen
    var lastResult: GameResult?

    init() {
        if ProcessInfo.processInfo.environment["WT_RESET"] == "1" {
            Persistence.reset()
        }
        let loadedSettings: AppSettings
        let loadedHistory: [HistoryEntry]
        if let storage = Persistence.load() {
            loadedSettings = storage.settings
            loadedHistory = storage.history
        } else {
            loadedSettings = .default
            loadedHistory = []
        }
        self.settings = loadedSettings
        self.history = loadedHistory
        self.bestScore = loadedHistory.map(\.score).max() ?? 0
        self.bestWpm = loadedHistory.map(\.wpm).max() ?? 0
        self.currentScreen = loadedSettings.onboarded ? .home : .onboarding
    }

    func updateSettings(_ patch: (inout AppSettings) -> Void) {
        var copy = settings
        patch(&copy)
        settings = copy
        save()
    }

    func recordResult(_ result: GameResult) {
        let score = ScoreCalculator.score(wpm: result.wpm, accuracyPercent: result.acc, combo: result.combo)
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
        lastResult = result
        save()
    }

    func resetAll() {
        Persistence.reset()
        settings = .default
        history = []
        bestScore = 0
        bestWpm = 0
        lastResult = nil
        currentScreen = .onboarding
    }

    private func save() {
        Persistence.save(.init(settings: settings, history: history))
    }
}
