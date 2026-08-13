import GameKit
import Observation

/// Game Center リーダーボードから取得した1エントリ。GameKit 型を View 層に漏らさないための変換済み値。
nonisolated struct RemoteLeaderboardEntry: Equatable, Sendable {
    let rank: Int
    let name: String
    let score: Int
    let date: Date
    let context: Int
    let isLocalPlayer: Bool
}

@Observable
@MainActor
final class GameCenterManager: NSObject {

    // MARK: - Leaderboard IDs (App Store Connect で設定する)
    enum LeaderboardID {
        static let bestScore       = "wakuwaku_typing_best_score"
        static let best15s         = "wakuwaku_typing_best_15s"
        static let best30s         = "typing_best_30s"
        static let best60s         = "typing_best_60s"
        static let cumulativeScore = "cumulative_score"

        static func forDuration(_ seconds: Int) -> String? {
            switch seconds {
            case 15: return best15s
            case 30: return best30s
            case 60: return best60s
            default: return nil
            }
        }
    }

    // MARK: - State
    private(set) var isAuthenticated = false
    private(set) var localPlayerName: String?
    private(set) var authError: Error?

    /// アプリ内リーダーボード表示用のキャッシュ。nil = 未取得（or 取得失敗）。
    private(set) var remoteBest: [RemoteLeaderboardEntry]?
    private(set) var remoteTotal: [RemoteLeaderboardEntry]?
    private(set) var isLoadingLeaderboards = false

    // MARK: - Authentication

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.authError = error
                    self.isAuthenticated = false
                    print("[GameCenter] Auth error: \(error.localizedDescription)")
                    return
                }

                if let vc = viewController {
                    // Game Center のログイン画面を表示
                    self.presentViewController(vc)
                    return
                }

                // 認証成功
                let player = GKLocalPlayer.local
                self.isAuthenticated = player.isAuthenticated
                self.localPlayerName = player.displayName
                self.authError = nil
                print("[GameCenter] Authenticated: \(player.displayName)")
            }
        }
    }

    // MARK: - Submit Score

    /// 単発ラウンドのスコアを `bestScore` および該当する `_best_NNs` リーダーボードに送信する。
    /// Game Center 側で自動的に最高値を保持するので、ローカルで max を比較する必要はない。
    /// `context` には `ScoreContext.encoded`（WPM 等のビットパック）を渡す。0 = 統計なし。
    func submitScore(_ score: Int, duration: Int, context: Int = 0) {
        guard isAuthenticated else {
            print("[GameCenter] Not authenticated – skip submit (score=\(score), duration=\(duration))")
            return
        }
        guard score > 0 else {
            print("[GameCenter] Skip submit – score is 0 (duration=\(duration))")
            return
        }

        var ids: [String] = [LeaderboardID.bestScore]
        if let durationID = LeaderboardID.forDuration(duration) {
            ids.append(durationID)
        }
        print("[GameCenter] Submitting score=\(score) duration=\(duration)s to \(ids)")

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: context,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: ids
                )
                print("[GameCenter] ✓ Submit succeeded: score=\(score) ids=\(ids)")
            } catch {
                print("[GameCenter] ✗ Submit failed: \(error) (score=\(score), ids=\(ids))")
            }
        }
    }

    /// 累積スコアを `cumulative_score` リーダーボードに送信する。
    /// Game Center 側で max を保持するため、ローカル累積値をそのまま送るだけで良い。
    func submitCumulativeScore(_ total: Int) {
        guard isAuthenticated else {
            print("[GameCenter] Not authenticated – skip cumulative submit (total=\(total))")
            return
        }
        guard total > 0 else { return }
        let id = LeaderboardID.cumulativeScore
        print("[GameCenter] Submitting cumulative=\(total) to \(id)")

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    total,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [id]
                )
                print("[GameCenter] ✓ Cumulative submit succeeded: total=\(total)")
            } catch {
                print("[GameCenter] ✗ Cumulative submit failed: \(error) (total=\(total))")
            }
        }
    }

    // MARK: - Load Leaderboard Entries

    /// アプリ内リーダーボード用に BEST / TOTAL の上位エントリを取得してキャッシュする。
    /// 表示側は `remoteBest` / `remoteTotal` を監視するだけでよい。多重呼び出しは無視。
    func refreshLeaderboards() {
        guard isAuthenticated, !isLoadingLeaderboards else { return }
        isLoadingLeaderboards = true

        Task {
            async let best = loadEntries(leaderboardID: LeaderboardID.bestScore)
            async let total = loadEntries(leaderboardID: LeaderboardID.cumulativeScore)
            let (bestResult, totalResult) = await (best, total)
            // 失敗時 (nil) は古いキャッシュを保持して表示を巻き戻さない
            if let bestResult { remoteBest = bestResult }
            if let totalResult { remoteTotal = totalResult }
            isLoadingLeaderboards = false
        }
    }

    /// 上位25件 + 圏外の場合は自分のエントリを取得する。失敗時は nil。
    private func loadEntries(leaderboardID: String) async -> [RemoteLeaderboardEntry]? {
        do {
            guard let board = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]).first else {
                print("[GameCenter] ✗ Leaderboard not found: \(leaderboardID)")
                return nil
            }
            let (localEntry, entries, _) = try await board.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 25)
            )
            var result = entries.map(Self.convert)
            if let localEntry, localEntry.rank > 0, !result.contains(where: \.isLocalPlayer) {
                result.append(Self.convert(localEntry))
            }
            print("[GameCenter] ✓ Loaded \(result.count) entries from \(leaderboardID)")
            return result.sorted { $0.rank < $1.rank }
        } catch {
            print("[GameCenter] ✗ Load entries failed for \(leaderboardID): \(error)")
            return nil
        }
    }

    private static func convert(_ entry: GKLeaderboard.Entry) -> RemoteLeaderboardEntry {
        RemoteLeaderboardEntry(
            rank: entry.rank,
            name: entry.player.displayName,
            score: entry.score,
            date: entry.date,
            context: entry.context,
            isLocalPlayer: entry.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID
        )
    }

    // MARK: - Show Game Center UI

    func showLeaderboard(leaderboardID: String = LeaderboardID.bestScore) {
        guard isAuthenticated else { return }

        let gcVC = GKGameCenterViewController(leaderboardID: leaderboardID,
                                              playerScope: .global,
                                              timeScope: .allTime)
        gcVC.gameCenterDelegate = self
        presentViewController(gcVC)
    }

    func showAchievements() {
        guard isAuthenticated else { return }

        let gcVC = GKGameCenterViewController(state: .achievements)
        gcVC.gameCenterDelegate = self
        presentViewController(gcVC)
    }

    // MARK: - Helpers

    private func presentViewController(_ vc: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else {
            return
        }
        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        presenter.present(vc, animated: true)
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterManager: GKGameCenterControllerDelegate {
    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
