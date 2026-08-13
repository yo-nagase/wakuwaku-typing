import SwiftUI

struct LeaderboardView: View {
    let theme: Theme
    let appState: AppState
    let onBack: () -> Void

    enum Tab { case total, best, history }
    @State private var tab: Tab = .total
    @State private var open: Entry?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    /// nil = 不明（Game Center の他プレイヤーは context 由来の統計しか持たない）。表示は「—」。
    struct Entry: Identifiable, Hashable {
        let id = UUID()
        var rank: Int
        let name: String
        let best: Int?
        let total: Int?
        let games: Int?
        let wpm: Int?
        let acc: Int?
        let combo: Int?
        let words: Int?
        let time: Int?
        let date: String
        let course: String
        let isYou: Bool
    }

    private static let cpus: [Entry] = [
        Entry(rank: 0, name: "CPU.AI",  best: 320, total: 0, games: 18, wpm: 142, acc: 99, combo: 48, words: 71, time: 60, date: "2026-04-29 09:14", course: "ことわざ / 60s", isYou: false),
        Entry(rank: 0, name: "KAZ★88",  best: 248, total: 0, games: 24, wpm: 118, acc: 96, combo: 32, words: 59, time: 60, date: "2026-04-28 22:03", course: "ことわざ / 60s", isYou: false),
        Entry(rank: 0, name: "TYPER77", best: 195, total: 0, games: 41, wpm: 102, acc: 94, combo: 24, words: 51, time: 30, date: "2026-04-28 14:50", course: "ことわざ / 30s", isYou: false),
        Entry(rank: 0, name: "MOMO♥",   best: 158, total: 0, games: 32, wpm: 88,  acc: 92, combo: 19, words: 44, time: 30, date: "2026-04-27 19:22", course: "ことわざ / 30s", isYou: false),
        Entry(rank: 0, name: "NEKO99",  best: 112, total: 0, games: 56, wpm: 71,  acc: 90, combo: 14, words: 36, time: 30, date: "2026-04-26 11:08", course: "ことわざ / 30s", isYou: false),
        Entry(rank: 0, name: "SORA22",  best: 88,  total: 0, games: 12, wpm: 60,  acc: 88, combo: 11, words: 30, time: 60, date: "2026-04-25 20:40", course: "ことわざ / 60s", isYou: false),
        Entry(rank: 0, name: "YUKI★",   best: 70,  total: 0, games: 28, wpm: 52,  acc: 85, combo: 8,  words: 26, time: 30, date: "2026-04-25 08:12", course: "ことわざ / 30s", isYou: false),
    ]

    private func boards() -> (total: [Entry], best: [Entry]) {
        let cpuFilled = Self.cpus.map { e in
            var x = e
            // approximate cumulative — best * games^0.7 (CPU ダミーは全フィールド非 nil)
            let est = Int(Double(e.best ?? 0) * pow(Double(e.games ?? 0), 0.7))
            x = Entry(rank: 0, name: e.name, best: e.best, total: est, games: e.games, wpm: e.wpm, acc: e.acc, combo: e.combo, words: e.words, time: e.time, date: e.date, course: e.course, isYou: false)
            return x
        }
        let history = appState.history
        let me = history.max(by: { $0.score < $1.score })
        let myTotal = history.reduce(0) { $0 + $1.score }
        let myBest = me?.score ?? 0
        let formatter: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withFullDate, .withSpaceBetweenDateAndTime, .withColonSeparatorInTime]
            return f
        }()
        let dateStr: String = me.map { entry in
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd HH:mm"
            return f.string(from: entry.date)
        } ?? "—"
        let me2 = Entry(
            rank: 0,
            name: appState.settings.name.isEmpty ? "YOU" : appState.settings.name,
            best: myBest,
            total: myTotal,
            games: history.count,
            wpm: me?.wpm ?? 0,
            acc: me?.acc ?? 0,
            combo: me?.combo ?? 0,
            words: me?.words ?? 0,
            time: me?.time ?? 30,
            date: dateStr,
            course: me?.course ?? "—",
            isYou: true
        )
        _ = formatter
        let combined = cpuFilled + [me2]
        let totalRanked = combined.sorted { ($0.total ?? 0) > ($1.total ?? 0) }.enumerated().map { (i, e) -> Entry in
            var x = e; x.rank = i + 1; return x
        }
        let bestRanked = combined.sorted { ($0.best ?? 0) > ($1.best ?? 0) }.enumerated().map { (i, e) -> Entry in
            var x = e; x.rank = i + 1; return x
        }
        return (totalRanked, bestRanked)
    }

    var body: some View {
        ScreenChrome(theme: theme, title: "🏆 LEADERBOARD", onBack: onBack) {
            VStack(spacing: 12) {
                // Game Center リーダーボード表示ボタン
                if appState.gameCenter.isAuthenticated {
                    Button {
                        appState.gameCenter.showLeaderboard()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 12))
                            Text("GAME CENTER")
                                .font(AppFont.pixel(10))
                                .kerning(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color.black)
                        .background(theme.secondary)
                        .overlay(Rectangle().stroke(theme.secondary, lineWidth: 2))
                        .glow(theme.secondary, radius: 8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }

                tabSwitcher
                Text(tabDescription)
                    .font(AppFont.pixel(8))
                    .kerning(1)
                    .foregroundStyle(theme.textDim)
                    .frame(maxWidth: .infinity)
                    .padding(6)
                    .overlay(Rectangle().stroke(style: .init(lineWidth: 1, dash: [4, 3])).foregroundStyle(theme.textDim))

                if tab == .history {
                    historyList
                } else if let remote = remoteEntries {
                    if remote.isEmpty {
                        emptyBox(title: "NO SCORES YET", subtitle: "プレイするとランキングに載ります")
                    } else {
                        VStack(spacing: 4) {
                            ForEach(remote, id: \.id) { entry in
                                rowButton(entry: entry, value: (tab == .total ? entry.total : entry.best) ?? 0)
                            }
                        }
                    }
                } else if appState.gameCenter.isAuthenticated && appState.gameCenter.isLoadingLeaderboards {
                    emptyBox(title: "LOADING...", subtitle: "GAME CENTERから取得中")
                } else {
                    let b = boards()
                    let list = tab == .total ? b.total : b.best
                    VStack(spacing: 4) {
                        ForEach(list, id: \.id) { entry in
                            rowButton(entry: entry, value: (tab == .total ? entry.total : entry.best) ?? 0)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .task(id: appState.gameCenter.isAuthenticated) {
            appState.gameCenter.refreshLeaderboards()
        }
        .sheet(item: $open) { entry in
            detailModal(for: entry)
        }
    }

    // MARK: - Game Center 実データ

    /// 認証済みかつ取得済みなら現在のタブに対応する実ランキングを返す。nil = ローカル(CPU)フォールバック表示。
    private var remoteEntries: [Entry]? {
        guard appState.gameCenter.isAuthenticated else { return nil }
        switch tab {
        case .total:
            return appState.gameCenter.remoteTotal.map { $0.map { entry(fromRemote: $0, isTotalBoard: true) } }
        case .best:
            return appState.gameCenter.remoteBest.map { $0.map { entry(fromRemote: $0, isTotalBoard: false) } }
        case .history:
            return nil
        }
    }

    private func entry(fromRemote r: RemoteLeaderboardEntry, isTotalBoard: Bool) -> Entry {
        // context に統計がパックされていれば復元（context=0 の旧スコアは nil → 「—」表示）
        let ctx = ScoreContext(decoding: r.context)
        let name = r.isLocalPlayer && !appState.settings.name.isEmpty ? appState.settings.name : r.name
        return Entry(
            rank: r.rank,
            name: name,
            best: isTotalBoard ? nil : r.score,
            total: isTotalBoard ? r.score : nil,
            games: r.isLocalPlayer ? appState.totalGames : nil,
            wpm: ctx?.wpm,
            acc: ctx?.acc,
            combo: ctx?.combo,
            words: ctx?.words,
            time: ctx?.time,
            date: Self.dateFormatter.string(from: r.date),
            course: ctx.map { "\($0.time)s" } ?? "—",
            isYou: r.isLocalPlayer
        )
    }

    private func emptyBox(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(AppFont.pixel(11))
                .kerning(2)
                .foregroundStyle(theme.textDim)
            Text(subtitle)
                .font(AppFont.kana(10))
                .kerning(2)
                .foregroundStyle(theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .overlay(Rectangle().stroke(style: .init(lineWidth: 1, dash: [4, 3])).foregroundStyle(theme.textDim))
    }

    private func fmt(_ value: Int?) -> String {
        value.map(String.init) ?? "—"
    }

    private var tabSwitcher: some View {
        HStack(spacing: 4) {
            tabButton(.total, label: "★ TOTAL", jp: "累計")
            tabButton(.best, label: "♕ BEST", jp: "ベスト")
            tabButton(.history, label: "≡ LOG", jp: "履歴")
        }
    }

    private var tabDescription: String {
        let isRemote = remoteEntries != nil
        switch tab {
        case .total: return isRemote ? "累計スコア = GAME CENTER RANKING" : "累計スコア = ALL GAMES SUMMED"
        case .best: return isRemote ? "ベストスコア = GAME CENTER RANKING" : "ベストスコア = SINGLE BEST RUN"
        case .history: return "プレイ履歴 = RECENT GAMES"
        }
    }

    @ViewBuilder
    private var historyList: some View {
        let history = appState.history
        if history.isEmpty {
            emptyBox(title: "NO GAMES YET", subtitle: "まだプレイ履歴がありません")
        } else {
            VStack(spacing: 4) {
                ForEach(Array(history.enumerated()), id: \.element.id) { (i, h) in
                    historyRowButton(index: i, entry: h)
                }
            }
        }
    }

    private func historyRowButton(index: Int, entry h: HistoryEntry) -> some View {
        Button { open = entry(from: h, rank: index + 1) } label: {
            HStack(spacing: 0) {
                Text(String(format: "%02d", index + 1))
                    .font(AppFont.pixel(14))
                    .foregroundStyle(index == 0 ? theme.accent : theme.textDim)
                    .frame(width: 36, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.dateFormatter.string(from: h.date))
                        .font(AppFont.pixel(10))
                        .kerning(1)
                        .foregroundStyle(theme.text)
                    Text("\(h.course) · \(h.wpm)wpm · \(h.acc)%")
                        .font(AppFont.pixel(8))
                        .kerning(1)
                        .foregroundStyle(theme.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(h.score) PTS")
                    .font(AppFont.pixel(11))
                    .foregroundStyle(theme.accent)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.3))
            .overlay(Rectangle().stroke(theme.textDim, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func entry(from h: HistoryEntry, rank: Int) -> Entry {
        Entry(
            rank: rank,
            name: appState.settings.name.isEmpty ? "YOU" : appState.settings.name,
            best: h.score,
            total: h.score,
            games: 1,
            wpm: h.wpm,
            acc: h.acc,
            combo: h.combo,
            words: h.words,
            time: h.time,
            date: Self.dateFormatter.string(from: h.date),
            course: h.course,
            isYou: true
        )
    }

    private func tabButton(_ which: Tab, label: String, jp: String) -> some View {
        Button { tab = which } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(AppFont.pixel(10))
                    .kerning(2)
                Text(jp)
                    .font(AppFont.kana(9))
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(tab == which ? Color.black : theme.text)
            .background(tab == which ? theme.primary : Color.clear)
            .overlay(Rectangle().stroke(theme.primary, lineWidth: 2))
            .glow(tab == which ? theme.primary : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }

    private func rowButton(entry: Entry, value: Int) -> some View {
        Button { open = entry } label: {
            HStack(spacing: 0) {
                Text(String(format: "%02d", entry.rank))
                    .font(AppFont.pixel(14))
                    .foregroundStyle(entry.rank == 1 ? theme.accent : (entry.rank <= 3 ? theme.secondary : theme.textDim))
                    .frame(width: 36, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name + (entry.isYou ? " ◀" : ""))
                        .font(AppFont.pixel(11))
                        .kerning(1)
                        .foregroundStyle(entry.isYou ? theme.accent : theme.text)
                    if tab == .best {
                        Text(entry.date)
                            .font(AppFont.pixel(7))
                            .kerning(1)
                            .foregroundStyle(theme.textDim)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(tab == .total
                    ? entry.games.map { "×\($0)" } ?? "—"
                    : entry.wpm.map { "\($0)wpm" } ?? "—")
                    .font(AppFont.pixel(8))
                    .foregroundStyle(theme.secondary)
                    .padding(.trailing, 10)
                Text("\(value) PTS")
                    .font(AppFont.pixel(11))
                    .foregroundStyle(theme.accent)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(entry.isYou ? theme.primary.opacity(0.3) : Color.black.opacity(0.3))
            .overlay(Rectangle().stroke(entry.isYou ? theme.accent : theme.textDim, lineWidth: entry.isYou ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func detailModal(for entry: Entry) -> some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("#\(entry.rank) \(entry.name)")
                    .font(AppFont.pixel(12))
                    .kerning(2)
                    .foregroundStyle(theme.accent)
                HStack(spacing: 12) {
                    StatBlock(theme: theme, label: "★ TOTAL", value: fmt(entry.total))
                    StatBlock(theme: theme, label: "♕ BEST", value: fmt(entry.best))
                    StatBlock(theme: theme, label: "GAMES", value: fmt(entry.games))
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    StatBlock(theme: theme, label: "WPM", value: fmt(entry.wpm))
                    StatBlock(theme: theme, label: "ACC", value: entry.acc.map { "\($0)%" } ?? "—")
                    StatBlock(theme: theme, label: "COMBO", value: fmt(entry.combo))
                    StatBlock(theme: theme, label: "WORDS", value: fmt(entry.words))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("COURSE: \(entry.course)")
                        .font(AppFont.pixel(9))
                        .foregroundStyle(theme.secondary)
                    Text("WHEN: \(entry.date)")
                        .font(AppFont.pixel(9))
                        .foregroundStyle(theme.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                PixelButton(theme: theme, small: true, "CLOSE ✕") { open = nil }
            }
            .padding(20)
        }
        .presentationDetents([.medium])
    }
}
