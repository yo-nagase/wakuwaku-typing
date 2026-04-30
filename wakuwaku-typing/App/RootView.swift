import SwiftUI

struct RootView: View {
    @State private var appState = AppState()
    @State private var lastResultWasNewBest = false

    var theme: Theme { Theme.forID(appState.settings.theme) }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Haptics.enabled = appState.settings.hapticsOn
            Haptics.prepare()
            appState.gameCenter.authenticate()
        }
        .onChange(of: appState.settings.hapticsOn) { _, on in
            Haptics.enabled = on
        }
    }

    @ViewBuilder
    private var content: some View {
        switch appState.currentScreen {
        case .onboarding:
            OnboardingView(theme: theme) { name in
                appState.updateSettings {
                    $0.name = name
                    $0.onboarded = true
                }
                appState.currentScreen = .home
            }
        case .home:
            HomeView(
                theme: theme,
                appState: appState,
                onStart: { appState.currentScreen = .game },
                onScreen: { appState.currentScreen = $0 }
            )
        case .game:
            GameView(
                theme: theme,
                settings: appState.settings,
                onEnd: { result in
                    let newScore = ScoreCalculator.score(wpm: result.wpm, accuracyPercent: result.acc, combo: result.combo)
                    let prevBest = appState.history.map(\.score).max() ?? 0
                    lastResultWasNewBest = newScore > prevBest
                    appState.recordResult(result)
                    appState.currentScreen = .results
                },
                onExit: { appState.currentScreen = .home }
            )
        case .results:
            ResultsView(
                theme: theme,
                result: appState.lastResult ?? GameResult(wpm: 0, acc: 0, combo: 0, words: 0, time: 30, course: "—"),
                isNewBest: lastResultWasNewBest,
                onRestart: { appState.currentScreen = .game },
                onHome: { appState.currentScreen = .home }
            )
        case .leaderboard:
            LeaderboardView(theme: theme, appState: appState) {
                appState.currentScreen = .home
            }
        case .modes:
            ModesView(theme: theme, appState: appState) {
                appState.currentScreen = .home
            }
        case .settings:
            SettingsView(theme: theme, appState: appState) {
                appState.currentScreen = .home
            }
        }
    }
}

#Preview {
    RootView()
}
