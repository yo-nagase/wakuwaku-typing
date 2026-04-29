import SwiftUI

struct ResultsView: View {
    let theme: Theme
    let result: GameResult
    let isNewBest: Bool
    let onRestart: () -> Void
    let onHome: () -> Void

    private var score: Int {
        ScoreCalculator.score(wpm: result.wpm, accuracyPercent: result.acc, combo: result.combo)
    }

    private var rank: Rank {
        ScoreCalculator.rank(for: score)
    }

    private var rankColor: Color {
        switch rank {
        case .s: return theme.accent
        case .a: return theme.primary
        case .b: return theme.secondary
        case .c, .d: return theme.textDim
        }
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            CRTOverlay(theme: theme).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("★ TIME UP ★")
                        .font(AppFont.pixel(16))
                        .kerning(6)
                        .foregroundStyle(theme.primary)
                        .glow(theme.primary, radius: 12)
                        .padding(.top, 40)

                    Text("じかん きれ")
                        .font(AppFont.kana(12))
                        .kerning(6)
                        .foregroundStyle(theme.textDim)

                    if isNewBest {
                        Text("♕ NEW BEST SCORE ♕")
                            .font(AppFont.pixel(11))
                            .kerning(3)
                            .foregroundStyle(theme.accent)
                            .glow(theme.accent, radius: 8)
                            .padding(.top, 12)
                    }

                    rankBadge
                        .padding(.top, 24)

                    Text("\(score) PTS")
                        .font(AppFont.pixel(28))
                        .kerning(2)
                        .foregroundStyle(theme.accent)
                        .glow(theme.accent, radius: 16)

                    statsGrid
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    HStack(spacing: 12) {
                        PixelButton(theme: theme, primary: true, "↻ AGAIN", action: onRestart)
                        PixelButton(theme: theme, small: true, "🏠 HOME", action: onHome)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .foregroundStyle(theme.text)
    }

    private var rankBadge: some View {
        Text(rank.rawValue)
            .font(AppFont.pixel(72))
            .foregroundStyle(rankColor)
            .glow(rankColor, radius: 24)
            .frame(width: 110, height: 110)
            .background(Color.black.opacity(0.4))
            .overlay(Rectangle().stroke(rankColor, lineWidth: 5))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            StatBlock(theme: theme, label: "WPM", value: "\(result.wpm)", big: true)
            StatBlock(theme: theme, label: "ACCURACY", value: "\(result.acc)%", big: true)
            StatBlock(theme: theme, label: "MAX COMBO", value: "\(result.combo)")
            StatBlock(theme: theme, label: "WORDS", value: "\(result.words)")
        }
    }
}
