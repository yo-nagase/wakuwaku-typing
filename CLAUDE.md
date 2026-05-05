# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Native iOS app: a Japanese-kana typing game ("WakuWakuタイピング"). Pure Swift/SwiftUI, no third-party dependencies, no package manager. Single Xcode project at [wakuwaku-typing.xcodeproj](wakuwaku-typing.xcodeproj).

- Bundle ID: `nag.wakuwaku-typing`
- iOS deployment target: 26.2 — Swift 5.0
- Universal (iPhone + iPad)
- The project uses `PBXFileSystemSynchronizedRootGroup`: **files added to the filesystem under `wakuwaku-typing/`, `wakuwaku-typingTests/`, `wakuwaku-typingUITests/` are auto-included in the build.** No need to edit `project.pbxproj` to register new source files.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set project-wide — all types are MainActor-isolated by default. Mark cross-actor / pure-data types with `nonisolated` (see [WordPack.swift](wakuwaku-typing/Game/WordPack.swift) for the pattern).

## Common commands

```sh
# Build (Debug)
xcodebuild -project wakuwaku-typing.xcodeproj -scheme wakuwaku-typing \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build

# Run all tests (unit + UI)
xcodebuild -project wakuwaku-typing.xcodeproj -scheme wakuwaku-typing \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test

# Run a single unit-test class or method (Swift Testing framework)
xcodebuild ... test -only-testing:wakuwaku-typingTests/KanaMatcherTests
xcodebuild ... test -only-testing:wakuwaku-typingTests/KanaMatcherTests/dakutenViaPendingThenModifier

# Run only UI tests
xcodebuild ... test -only-testing:wakuwaku-typingUITests
```

Unit tests use the **Swift Testing** framework (`import Testing`, `@Test`, `#expect`) — NOT XCTest. UI tests still use XCTest.

Set `WT_RESET=1` in the launch environment to wipe persisted state on launch (used by [OnboardingFlowUITests.swift](wakuwaku-typingUITests/OnboardingFlowUITests.swift) and useful for manual debugging via the scheme's Arguments tab).

## Architecture

### Screen routing
There is **no `NavigationStack`**. [RootView.swift](wakuwaku-typing/App/RootView.swift) is a `switch` over `AppState.currentScreen` (a `Screen` enum). To add a screen: add a case to `Screen` in [AppState.swift](wakuwaku-typing/State/AppState.swift), build the `*View` in [Screens/](wakuwaku-typing/Screens/), and wire it in `RootView.content`. Screens receive callbacks (`onEnd`, `onBack`, etc.) instead of pushing navigation themselves.

### State
- [AppState](wakuwaku-typing/State/AppState.swift) is the top-level `@Observable @MainActor` store: settings, history, current screen, last result, and the `GameCenterManager`. All mutations route through `updateSettings { ... }` / `recordResult(_:)` which persist automatically via [Persistence](wakuwaku-typing/State/Persistence.swift) (UserDefaults key `kanaTyper.v1`). `history` is capped at 50 entries, so for lifetime aggregates use the dedicated persistent counters `cumulativeScore` and `totalGames` (incremented in `recordResult`) — do **not** sum `history` for "TOTAL" displays.
- [GameViewModel](wakuwaku-typing/State/GameViewModel.swift) owns one round: the timer task, stats, particle list, and the `KanaMatcher`. Constructed fresh per game in `GameView.init` — do not try to share or hoist it.
- Use the `Observation` framework (`@Observable`, `@State`), not `ObservableObject` / `@StateObject`.
- Score is a **per-character accumulator**, not an end-of-round derived metric. Each correct kana adds `ScoreCalculator.points(forCombo:)` to `GameViewModel.Stats.score` (combo is incremented first, so the first correct kana scores at combo=1). Tier table in [Score.swift](wakuwaku-typing/Game/Score.swift): combo 0–4 → 1pt, 5–9 → 2pt, 10–19 → 3pt, 20–29 → 4pt, 30+ → 5pt. A wrong input resets `combo` to 0 (no score subtraction). The accumulated total is read live as `viewModel.liveScore` (= `stats.score`) and shipped to `recordResult` via `GameResult.score` — `AppState.recordResult` and `RootView` (new-best check) both consume `result.score` directly; never recompute. `Rank` thresholds also live in `Score.swift` (S 300+ / A 200+ / B 120+ / C 60+ / D under) and assume a ~0–340 range for a perfect 30s round.

### The kana input system (the non-obvious part)
This is the heart of the game and spans three files. Read them together before changing input behavior:

1. [KanaModifier.swift](wakuwaku-typing/Game/KanaModifier.swift) — defines **modifier cycles** for dakuten/handakuten/small kana, e.g. `か→が`, `つ→づ→っ`, `は→ば→ぱ`. The flick keyboard cannot type these directly; the user types the base kana and presses the modifier key to cycle.
2. [KanaMatcher.swift](wakuwaku-typing/Game/KanaMatcher.swift) — **lenient** matcher. If the user types a kana in the same cycle as `expectedNext` (e.g. expects `が`, types `か`), the input becomes `.pending` rather than `.wrong`. `applyModifier()` then advances the pending kana around its cycle. Wrong inputs from a different cycle abandon any pending kana. The state machine is fully test-covered in [KanaMatcherTests.swift](wakuwaku-typingTests/KanaMatcherTests.swift) — preserve those semantics.
3. [GameView.swift `feed(old:new:)`](wakuwaku-typing/Screens/GameView.swift) — bridges iOS's kana TextField to the matcher. iOS produces three change patterns: append (kana typed), same-length replace (modifier cycled the last char in-buffer), and shrink (backspace, ignored). All three are normalized into single-character calls to `viewModel.handle(_:)`.

[KanaKeyboardModel.swift](wakuwaku-typing/Game/KanaKeyboardModel.swift) describes the visual flick keyboard layout but the app does NOT render its own keyboard — it relies on the system kana keyboard. The model exists for content validation (e.g. ensuring word packs only use reachable kana).

### Word packs
[WordPacks](wakuwaku-typing/Game/WordPack.swift) declares all packs as static properties. Only `kotowaza` is currently active; `vocab`, `shorttext`, and `katakana` are `isLocked` placeholders rendered as "Coming soon" tiles in [ModesView](wakuwaku-typing/Screens/ModesView.swift). Use `WordPacks.active` to iterate playable packs and `WordPacks.all` to iterate every tile (including locked). To ship a new pack: add a `WordPack(...)` static, append it to `all`, and supply `entries` of fully-formed kana strings (no romaji, no kanji).

### Theming
Three themes (`.neon`, `.matrix`, `.sunset`) defined as static properties on [Theme](wakuwaku-typing/UI/Theme.swift). `Theme` is passed explicitly down the view tree as a `let theme: Theme` parameter — it is not in the environment. When adding a screen, follow this convention.

### Game Center
[GameCenterManager](wakuwaku-typing/State/GameCenterManager.swift) handles authentication and score submission. Leaderboard IDs are hardcoded constants and must match App Store Connect configuration: `wakuwaku_typing_best_score`, `wakuwaku_typing_best_15s`, `typing_best_30s`, `typing_best_60s` (note: 30s and 60s leaderboards use a shorter prefix), and `cumulative_score` (lifetime total — receives a different value than the per-round IDs). **The per-round leaderboards all receive the same per-round score**; the cumulative leaderboard receives `AppState.cumulativeScore`. Game Center automatically keeps the player's max per leaderboard, so we don't track best score locally for submission. `submitScore(_:duration:)` skips score=0 submissions, includes the matching `_best_NNs` ID only when duration ∈ {15, 30, 60}, and is fire-and-forget. `submitCumulativeScore(_:)` is a separate fire-and-forget call (the running total is a different score value, so it can't share the per-round batch). Both are dispatched from `AppState.recordResult`. Authentication runs once on `RootView.onAppear`. The Game Center capability lives in [wakuwaku-typing/wakuwaku-typing.entitlements](wakuwaku-typing/wakuwaku-typing.entitlements) — add new capabilities there.

⚠️ App Store Connect leaderboard configuration must match: **Score Format Type = Integer, Decimal Places = 0, Sort Order = Highest is Best**. Setting Decimal Places > 0 will display submitted integers scaled (e.g. score=250 with 2 decimals → "2.50"); setting Sort Order to "Lowest is Best" makes Game Center keep the lowest score, not the best.

`AppState.cumulativeScore` powers the home screen `★ TOTAL` tile and the in-app leaderboard's TOTAL tab, **and** is submitted to the `cumulative_score` Game Center leaderboard after each round. `AppState.totalGames` is local-only.

### Custom fonts
`PressStart2P-Regular.ttf` and `DotGothic16-Regular.ttf` live in [wakuwaku-typing/Resources/Fonts/](wakuwaku-typing/Resources/Fonts/) and are registered via `UIAppFonts` in [Config/Info.plist](Config/Info.plist). Always reference them through [AppFont.pixel(_:)](wakuwaku-typing/UI/Fonts.swift) and `AppFont.kana(_:)` — never hardcode the font names elsewhere.

## Design source

Original HTML/CSS/JS prototypes (the design handoff bundle from claude.ai/design) live under [doc/typing-game/](doc/typing-game/). They are reference-only — match visual output, do not port the prototype's structure. See [doc/typing-game/README.md](doc/typing-game/README.md).
