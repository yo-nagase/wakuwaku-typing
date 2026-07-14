# ローマ字入力モード 実装計画

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** フリック専用のかなタイピングゲームに、英字キーボードで打つローマ字入力モードを追加する。

**Architecture:** 新設の `RomajiMatcher`（純ロジック状態機械）が ASCII 打鍵をかな確定に変換する。既存の `KanaMatcher`（フリック用）には一切手を入れず、`GameViewModel` がモードに応じてどちらかを保持する。設定は `AppSettings.inputMode`（後方互換デコード必須）。スコアは「かな確定ごとに加点」でフリックと同一定義、リーダーボードは既存を共用（確定済み）。

**Tech Stack:** Swift 5 / SwiftUI / Observation / Swift Testing（unit）。`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` のため純データ型は `nonisolated`。ファイル追加は filesystem-synchronized group なので pbxproj 編集不要。

**設計書:** [2026-07-14-romaji-input-mode-design.md](2026-07-14-romaji-input-mode-design.md)

**ビルド/テストコマンド:**

```sh
# 全テスト
xcodebuild -project wakuwaku-typing.xcodeproj -scheme wakuwaku-typing \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test
# 単一スイート
xcodebuild ... test -only-testing:wakuwaku-typingTests/RomajiMatcherTests
```

---

## Task 0: フィーチャーブランチ作成

```bash
git switch -c feature/romaji-input
```

⚠️ 作業ツリーに既存の `wakuwaku-typing.xcodeproj/project.pbxproj` の変更があるが、本件と無関係なのでコミットに含めない（`git add` はファイル個別指定で行う）。

## Task 1: InputMode + AppSettings 後方互換デコード

**Files:**

- Modify: `wakuwaku-typing/Game/GameSettings.swift`
- Test: `wakuwaku-typingTests/AppSettingsCodableTests.swift`（新規）

**Step 1: 失敗するテストを書く**

```swift
import Testing
import Foundation
@testable import wakuwaku_typing

struct AppSettingsCodableTests {
    private let legacySettingsJSON = """
    {"name":"ABC","onboarded":true,"theme":"neon","duration":30,"packID":"kotowaza","difficulty":"normal","soundOn":true,"hapticsOn":false}
    """

    @Test func legacyJSONWithoutInputModeDefaultsToFlick() throws {
        let s = try JSONDecoder().decode(AppSettings.self, from: Data(legacySettingsJSON.utf8))
        #expect(s.inputMode == .flick)
        #expect(s.name == "ABC")
        #expect(s.hapticsOn == false)
    }

    @Test func legacyStorageDecodesWithoutDataLoss() throws {
        let json = """
        {"settings":\(legacySettingsJSON),"history":[{"date":700000000,"wpm":10,"acc":95,"combo":8,"words":5,"time":30,"course":"ことわざ / 30s","score":42}]}
        """
        let storage = try JSONDecoder().decode(Persistence.Storage.self, from: Data(json.utf8))
        #expect(storage.settings.inputMode == .flick)
        #expect(storage.history.count == 1)
    }

    @Test func roundTripsRomajiMode() throws {
        var s = AppSettings.default
        s.inputMode = .romaji
        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(s))
        #expect(decoded.inputMode == .romaji)
    }
}
```

※ `HistoryEntry` のフィールド名・date エンコード形式は `GameHistory.swift` を見て fixture を合わせること。

**Step 2: 失敗確認**（`inputMode` 未定義でコンパイルエラー = 失敗扱い）

**Step 3: 実装** — `GameSettings.swift` に追加:

```swift
enum InputMode: String, Codable, CaseIterable {
    case flick
    case romaji
}
```

`AppSettings` に `var inputMode: InputMode` を追加。**カスタム `init(from:)` を書くと memberwise init が消えるので、明示的に両方書く**:

```swift
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

    // 旧バージョンの保存データに inputMode が無くてもデコードを失敗させない
    // （失敗すると Persistence.load() が nil → 履歴・累積スコアごと初期化されるため）
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
}
```

`static let default` に `inputMode: .flick` を追加。isolation エラーが出た場合は WordPack.swift の例に倣い `nonisolated` を付ける。

**Step 4: テスト実行 → PASS 確認**

```sh
xcodebuild ... test -only-testing:wakuwaku-typingTests/AppSettingsCodableTests
```

**Step 5: Commit** `feat: add InputMode setting with backward-compatible decoding`

## Task 2: RomajiTable（綴りテーブル）

**Files:**

- Create: `wakuwaku-typing/Game/RomajiTable.swift`

かな→綴りの静的テーブル。**配列の先頭が表示ヒント用の優先綴り**。ん・っ はコンテキスト依存なので Matcher 側で扱い、テーブルには含めない。

```swift
import Foundation

/// ローマ字入力モードの綴りテーブル。
/// 各配列の先頭が表示ヒントに使う優先綴り。ん・っ は文脈依存のため
/// RomajiMatcher.candidates(in:at:) が動的に生成する。
nonisolated enum RomajiTable {
    static let kana: [Character: [String]] = [
        "あ": ["a"], "い": ["i"], "う": ["u"], "え": ["e"], "お": ["o"],
        "か": ["ka"], "き": ["ki"], "く": ["ku"], "け": ["ke"], "こ": ["ko"],
        "さ": ["sa"], "し": ["shi", "si"], "す": ["su"], "せ": ["se"], "そ": ["so"],
        "た": ["ta"], "ち": ["chi", "ti"], "つ": ["tsu", "tu"], "て": ["te"], "と": ["to"],
        "な": ["na"], "に": ["ni"], "ぬ": ["nu"], "ね": ["ne"], "の": ["no"],
        "は": ["ha"], "ひ": ["hi"], "ふ": ["fu", "hu"], "へ": ["he"], "ほ": ["ho"],
        "ま": ["ma"], "み": ["mi"], "む": ["mu"], "め": ["me"], "も": ["mo"],
        "や": ["ya"], "ゆ": ["yu"], "よ": ["yo"],
        "ら": ["ra"], "り": ["ri"], "る": ["ru"], "れ": ["re"], "ろ": ["ro"],
        "わ": ["wa"], "を": ["wo"],
        "が": ["ga"], "ぎ": ["gi"], "ぐ": ["gu"], "げ": ["ge"], "ご": ["go"],
        "ざ": ["za"], "じ": ["ji", "zi"], "ず": ["zu"], "ぜ": ["ze"], "ぞ": ["zo"],
        "だ": ["da"], "ぢ": ["di"], "づ": ["du"], "で": ["de"], "ど": ["do"],
        "ば": ["ba"], "び": ["bi"], "ぶ": ["bu"], "べ": ["be"], "ぼ": ["bo"],
        "ぱ": ["pa"], "ぴ": ["pi"], "ぷ": ["pu"], "ぺ": ["pe"], "ぽ": ["po"],
        "ぁ": ["xa", "la"], "ぃ": ["xi", "li"], "ぅ": ["xu", "lu"],
        "ぇ": ["xe", "le"], "ぉ": ["xo", "lo"],
        "ゃ": ["xya", "lya"], "ゅ": ["xyu", "lyu"], "ょ": ["xyo", "lyo"],
        "ゎ": ["xwa", "lwa"],
    ]

    static let youon: [String: [String]] = [
        "きゃ": ["kya"], "きゅ": ["kyu"], "きょ": ["kyo"],
        "しゃ": ["sha", "sya"], "しゅ": ["shu", "syu"], "しょ": ["sho", "syo"],
        "ちゃ": ["cha", "tya"], "ちゅ": ["chu", "tyu"], "ちょ": ["cho", "tyo"],
        "にゃ": ["nya"], "にゅ": ["nyu"], "にょ": ["nyo"],
        "ひゃ": ["hya"], "ひゅ": ["hyu"], "ひょ": ["hyo"],
        "みゃ": ["mya"], "みゅ": ["myu"], "みょ": ["myo"],
        "りゃ": ["rya"], "りゅ": ["ryu"], "りょ": ["ryo"],
        "ぎゃ": ["gya"], "ぎゅ": ["gyu"], "ぎょ": ["gyo"],
        "じゃ": ["ja", "jya", "zya"], "じゅ": ["ju", "jyu", "zyu"], "じょ": ["jo", "jyo", "zyo"],
        "びゃ": ["bya"], "びゅ": ["byu"], "びょ": ["byo"],
        "ぴゃ": ["pya"], "ぴゅ": ["pyu"], "ぴょ": ["pyo"],
        "ぢゃ": ["dya"], "ぢゅ": ["dyu"], "ぢょ": ["dyo"],
    ]
}
```

コミットは Task 3 とまとめる（テーブル単体ではテスト不能なため）。

## Task 3: RomajiMatcher 状態機械（本丸）

**Files:**

- Create: `wakuwaku-typing/Game/RomajiMatcher.swift`
- Test: `wakuwaku-typingTests/RomajiMatcherTests.swift`（新規）

### 動作原理

`done` 位置から始まる「現在セグメント」の候補綴り集合 `live` を持ち、1 打鍵ごとに前方一致でフィルタ。候補の綴りを打ち切ったらそのかな数を確定（commit）して次セグメントの候補を生成する。

- **候補生成 `candidates(in:at:)`**（テストから検証するため internal）:
  - `ん`: 優先順 = ①結合候補 `"n" + 次基本ユニットの綴り`（次綴りの先頭が母音・n・y のものは除外、かな数 = 1 + 次ユニット）②`"nn"` ③`"xn"`。結合候補を先頭に置くことで表示ヒントが「nko」のような最短形になる。語末・次が母音等なら nn 必須になる（結合候補が生成されないため）
  - `っ`: 優先順 = ①重ね子音 1 文字（次基本ユニットの各綴りの先頭文字。母音と n は除外、重複排除。かな数 1 = っ を即確定し、次ユニットは通常どおり打つ → "kko"/"cchi"/"tti" が自然に成立）②`"xtu"` ③`"ltu"` ④`"ltsu"`
  - それ以外: **基本ユニット** = 拗音 2 文字（`RomajiTable.youon` にあれば。かな数 2）+ 単独かな綴り（かな数 1。き + xya の分割入力パス）
- **不変条件**: 同一候補集合内に、ある綴りが別の綴りの真の接頭辞になる組があってはならない（早期確定が長い綴りを潰すため）。`ん` の裸 `"n"` を候補にしない（`"nn"` と衝突する）のはこのため。テストで全パック全位置を検証する
- ミス打鍵は状態を変えない（typed も live も維持）

### 実装コード

```swift
import Foundation

/// ローマ字入力モードのマッチャー。ASCII 打鍵を 1 文字ずつ受け取り、
/// かな課題語への前方一致で確定していく状態機械。
/// 表示用 API（target / done / isComplete / progress）は KanaMatcher と揃える。
nonisolated struct RomajiMatcher {
    let target: String
    private let targetChars: [Character]

    private(set) var kanaDone: Int = 0
    private(set) var typed: String = ""
    private var live: [Candidate] = []

    struct Candidate: Equatable {
        let spelling: String
        let kanaCount: Int
    }

    enum InputResult: Equatable {
        case progress                      // セグメント途中の正しい 1 打鍵
        case correct(kanaCommitted: Int)   // セグメント確定
        case complete(kanaCommitted: Int)  // 語クリア
        case wrong
    }

    init(target: String) {
        self.target = target
        self.targetChars = Array(target)
        self.live = Self.candidates(in: targetChars, at: 0)
    }

    var done: String { String(targetChars.prefix(kanaDone)) }
    var isComplete: Bool { kanaDone >= targetChars.count }
    var progress: Double {
        targetChars.isEmpty ? 1 : Double(kanaDone) / Double(targetChars.count)
    }

    /// 現在セグメントの残り綴り + 後続セグメントの優先綴り（表示ヒント用）
    var remainingRomaji: String {
        guard !isComplete, let first = live.first else { return "" }
        var out = String(first.spelling.dropFirst(typed.count))
        var i = kanaDone + first.kanaCount
        while i < targetChars.count {
            guard let c = Self.candidates(in: targetChars, at: i).first else { break }
            out += c.spelling
            i += c.kanaCount
        }
        return out
    }

    @discardableResult
    mutating func ingest(_ input: Character) -> InputResult {
        guard !isComplete else { return .complete(kanaCommitted: 0) }
        guard let c = Self.normalize(input) else { return .wrong }
        let idx = typed.count
        let matched = live.filter { candidate in
            let s = Array(candidate.spelling)
            return s.count > idx && s[idx] == c
        }
        if matched.isEmpty { return .wrong }
        typed.append(c)
        if let hit = matched.first(where: { $0.spelling.count == typed.count }) {
            kanaDone += hit.kanaCount
            typed = ""
            if isComplete {
                live = []
                return .complete(kanaCommitted: hit.kanaCount)
            }
            live = Self.candidates(in: targetChars, at: kanaDone)
            return .correct(kanaCommitted: hit.kanaCount)
        }
        live = matched
        return .progress
    }

    private static func normalize(_ ch: Character) -> Character? {
        let lowered = ch.lowercased()
        guard lowered.count == 1, let c = lowered.first,
              c.isASCII, c.isLetter else { return nil }
        return c
    }

    /// index 位置から始まるセグメントの候補綴り（先頭が優先綴り）。internal: テストで不変条件を検証する。
    static func candidates(in chars: [Character], at index: Int) -> [Candidate] {
        guard index < chars.count else { return [] }
        switch chars[index] {
        case "ん":
            var result: [Candidate] = []
            for next in baseCandidates(in: chars, at: index + 1) {
                guard let head = next.spelling.first, !"aiueony".contains(head) else { continue }
                result.append(Candidate(spelling: "n" + next.spelling, kanaCount: 1 + next.kanaCount))
            }
            result.append(Candidate(spelling: "nn", kanaCount: 1))
            result.append(Candidate(spelling: "xn", kanaCount: 1))
            return result
        case "っ":
            var result: [Candidate] = []
            var seen = Set<Character>()
            for next in baseCandidates(in: chars, at: index + 1) {
                guard let head = next.spelling.first,
                      !"aiueon".contains(head), !seen.contains(head) else { continue }
                seen.insert(head)
                result.append(Candidate(spelling: String(head), kanaCount: 1))
            }
            result.append(Candidate(spelling: "xtu", kanaCount: 1))
            result.append(Candidate(spelling: "ltu", kanaCount: 1))
            result.append(Candidate(spelling: "ltsu", kanaCount: 1))
            return result
        default:
            return baseCandidates(in: chars, at: index)
        }
    }

    /// ん・っ 以外の「基本ユニット」候補（拗音 or 単独かな）
    private static func baseCandidates(in chars: [Character], at index: Int) -> [Candidate] {
        guard index < chars.count else { return [] }
        var result: [Candidate] = []
        if index + 1 < chars.count,
           let combos = RomajiTable.youon[String(chars[index...index + 1])] {
            result += combos.map { Candidate(spelling: $0, kanaCount: 2) }
        }
        if let singles = RomajiTable.kana[chars[index]] {
            result += singles.map { Candidate(spelling: $0, kanaCount: 1) }
        }
        return result
    }
}
```

### テストマトリクス（TDD: グループごとに RED → GREEN → commit）

`RomajiMatcherTests.swift` に順次追加。ヘルパー:

```swift
import Testing
@testable import wakuwaku_typing

struct RomajiMatcherTests {
    @discardableResult
    private func type(_ s: String, into m: inout RomajiMatcher) -> [RomajiMatcher.InputResult] {
        s.map { m.ingest($0) }
    }
```

1. **基本** — `ねこ` を "neko"（progress/correct(1)/progress/complete(1)、done の遷移）。大文字 "NEKO" も可。非英字（"1", " "）は .wrong
2. **綴りバリエーション**（parameterized `@Test(arguments:)`）— し=shi/si、ち=chi/ti、つ=tsu/tu、ふ=fu/hu、じ=ji/zi、ぢ=di、づ=du、を=wo、が=ga、ぱ=pa
3. **拗音** — きゃ="kya" は complete(kanaCommitted: 2)。分割 "kixya"・"kilya" は correct(1)+complete(1)。じゃ=ja/jya/zya
4. **っ** — っこ: "kko"（'k' で correct(1)・done=="っ"、以降 "ko"）と "xtuko"。っち: "cchi"/"tti"。っしゃ: "ssha"
5. **ん** — んこ: "nko"（'o' で correct/complete(kanaCommitted: 2)）と "nnko"。ほん: "honn"（"hon" 時点では isComplete == false）。んあ相当: 'n'→progress, 'a'→wrong, 'n'→correct(1), 'a'→complete(1)。こんやく: "konnyaku"（や の前は nn 必須。"nya" と打つと 'y' が wrong）
6. **ミスは状態を壊さない** — しゃ: "s", "k"(wrong), "h", "a" で完走
7. **表示ヒント** — っこ: remainingRomaji == "kko"。んこ: "nko"。こんにちは: "konnnichiha"。し を "s" まで打つと remaining == "hi"（優先綴り追従）
8. **接頭辞不変条件** — 全アクティブパック全エントリの全確定位置で、候補集合に真の接頭辞ペアがないこと（`RomajiMatcher.candidates(in:at:)` を直接検証）

**各グループごとに**: テスト追加 → 実行(FAIL) → 実装 → 実行(PASS) → commit。
最終 commit: `feat: add RomajiMatcher with multi-spelling romaji-to-kana state machine`

## Task 4: 全パックのローマ字化可能性テスト

**Files:**

- Modify: `wakuwaku-typingTests/WordPackTests.swift`

```swift
@Test func allActivePackEntriesAreRomajiTypable() {
    for pack in WordPacks.active {
        for entry in pack.entries {
            var m = RomajiMatcher(target: entry)
            var steps = 0
            while !m.isComplete, steps < 300 {
                guard let ch = m.remainingRomaji.first else { break }
                #expect(m.ingest(ch) != .wrong, "entry: \(entry)")
                steps += 1
            }
            #expect(m.isComplete, "entry: \(entry)")
        }
    }
}
```

Run → PASS → commit: `test: verify all pack entries are typable in romaji mode`

## Task 5: GameViewModel 統合

**Files:**

- Modify: `wakuwaku-typing/State/GameViewModel.swift`
- Test: `wakuwaku-typingTests/GameViewModelRomajiTests.swift`（新規）

**Step 1: 失敗するテスト**（決定的にするため単一エントリのテストパックを使う）

```swift
import Testing
@testable import wakuwaku_typing

struct GameViewModelRomajiTests {
    private func makeVM(entry: String) -> GameViewModel {
        let pack = WordPack(id: "t", jp: "テスト", en: "TEST", sample: "", desc: "", entries: [entry])
        return GameViewModel(pack: pack, duration: 30, difficulty: .normal, inputMode: .romaji)
    }

    @Test func scoresPerKanaOnCommitOnly() {
        let vm = makeVM(entry: "ねこ")
        defer { vm.quit() }
        vm.handleAscii("n")
        #expect(vm.stats.score == 0)          // セグメント途中は加点なし
        vm.handleAscii("e")
        #expect(vm.stats.score == 1)          // combo1 → 1pt
        #expect(vm.stats.combo == 1)
        vm.handleAscii("k")
        vm.handleAscii("o")
        #expect(vm.stats.score == 2)          // combo2 → 1pt
        #expect(vm.stats.words == 1)
        #expect(vm.stats.correctChars == 2)   // かな単位
    }

    @Test func multiKanaCommitAwardsEachKana() {
        let vm = makeVM(entry: "んこ")
        defer { vm.quit() }
        vm.handleAscii("n")
        vm.handleAscii("k")
        vm.handleAscii("o")                   // ん+こ を一括確定
        #expect(vm.stats.combo == 2)
        #expect(vm.stats.score == 2)
        #expect(vm.stats.words == 1)
    }

    @Test func wrongKeyResetsCombo() {
        let vm = makeVM(entry: "ねこ")
        defer { vm.quit() }
        vm.handleAscii("n")
        vm.handleAscii("e")
        vm.handleAscii("q")                   // miss
        #expect(vm.stats.combo == 0)
        #expect(vm.stats.wrongChars == 1)
        #expect(vm.stats.score == 1)          // 減点はしない
    }

    @Test func courseStringMarksRomajiMode() {
        let vm = makeVM(entry: "ねこ")
        defer { vm.quit() }
        #expect(vm.currentResult().course.hasSuffix(" / R"))
    }
}
```

**Step 3: 実装** — 変更点:

- `let inputMode: InputMode` を追加、`init(pack:duration:difficulty:inputMode: InputMode = .flick)`（既定値 `.flick` で既存呼び出しは無変更）
- `private(set) var matcher: KanaMatcher` → `private(set) var kanaMatcher: KanaMatcher?` + `private(set) var romajiMatcher: RomajiMatcher?`（モードに応じて一方だけ非 nil。init と `advanceWord()` で生成）
- 表示用アクセサ追加: `var targetText: String { kanaMatcher?.target ?? romajiMatcher?.target ?? "" }`、`var doneText: String`（同型）、`var romajiTyped: String { romajiMatcher?.typed ?? "" }`、`var romajiRemaining: String { romajiMatcher?.remainingRomaji ?? "" }`
- `expectedKey` は `kanaMatcher?.expectedNext` に（フリック専用のまま）
- `handle(_:)` / `handleModifier()` は `kanaMatcher?.ingest(...)` 経由に書き換え（optional chaining は in-place mutate する）。**process(_:) と加点ロジックの意味論は不変**
- 新設:

```swift
func handleAscii(_ ch: Character) {
    guard inputMode == .romaji, !finished else { return }
    if !started { start() }
    guard let result = romajiMatcher?.ingest(ch) else { return }
    processRomaji(result)
}

private func processRomaji(_ result: RomajiMatcher.InputResult) {
    switch result {
    case .progress:
        break
    case .correct(let n):
        awardKana(count: n)
        spawnParticles(forCombo: stats.combo, isComplete: false)
        Haptics.tap()
    case .complete(let n):
        awardKana(count: n)
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
    }
}

private func awardKana(count: Int) {
    for _ in 0..<count {
        stats.correctChars += 1
        stats.combo += 1
        stats.maxCombo = max(stats.maxCombo, stats.combo)
        stats.score += ScoreCalculator.points(forCombo: stats.combo)
    }
}
```

- `currentResult()` の course: `"\(pack.jp) / \(duration)s" + (inputMode == .romaji ? " / R" : "")`
- `advanceWord()`: 現在ターゲットは `targetText` から取得し、モード別にマッチャー再生成

**Step 4: 既存テスト含め全 unit テスト PASS 確認**

**Step 5: Commit** `feat: integrate romaji input mode into GameViewModel scoring`

## Task 6: UI 統合（GameView / KanaInputField / SettingsView）

**Files:**

- Modify: `wakuwaku-typing/Screens/GameView.swift`
- Modify: `wakuwaku-typing/Screens/SettingsView.swift`

**GameView.init**: `GameViewModel(pack:..., inputMode: settings.inputMode)` を渡す。

**attributedTarget** (162-163 行付近): `viewModel.matcher.done/target` → `viewModel.doneText` / `viewModel.targetText`。

**feed(old:new:)**: モード分岐。

```swift
private func feed(old: String, new: String) {
    defer { prevInput = new }
    if viewModel.inputMode == .romaji {
        guard new.count > old.count else { return }   // ASCII は追加のみ。削除・置換は無視
        for ch in new.dropFirst(old.count) {
            viewModel.handleAscii(ch)
        }
        return
    }
    // 既存のフリック処理は無変更
    ...
}
```

**inputHint**: フリック時は現状のまま。ローマ字時:

- 文言 "英字キーボードでローマ字入力"
- ローマ字ガイド行: `viewModel.romajiTyped`（theme.accent、打鍵済み）+ `viewModel.romajiRemaining`（theme.textDim）を `AppFont.pixel(12)` の 1 行で連結表示（`Text(...) + Text(...)`）。既存の NEXT 行はローマ字時はガイド行に置き換える

**KanaInputField**: `let asciiMode: Bool` を追加し `makeUIView` で `tf.keyboardType = asciiMode ? .asciiCapable : .default`。呼び出し側 `KanaInputField(text: $input, isFocused: $inputFocused, asciiMode: viewModel.inputMode == .romaji)`。

**SettingsView**: DIFFICULTY 行の下に追加（seg のラベルは PressStart2P に無いかな字を避けて英字）:

```swift
row(label: "INPUT MODE") {
    seg(
        value: appState.settings.inputMode,
        options: [(.flick, "FLICK"), (.romaji, "ROMAJI")],
        onChange: { v in appState.updateSettings { $0.inputMode = v } }
    )
}
```

**Step: ビルド + 全テスト PASS → Commit** `feat: add romaji input mode UI (keyboard, guide, settings toggle)`

## Task 7: 最終検証

1. `xcodebuild ... build` — ビルド成功
2. `xcodebuild ... test` — unit + UI テスト全 PASS（既存 OnboardingFlowUITests がモード追加で壊れていないこと）
3. シミュレータ手動確認（可能なら）:
   - 設定 → INPUT MODE → ROMAJI → ゲーム開始 → 英字キーボードが出る → "neko" 等で確定・加点・パーティクル
   - FLICK に戻す → かなキーボード・従来動作
   - 旧データ互換: 一度旧版相当のデータで起動確認（Task 1 のテストで担保済み）

## 明示的にやらないこと（YAGNI）

- ローマ字専用リーダーボード（既存共用で確定）
- オンボーディングへのモード選択追加
- "tchi"（っち のヘボン公式表記）、"n'"、ca/ci/cu/ce/co、ふぁ/てぃ 等の外来音拗音（パック未使用）
- アプリ内キーボード描画
