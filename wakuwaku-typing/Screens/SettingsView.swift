import SwiftUI

struct SettingsView: View {
    let theme: Theme
    let appState: AppState
    let onBack: () -> Void

    @State private var showResetConfirm = false

    var body: some View {
        ScreenChrome(theme: theme, title: "⚙ SETTINGS", onBack: onBack) {
            VStack(alignment: .leading, spacing: 18) {
                row(label: "PLAYER NAME") {
                    TextField("YOUR NAME", text: Binding(
                        get: { appState.settings.name },
                        set: { newVal in
                            let trimmed = String(newVal.prefix(8)).uppercased()
                            appState.updateSettings { $0.name = trimmed }
                        }
                    ))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(AppFont.pixel(14))
                    .kerning(3)
                    .foregroundStyle(theme.accent)
                    .padding(10)
                    .background(Color.black.opacity(0.5))
                    .overlay(Rectangle().stroke(theme.primary, lineWidth: 2))
                }

                row(label: "THEME") {
                    seg(
                        value: appState.settings.theme,
                        options: [(.neon, "NEON"), (.matrix, "MATRIX"), (.sunset, "SUNSET")],
                        onChange: { v in appState.updateSettings { $0.theme = v } }
                    )
                }

                row(label: "ROUND DURATION") {
                    seg(
                        value: appState.settings.duration,
                        options: [(.fifteen, "15s"), (.thirty, "30s"), (.sixty, "60s")],
                        onChange: { v in appState.updateSettings { $0.duration = v } }
                    )
                }

                row(label: "DIFFICULTY") {
                    seg(
                        value: appState.settings.difficulty,
                        options: [(.easy, "EASY"), (.normal, "NORMAL"), (.hard, "HARD")],
                        onChange: { v in appState.updateSettings { $0.difficulty = v } }
                    )
                }

                row(label: "SOUND") {
                    seg(
                        value: appState.settings.soundOn,
                        options: [(true, "ON"), (false, "OFF")],
                        onChange: { v in appState.updateSettings { $0.soundOn = v } }
                    )
                }

                row(label: "HAPTICS") {
                    seg(
                        value: appState.settings.hapticsOn,
                        options: [(true, "ON"), (false, "OFF")],
                        onChange: { v in appState.updateSettings { $0.hapticsOn = v } }
                    )
                }

                statsBlock

                Button { showResetConfirm = true } label: {
                    Text("↺ RESET ALL DATA")
                        .font(AppFont.pixel(10))
                        .kerning(2)
                        .foregroundStyle(theme.wrong)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .overlay(Rectangle().stroke(theme.wrong, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .alert("Reset all data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { appState.resetAll() }
        } message: {
            Text("This will erase your name, scores, and history.")
        }
    }

    @ViewBuilder
    private func row<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFont.pixel(9))
                .kerning(2)
                .foregroundStyle(theme.textDim)
            content()
        }
    }

    private func seg<V: Equatable>(value: V, options: [(V, String)], onChange: @escaping (V) -> Void) -> some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { i in
                let opt = options[i]
                Button { onChange(opt.0) } label: {
                    Text(opt.1)
                        .font(AppFont.pixel(10))
                        .kerning(1)
                        .foregroundStyle(value == opt.0 ? Color.black : theme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(value == opt.0 ? theme.primary : Color.clear)
                        .overlay(Rectangle().stroke(theme.primary, lineWidth: 2))
                        .glow(value == opt.0 ? theme.primary : .clear, radius: 8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var statsBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PROGRESS IS SAVED ON THIS DEVICE.")
                .font(AppFont.pixel(9))
                .kerning(1)
            Text("BEST SCORE: \(appState.history.map(\.score).max() ?? 0) PTS")
                .font(AppFont.pixel(9))
                .foregroundStyle(theme.textDim)
            Text("BEST WPM: \(appState.history.map(\.wpm).max() ?? 0)")
                .font(AppFont.pixel(9))
                .foregroundStyle(theme.textDim)
            Text("GAMES PLAYED: \(appState.history.count)")
                .font(AppFont.pixel(9))
                .foregroundStyle(theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .overlay(Rectangle().stroke(style: .init(lineWidth: 1, dash: [4, 3])).foregroundStyle(theme.textDim))
        .padding(.top, 12)
    }
}
