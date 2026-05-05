import SwiftUI

struct GameView: View {
    let theme: Theme
    let onEnd: (GameResult) -> Void
    let onExit: () -> Void

    @State private var viewModel: GameViewModel
    @State private var shakeOffset: CGFloat = 0
    @State private var input = ""
    @State private var prevInput = ""
    @FocusState private var inputFocused: Bool

    init(theme: Theme, settings: AppSettings, onEnd: @escaping (GameResult) -> Void, onExit: @escaping () -> Void) {
        self.theme = theme
        self.onEnd = onEnd
        self.onExit = onExit
        let pack = WordPacks.pack(id: settings.packID)
        self._viewModel = State(initialValue: GameViewModel(pack: pack, duration: settings.duration.rawValue, difficulty: settings.difficulty))
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            CRTOverlay(theme: theme).ignoresSafeArea()

            VStack(spacing: 0) {
                hud
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                progressBar
                    .padding(.bottom, 8)

                Spacer()

                wordDisplay
                    .padding(.horizontal, 24)

                MultiplierBadge(theme: theme, combo: viewModel.stats.combo)
                    .padding(.top, 16)

                Spacer()

                inputHint
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)

                TextField("", text: $input)
                    .focused($inputFocused)
                    .keyboardType(.default)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    // .oneTimeCode で IME に「ワンタイムコード入力欄」と伝えると、
                    // 日本語かな入力の変換候補バーが抑制される。
                    .textContentType(.oneTimeCode)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onChange(of: input) { old, new in
                        feed(old: old, new: new)
                    }
            }
            .offset(x: shakeOffset)
            .contentShape(Rectangle())
            .onTapGesture { inputFocused = true }

            ParticleLayer(particles: viewModel.particles, theme: theme)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .foregroundStyle(theme.text)
        .onChange(of: viewModel.shakeCount) { _, _ in performShake() }
        .onChange(of: viewModel.stats.words) { _, _ in
            input = ""
            prevInput = ""
        }
        .onChange(of: viewModel.finished) { _, finished in
            if finished {
                onEnd(viewModel.currentResult())
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { inputFocused = true }
        }
        .onDisappear { viewModel.quit() }
    }

    private var inputHint: some View {
        VStack(spacing: 4) {
            Text("iOS かなキーボードで入力")
                .font(AppFont.pixel(8))
                .kerning(2)
                .foregroundStyle(theme.textDim)
            if let next = viewModel.expectedKey {
                Text("NEXT: ")
                    .font(AppFont.pixel(9))
                    .foregroundStyle(theme.textDim)
                +
                Text(String(next))
                    .font(AppFont.kana(20))
                    .foregroundStyle(theme.accent)
            }
        }
    }

    /// Drives `viewModel.handle` from `TextField` text changes.
    /// Handles three cases: append (typed kana), replace (modifier ゛゜小), and delete (backspace).
    private func feed(old: String, new: String) {
        defer { prevInput = new }
        if new.count > old.count {
            // Typed one or more new chars at end
            let added = new.dropFirst(old.count)
            for ch in added {
                viewModel.handle(ch)
            }
        } else if new.count == old.count && new != old {
            // Modifier replaced the last uncommitted kana (e.g., か → が)
            if let last = new.last {
                viewModel.handle(last)
            }
        }
        // backspace (count decreased): no-op for game logic
    }

    private var hud: some View {
        HStack(spacing: 8) {
            iconButton("✕") { onExit() }
            StatBlock(theme: theme, label: "TIME", value: "\(viewModel.timeRemaining)s", big: true)
            StatBlock(theme: theme, label: "SCORE", value: "\(viewModel.liveScore)", big: true)
            StatBlock(theme: theme, label: "WPM", value: "\(viewModel.liveWPM)", big: true)
            StatBlock(theme: theme, label: "ACC", value: "\(viewModel.stats.accuracyPercent)%", big: true)
        }
    }

    private func iconButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(AppFont.pixel(12))
                .foregroundStyle(theme.text)
                .frame(width: 36, height: 36)
                .overlay(Rectangle().stroke(theme.primary, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private var wordDisplay: some View {
        VStack(spacing: 16) {
            Text(viewModel.started ? "▼ TYPE THIS ▼" : "▶ TAP TO START")
                .font(AppFont.pixel(9))
                .kerning(4)
                .foregroundStyle(theme.textDim)

            Text(attributedTarget)
                .font(AppFont.kana(38))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .glow(theme.primary, radius: 24)
                .frame(minHeight: 60)
        }
    }

    private var attributedTarget: AttributedString {
        let done = viewModel.matcher.done
        let target = viewModel.matcher.target
        var donePart = AttributedString(done)
        donePart.foregroundColor = theme.correct.opacity(0.6)
        var remainPart = AttributedString(String(target.dropFirst(done.count)))
        remainPart.foregroundColor = theme.text
        var result = donePart
        result.append(remainPart)
        return result
    }

    private var progressBar: some View {
        let frac = Double(viewModel.timeRemaining) / Double(viewModel.duration)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.black.opacity(0.5))
                Rectangle()
                    .fill(viewModel.timeRemaining < 10 ? theme.wrong : theme.primary)
                    .frame(width: geo.size.width * max(0, frac))
                    .glow(viewModel.timeRemaining < 10 ? theme.wrong : theme.primary, radius: 8)
                    .animation(.linear(duration: 1), value: viewModel.timeRemaining)
            }
            .overlay(Rectangle().stroke(theme.textDim, lineWidth: 1))
        }
        .frame(height: 8)
        .padding(.horizontal, 32)
    }

    private func performShake() {
        withAnimation(.easeInOut(duration: 0.05)) { shakeOffset = -8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.05)) { shakeOffset = 8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.easeInOut(duration: 0.05)) { shakeOffset = -4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.05)) { shakeOffset = 0 }
        }
    }
}

struct ParticleLayer: View {
    let particles: [GameViewModel.Particle]
    let theme: Theme

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let now = context.date
                for p in particles {
                    let elapsed = now.timeIntervalSince(p.createdAt)
                    if elapsed > p.lifetime { continue }
                    let t = elapsed / p.lifetime
                    let alpha = 1.0 - t
                    let x = size.width * p.originX + CGFloat(p.velocityX * 30 * t)
                    let y = size.height * p.originY + CGFloat(p.velocityY * 60 * t + 80 * t * t)
                    let scale = 1.0 - 0.4 * t
                    let color: Color = {
                        switch p.color {
                        case .primary: return theme.primary
                        case .accent: return theme.accent
                        case .secondary: return theme.secondary
                        }
                    }()
                    let text = Text(String(p.char))
                        .font(AppFont.pixel(18 * scale))
                        .foregroundStyle(color.opacity(alpha))
                    ctx.draw(text, at: CGPoint(x: x, y: y), anchor: .center)
                }
            }
        }
    }
}

private struct MultiplierBadge: View {
    let theme: Theme
    let combo: Int

    @State private var pulseScale: CGFloat = 1.0

    private var multiplier: Int { ScoreCalculator.multiplier(forCombo: combo) }
    private var tierStart: Int { ScoreCalculator.currentTierStart(forCombo: combo) }
    private var nextThreshold: Int? { ScoreCalculator.nextThreshold(forCombo: combo) }

    /// 階層が上がるごとに緑 → 赤へ移行する。
    private var tierColor: Color {
        switch multiplier {
        case 1:  return Color(hex: "39ff14") // green
        case 2:  return Color(hex: "aaff00") // yellow-green
        case 3:  return Color(hex: "ffd60a") // yellow
        case 4:  return Color(hex: "ff9500") // orange
        case 5:  return Color(hex: "ff4d00") // deep orange
        default: return Color(hex: "ff1a1a") // red (6x+)
        }
    }

    /// バーの総セグメント数 = 現階層の幅（次閾値まで何文字あるか）。
    /// 最高層は次がないので 5 個固定で全点灯表示。
    private var totalSegments: Int {
        if let next = nextThreshold {
            return max(1, next - tierStart)
        }
        return 5
    }

    /// 現在何個塗られているか（左から順に塗られていく）。最高層では全点灯。
    private var filledSegments: Int {
        guard nextThreshold != nil else { return totalSegments }
        return max(0, min(totalSegments, combo - tierStart))
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text("MULT")
                    .font(AppFont.pixel(10))
                    .kerning(2)
                    .foregroundStyle(theme.textDim)
                Text("x\(multiplier)")
                    .font(AppFont.pixel(20))
                    .foregroundStyle(tierColor)
                    .glow(tierColor, radius: 6)
                    .scaleEffect(pulseScale)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay(Rectangle().stroke(tierColor, lineWidth: 2))
            .onChange(of: multiplier) { old, new in
                guard new > old else { return }
                pulseScale = 1.0
                withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) {
                    pulseScale = 1.7
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                        pulseScale = 1.0
                    }
                }
            }

            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    ForEach(0..<totalSegments, id: \.self) { i in
                        Rectangle()
                            .fill(i < filledSegments ? tierColor : theme.textDim.opacity(0.3))
                            .frame(width: 10, height: 6)
                    }
                }
                .glow(tierColor, radius: 4)

                if let next = nextThreshold {
                    Text("NEXT \(max(next - combo, 0))")
                        .font(AppFont.pixel(8))
                        .kerning(2)
                        .foregroundStyle(theme.textDim)
                } else {
                    Text("MAX")
                        .font(AppFont.pixel(8))
                        .kerning(2)
                        .foregroundStyle(tierColor)
                }
            }
        }
    }
}
