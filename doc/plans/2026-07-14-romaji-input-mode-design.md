# ローマ字入力モード 設計書

日付: 2026-07-14（2026-07-15 スコアリング方針確定）
ステータス: 承認済み（実装へ）

## 目的

現在フリック入力（システムかなキーボード）専用のゲームに、ローマ字入力モードを追加する。
フリック入力が苦手なユーザーが、英字（QWERTY）キーボードでローマ字を打ってかなの課題語をクリアできるようにする。

## 方式の比較と採用案

| 案 | 概要 | 判定 |
| --- | --- | --- |
| **A. 自前ローマ字マッチャー + システム英字キーボード** | 隠し UITextField を `keyboardType = .asciiCapable` にし、ASCII 1 文字ずつを自前の `RomajiMatcher` で判定 | **採用** |
| B. iOS のローマ字かな IME に変換させる | 既存 KanaMatcher を再利用できるが、キーボード種別を強制できず、変換候補・確定タイミングが制御不能 | 不採用 |
| C. アプリ内に QWERTY キーボードを描画 | 完全制御できるが工数大、ネイティブ感が失われる | 不採用（将来の選択肢） |

案 A は寿司打・e-typing 等の定番方式。判定ロジックが純粋関数になりテストしやすく、既存の「かな課題語 → マッチャー → GameViewModel」パイプラインをそのまま使える。

## 新規モジュール: RomajiMatcher

`wakuwaku-typing/Game/RomajiMatcher.swift`（`nonisolated` な純データ型。WordPack.swift のパターンに倣う）

### 責務

課題かな文字列を「入力単位」に分解し、ASCII 1 文字ずつの入力を判定する状態機械。
`KanaMatcher` と同じ表示用 API（`target` / `done` / `expectedNext` 相当 / `isComplete` / `progress`）を持たせ、GameView の表示コードを共有する。

### かな分解と綴りテーブル

- **拗音ユニット**: かな + 小書き ゃゅょ（例: きゃ）を 1 ユニットとして複数綴りを許容（きゃ = kya、または ki + xya/lya の分割入力）
- **複数綴り対応**（ヘボン式 + 訓令式 + IME 慣用）:
  - し = shi/si、ち = chi/ti、つ = tsu/tu、ふ = fu/hu、じ = ji/zi、ぢ = di、づ = du、を = wo
  - しゃ = sha/sya、ちゃ = cha/tya/cya、じゃ = ja/jya/zya など
- **促音 っ**: 次ユニットの綴り先頭子音の重ね打ち（っこ = kko、っち = cchi/tti）、または単独 xtu/ltu/ltsu
- **ん**: nn は常に可。単独 n は次が子音（n/y と母音以外）で始まる場合のみ可。語末は nn 必須
- **小書き単独**（ぁぃぅぇぉゃゅょ 等）: xa/la 系で入力可能（拗音分割入力のフォールバック）

### 状態機械の結果型

```text
ingest(ascii) -> .correct(committedKanaCount)  // ユニット確定（きゃ なら 2 かな分）
              | .progress                       // ユニット途中の正しい 1 打鍵（減点なし・加点なし）
              | .wrong                          // どの許容綴りにも合致しない
              | .complete                       // 語クリア
```

ユーザーが打った綴りに追従して残り表示を適応させる（"s" まで打ったら し の残りは "hi" でも "i" でも受理し、表示は最短綴りを提示）。

## スコアリング（確定）

- **かな確定ごとに加点**（フリックと同一の定義）: ユニット確定時に確定かな数ぶん `combo` を進め `ScoreCalculator.points(forCombo:)` を加算。途中打鍵（.progress）は加点なし
- ミス打鍵（.wrong）: `combo = 0`、`wrongChars += 1`（フリックと同じ）
- `correctChars` は確定かな数、`wrongChars` はミス打鍵数（accuracy の分母が混在するが v1 は許容）

> ✅ **確定（2026-07-15）**: 「かな単位加点 + 既存リーダーボード共用」で決定。ローマ字はかな 1 文字あたり打鍵数が多くスコアは低めに出るが、定義が一貫しインフレしない方向なのでボード汚染はない。専用リーダーボードは作らない。

## 設定とデータモデル

### InputMode enum（GameSettings.swift）

```swift
enum InputMode: String, Codable, CaseIterable {
    case flick
    case romaji
}
```

### AppSettings への追加（⚠️ 後方互換が最重要）

`AppSettings` に `inputMode` を追加すると、**synthesized Codable では既存ユーザーの保存 JSON がデコード失敗し、`Persistence.load()` が nil → 設定・履歴・累積スコアが全消去される**。

対策: カスタム `init(from:)` で `decodeIfPresent` + デフォルト `.flick`。
既存フィールドのみの JSON フィクスチャをデコードするテストを必ず追加する。

## GameViewModel の変更

- `init` に `inputMode` を追加（GameView.init が `settings.inputMode` を渡す）
- マッチャー保持: 表示用の共通プロトコル（`target`/`done`/`progress`/`isComplete`）を切り、入力系はモード別メソッドで分岐
  - フリック: 既存 `handle(_:)` / `handleModifier()`（**一切変更しない** — KanaMatcherTests の意味論を保全）
  - ローマ字: 新設 `handleAscii(_:)` → `RomajiMatcher.ingest` → 既存 `process()` 相当の加点・パーティクル・ハプティクスへ合流
- `advanceWord()` はモードに応じたマッチャーを生成

## GameView / KanaInputField の変更

- `KanaInputField` に mode パラメータ追加: romaji 時は `keyboardType = .asciiCapable`（英字キーボードを強制。IME 候補バー問題は ASCII では発生しない）
- `feed(old:new:)`: romaji 時は「追加」のみ処理（小文字化して `handleAscii`）。同長置換（かな修飾）は発生しない。バックスペースは従来どおり無視
- **ローマ字ガイド表示**: かな課題語の下に、現在ユニットの「打ち終えた綴り（ハイライト）+ 残り最短綴り + 後続ユニットの標準綴り」を 1 行表示。`NEXT:` ヒントは次に打つべき英字 1 文字に
- 入力ヒント文言をモードで切替（「iOS かなキーボードで入力」→「英字キーボードでローマ字入力」）

## SettingsView / その他 UI

- `INPUT MODE` 行を追加（既存 `seg` コンポーネントで「フリック / ローマ字」2 択）
- `GameResult.course` に入力モードを付記（例: `ことわざ / 30s / R`）— 履歴・リザルト画面で区別可能に
- オンボーディングは v1 では変更しない（設定画面からの切替のみ）

## Game Center

- 送信経路は変更なし（同一リーダーボードに同一定義のスコアを送信）
- entitlements / App Store Connect の変更なし（専用ボード案を採る場合のみ将来対応）

## テスト計画（Swift Testing）

1. **RomajiMatcherTests**（本丸・最初に書く）
   - 五十音・濁音・半濁音・を
   - ん: nn / 子音前の単独 n / 母音・な行・や行前は nn 必須 / 語末 nn
   - っ: 子音重ね（kko, tti, cchi）/ xtu・ltu 単独
   - 拗音: sha/sya、cha/tya、分割入力（ki + xya）
   - 綴り追従（s→i と s→h→i の両受理）、ミス判定、combo 起点、progress/done 表示、語クリア
2. **WordPackTests 追加**: 全アクティブパックの全エントリが RomajiMatcher で完走可能（ローマ字化可能性の網羅検証。現行パックは標準ひらがなのみで問題ないことを確認済み）
3. **AppSettings 後方互換テスト**: `inputMode` なし JSON のデコードで既定値 `.flick`、データ消失なし
4. **GameViewModel テスト**: romaji モードでの加点タイミング（ユニット途中は加点なし、確定でかな数ぶん加算）
5. **UI テスト（任意）**: WT_RESET 起動 → 設定でローマ字に切替 → ゲーム画面のヒント文言確認

## 実装ステップ（TDD 順）

1. `InputMode` + `AppSettings.inputMode`（カスタムデコード）+ 後方互換テスト
2. 綴りテーブル + `RomajiMatcher` を TDD で構築（テストマトリクス先行）
3. WordPack ローマ字化可能性テスト
4. GameViewModel: モード注入・`handleAscii`・スコア合流
5. GameView / KanaInputField: キーボード種別・feed 分岐・ローマ字ガイド UI
6. SettingsView の INPUT MODE 行 + course 付記
7. ビルド + 全テスト + シミュレータで両モード手動確認

規模感: 中心は RomajiMatcher（綴りテーブル + 状態機械 + テスト群）。それ以外は既存構造への薄い追加で済む。
