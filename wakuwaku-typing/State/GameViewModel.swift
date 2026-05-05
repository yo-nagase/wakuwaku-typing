import Foundation
import Observation

@Observable
@MainActor
final class GameViewModel {
    let pack: WordPack
    let duration: Int
    let difficulty: Difficulty

    private(set) var matcher: KanaMatcher
    private(set) var timeRemaining: Int
    private(set) var stats = Stats()
    private(set) var particles: [Particle] = []
    private(set) var shakeCount = 0
    private(set) var lastWrongAt: Date?

    private(set) var started = false
    private(set) var finished = false

    private var timerTask: Task<Void, Never>?

    struct Stats: Equatable {
        var correctChars = 0
        var wrongChars = 0
        var words = 0
        var combo = 0
        var maxCombo = 0
        var score = 0
        var totalChars: Int { correctChars + wrongChars }
        var accuracyPercent: Int {
            totalChars == 0 ? 100 : Int((Double(correctChars) / Double(totalChars)) * 100.0)
        }
    }

    enum ParticleColor { case primary, accent, secondary }

    struct Particle: Identifiable {
        let id = UUID()
        let createdAt: Date
        let lifetime: TimeInterval
        let originX: Double
        let originY: Double
        let velocityX: Double
        let velocityY: Double
        let char: Character
        let color: ParticleColor
    }

    init(pack: WordPack = WordPacks.kotowaza, duration: Int = 30, difficulty: Difficulty = .normal) {
        self.pack = pack
        self.duration = duration
        self.difficulty = difficulty
        self.timeRemaining = duration
        self.matcher = KanaMatcher(target: pack.entries.randomElement() ?? "")
    }

    var liveWPM: Int {
        let elapsed = max(1, duration - timeRemaining)
        return Int((Double(stats.words) / Double(elapsed)) * 60.0)
    }

    var liveScore: Int { stats.score }

    var expectedKey: Character? { matcher.expectedNext }

    func start() {
        guard !started, !finished else { return }
        started = true
        timerTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    guard !self.finished else { return }
                    if self.timeRemaining > 0 {
                        self.timeRemaining -= 1
                    }
                    if self.timeRemaining == 0 {
                        self.finished = true
                    }
                }
                if await self.finished { return }
            }
        }
    }

    func quit() {
        timerTask?.cancel()
        timerTask = nil
    }

    func handle(_ kana: Character) {
        guard !finished else { return }
        if !started { start() }
        process(matcher.ingest(kana))
    }

    func handleModifier() {
        guard !finished else { return }
        if !started { start() }
        process(matcher.applyModifier())
    }

    private func process(_ result: KanaMatcher.InputResult) {
        switch result {
        case .correct:
            stats.correctChars += 1
            stats.combo += 1
            stats.maxCombo = max(stats.maxCombo, stats.combo)
            stats.score += ScoreCalculator.points(forCombo: stats.combo)
            spawnParticles(forCombo: stats.combo, isComplete: false)
            Haptics.tap()
        case .complete:
            stats.correctChars += 1
            stats.combo += 1
            stats.maxCombo = max(stats.maxCombo, stats.combo)
            stats.score += ScoreCalculator.points(forCombo: stats.combo)
            stats.words += 1
            spawnParticles(forCombo: stats.combo, isComplete: true)
            advanceWord()
            Haptics.success()
        case .wrong:
            stats.wrongChars += 1
            stats.combo = 0
            shakeCount += 1
            lastWrongAt = Date()
            Haptics.wrong()
        case .pending, .ignored:
            break
        }
    }

    private func advanceWord() {
        let candidates = pack.entries.filter { $0 != matcher.target }
        let next = (candidates.isEmpty ? pack.entries : candidates).randomElement() ?? ""
        matcher = KanaMatcher(target: next)
    }

    private func spawnParticles(forCombo combo: Int, isComplete: Bool) {
        let count: Int = isComplete
            ? 20 + min(combo, 30)
            : 8 + min(combo, 16)
        let velocityScale = 1.0 + Double(min(combo, 20)) / 40.0
        let baseChars: [Character] = ["Z", "X", "*", "+", "·"]
        let chars: [Character] = combo >= 20
            ? baseChars + ["★", "♥", "◆"]
            : baseChars
        let now = Date()
        for _ in 0..<count {
            particles.append(Particle(
                createdAt: now,
                lifetime: 0.8,
                originX: 0.5 + Double.random(in: -0.15...0.15),
                originY: 0.5 + Double.random(in: -0.05...0.05),
                velocityX: Double.random(in: -2.5...2.5) * velocityScale,
                velocityY: Double.random(in: -3.5 ... -1.5) * velocityScale,
                char: chars.randomElement() ?? "*",
                color: pickParticleColor(forCombo: combo)
            ))
        }
        particles.removeAll { now.timeIntervalSince($0.createdAt) > $0.lifetime + 0.5 }
    }

    private func pickParticleColor(forCombo combo: Int) -> ParticleColor {
        // combo<10: 等確率 / combo≥10: accent 寄り (60%) / combo≥20: accent 重視 (75%)
        let accentBias: Double = combo >= 20 ? 0.75 : (combo >= 10 ? 0.60 : 1.0/3.0)
        if Double.random(in: 0..<1) < accentBias {
            return .accent
        }
        return Bool.random() ? .primary : .secondary
    }

    func currentResult() -> GameResult {
        let elapsed = max(1, duration - timeRemaining)
        return GameResult(
            wpm: Int((Double(stats.words) / Double(elapsed)) * 60.0),
            acc: stats.accuracyPercent,
            combo: stats.maxCombo,
            words: stats.words,
            time: duration,
            course: "\(pack.jp) / \(duration)s",
            score: stats.score
        )
    }
}
