import SwiftUI

struct HomeView: View {
    let theme: Theme
    let appState: AppState
    let onStart: () -> Void
    let onScreen: (Screen) -> Void

    @State private var blink = true
    @State private var prewarmText = ""
    @FocusState private var prewarmFocused: Bool

    /// アプリプロセス全体で1回だけ実行する。HomeView は results 画面から戻るたび
    /// onAppear が再発火するため、@State だと再プリウォームしてしまう。
    nonisolated(unsafe) private static var didPrewarmKeyboard = false

    private var totals: (total: Int, games: Int) {
        // 累計スコア / 通算プレイ数は永続フィールドを使う（履歴は 50 件で打ち切られるため）。
        (appState.cumulativeScore, appState.totalGames)
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            CRTOverlay(theme: theme)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                titleBlock
                    .padding(.top, 32)

                statTilesRow
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                Spacer(minLength: 24)

                PixelMascot(theme: theme, dotSize: 9)

                Spacer(minLength: 16)

                pressStartBlock

                Spacer(minLength: 12)

                bottomNav
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }

            // GameView と同じ TextField 設定で初回 first-responder にし、
            // システムのかな IME をプロセスにロードさせるためだけの隠しフィールド。
            // 入場直後にフォーカス→即座に外すことで、キーボードが画面に出る前に
            // IME 初期化のコストを払い終える。
            TextField("", text: $prewarmText)
                .focused($prewarmFocused)
                .keyboardType(.default)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.oneTimeCode)
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .foregroundStyle(theme.text)
        .onAppear {
            startBlink()
            prewarmKeyboardIfNeeded()
        }
    }

    private func prewarmKeyboardIfNeeded() {
        guard !Self.didPrewarmKeyboard else { return }
        Self.didPrewarmKeyboard = true
        // 画面遷移アニメ完了直後にフォーカス → IME ロード開始 → 即外して
        // キーボードのスライドアップを描画前にキャンセル。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            prewarmFocused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                prewarmFocused = false
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("わくわく")
                .font(AppFont.kana(14))
                .kerning(8)
                .foregroundStyle(theme.secondary)
            Text("WAKUWAKU")
                .font(AppFont.pixel(40))
                .kerning(2)
                .foregroundStyle(theme.primary)
                .glow(theme.primary, radius: 16)
            Text("TYPING")
                .font(AppFont.pixel(40))
                .kerning(2)
                .foregroundStyle(theme.accent)
                .glow(theme.accent, radius: 16)
        }
    }

    private var statTilesRow: some View {
        let t = totals
        return tile(label: "★ TOTAL", value: t.total, sub: "GAMES·\(t.games)", color: theme.accent)
    }

    private func tile(label: String, value: Int, sub: String, color: Color) -> some View {
        Button { onScreen(.leaderboard) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(AppFont.pixel(8))
                    .kerning(2)
                    .foregroundStyle(theme.textDim)
                Text(String(format: "%05d", value))
                    .font(AppFont.pixel(26))
                    .foregroundStyle(color)
                    .glow(color, radius: 12)
                Text(sub)
                    .font(AppFont.pixel(7))
                    .kerning(2)
                    .foregroundStyle(theme.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Rectangle().fill(Color.black.opacity(0.5)))
            .overlay(Rectangle().stroke(color, lineWidth: 3))
            .background(
                Rectangle()
                    .fill(color.opacity(0.4))
                    .offset(x: 4, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    private var pressStartBlock: some View {
        Button(action: onStart) {
            Text("▶ PRESS START")
                .font(AppFont.pixel(14))
                .kerning(2)
                .foregroundStyle(theme.text)
                .glow(theme.primary, radius: 8)
                .opacity(blink ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private var bottomNav: some View {
        HStack(spacing: 6) {
            navButton(icon: "🏆", label: "LEAD") { onScreen(.leaderboard) }
            navButton(icon: "📚", label: "MODE") { onScreen(.modes) }
            navButton(icon: "⚙", label: "OPTS") { onScreen(.settings) }
        }
    }

    private func navButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(icon).font(.system(size: 16))
                Text(label)
                    .font(AppFont.pixel(9))
                    .kerning(1)
                    .foregroundStyle(theme.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .overlay(Rectangle().stroke(theme.primary, lineWidth: 2))
            .background(
                Rectangle()
                    .fill(theme.primary.opacity(0.6))
                    .offset(x: 2, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func startBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            Task { @MainActor in blink.toggle() }
        }
    }
}
