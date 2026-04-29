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

                if viewModel.stats.combo >= 3 {
                    Text("★ COMBO ×\(viewModel.stats.combo)")
                        .font(AppFont.pixel(14))
                        .kerning(2)
                        .foregroundStyle(theme.accent)
                        .glow(theme.accent, radius: 12)
                        .padding(.bottom, 4)
                }

                Spacer()

                wordDisplay
                    .padding(.horizontal, 24)

                progressBar
                    .padding(.top, 16)

                Text("WORDS·\(viewModel.stats.words)  ·  COMBO·\(viewModel.stats.combo)/\(viewModel.stats.maxCombo)")
                    .font(AppFont.pixel(9))
                    .kerning(2)
                    .foregroundStyle(theme.textDim)
                    .padding(.top, 12)

                Spacer()

                inputHint
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)

                TextField("", text: $input)
                    .focused($inputFocused)
                    .keyboardType(.default)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
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

            if viewModel.paused {
                pauseOverlay
            }
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
            StatBlock(theme: theme, label: "WPM", value: "\(viewModel.liveWPM)", big: true)
            StatBlock(theme: theme, label: "ACC", value: "\(viewModel.stats.accuracyPercent)%", big: true)
            iconButton(viewModel.paused ? "▶" : "‖") { viewModel.togglePause() }
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

            HStack(spacing: 0) {
                Text(viewModel.matcher.done)
                    .foregroundStyle(theme.correct.opacity(0.6))
                Text(String(viewModel.matcher.target.dropFirst(viewModel.matcher.done.count)))
                    .foregroundStyle(theme.text)
            }
            .font(AppFont.kana(56))
            .kerning(4)
            .glow(theme.primary, radius: 24)
            .frame(minHeight: 80)
        }
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
            }
            .overlay(Rectangle().stroke(theme.textDim, lineWidth: 1))
        }
        .frame(height: 8)
        .padding(.horizontal, 32)
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("‖ PAUSED")
                    .font(AppFont.pixel(24))
                    .kerning(4)
                    .foregroundStyle(theme.accent)
                PixelButton(theme: theme, primary: true, "▶ RESUME") {
                    viewModel.togglePause()
                }
                PixelButton(theme: theme, small: true, "✕ QUIT") {
                    viewModel.quit()
                    onExit()
                }
            }
        }
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
