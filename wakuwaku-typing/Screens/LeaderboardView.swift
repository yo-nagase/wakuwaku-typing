import SwiftUI

struct LeaderboardView: View {
    let theme: Theme
    let appState: AppState
    let onBack: () -> Void

    enum Tab { case total, best }
    @State private var tab: Tab = .total
    @State private var open: Entry?

    struct Entry: Identifiable, Hashable {
        let id = UUID()
        var rank: Int
        let name: String
        let best: Int
        let total: Int
        let games: Int
        let wpm: Int
        let acc: Int
        let combo: Int
        let words: Int
        let time: Int
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
            // approximate cumulative — best * games^0.7
            let est = Int(Double(e.best) * pow(Double(e.games), 0.7))
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
        let totalRanked = combined.sorted { $0.total > $1.total }.enumerated().map { (i, e) -> Entry in
            var x = e; x.rank = i + 1; return x
        }
        let bestRanked = combined.sorted { $0.best > $1.best }.enumerated().map { (i, e) -> Entry in
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
                Text(tab == .total ? "累計スコア = ALL GAMES SUMMED" : "ベストスコア = SINGLE BEST RUN")
                    .font(AppFont.pixel(8))
                    .kerning(1)
                    .foregroundStyle(theme.textDim)
                    .frame(maxWidth: .infinity)
                    .padding(6)
                    .overlay(Rectangle().stroke(style: .init(lineWidth: 1, dash: [4, 3])).foregroundStyle(theme.textDim))

                let b = boards()
                let list = tab == .total ? b.total : b.best
                VStack(spacing: 4) {
                    ForEach(list, id: \.id) { entry in
                        rowButton(entry: entry, value: tab == .total ? entry.total : entry.best)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .sheet(item: $open) { entry in
            detailModal(for: entry)
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 4) {
            tabButton(.total, label: "★ TOTAL", jp: "累計")
            tabButton(.best, label: "♕ BEST", jp: "ベスト")
        }
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
                Text(entry.name + (entry.isYou ? " ◀" : ""))
                    .font(AppFont.pixel(11))
                    .kerning(1)
                    .foregroundStyle(entry.isYou ? theme.accent : theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(tab == .total ? "×\(entry.games)" : "\(entry.wpm)wpm")
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
                    StatBlock(theme: theme, label: "★ TOTAL", value: "\(entry.total)")
                    StatBlock(theme: theme, label: "♕ BEST", value: "\(entry.best)")
                    StatBlock(theme: theme, label: "GAMES", value: "\(entry.games)")
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    StatBlock(theme: theme, label: "WPM", value: "\(entry.wpm)")
                    StatBlock(theme: theme, label: "ACC", value: "\(entry.acc)%")
                    StatBlock(theme: theme, label: "COMBO", value: "\(entry.combo)")
                    StatBlock(theme: theme, label: "WORDS", value: "\(entry.words)")
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
