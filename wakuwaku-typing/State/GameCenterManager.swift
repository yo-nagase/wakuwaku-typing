import GameKit
import Observation

@Observable
@MainActor
final class GameCenterManager: NSObject {

    // MARK: - Leaderboard IDs (App Store Connect で設定する)
    enum LeaderboardID {
        static let bestScore = "wakuwaku_typing_best_score"
        static let best15s   = "wakuwaku_typing_best_15s"
        static let best30s   = "wakuwaku_typing_best_30s"
        static let best60s   = "wakuwaku_typing_best_60s"

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

    func submitScore(_ score: Int, duration: Int) {
        guard isAuthenticated else {
            print("[GameCenter] Not authenticated – skip submit")
            return
        }

        // ベストスコア(総合)
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [LeaderboardID.bestScore]
                )
                print("[GameCenter] Score \(score) submitted to bestScore")
            } catch {
                print("[GameCenter] Submit bestScore error: \(error.localizedDescription)")
            }
        }

        // 秒数別リーダーボード
        if let durationID = LeaderboardID.forDuration(duration) {
            Task {
                do {
                    try await GKLeaderboard.submitScore(
                        score,
                        context: 0,
                        player: GKLocalPlayer.local,
                        leaderboardIDs: [durationID]
                    )
                    print("[GameCenter] Score \(score) submitted to \(durationID)")
                } catch {
                    print("[GameCenter] Submit \(durationID) error: \(error.localizedDescription)")
                }
            }
        }
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
