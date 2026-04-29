import SwiftUI

struct ModesView: View {
    let theme: Theme
    let appState: AppState
    let onBack: () -> Void

    var body: some View {
        ScreenChrome(theme: theme, title: "📚 MODES", onBack: onBack) {
            VStack(spacing: 10) {
                ForEach(WordPacks.all) { pack in
                    packCard(pack)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private func packCard(_ pack: WordPack) -> some View {
        let active = appState.settings.packID == pack.id && !pack.isLocked
        return Button {
            guard !pack.isLocked else { return }
            appState.updateSettings { $0.packID = pack.id }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(pack.jp)
                        .font(AppFont.kana(16))
                        .kerning(2)
                        .foregroundStyle(active ? theme.accent : theme.text)
                    Text(pack.en)
                        .font(AppFont.pixel(9))
                        .kerning(2)
                        .foregroundStyle(theme.textDim)
                    Spacer()
                    if pack.isLocked {
                        Text("🔒 LOCKED")
                            .font(AppFont.pixel(8))
                            .foregroundStyle(theme.textDim)
                    } else {
                        Text("×\(pack.entries.count)")
                            .font(AppFont.pixel(9))
                            .foregroundStyle(theme.secondary)
                    }
                }
                Text(pack.sample)
                    .font(AppFont.kana(13))
                    .kerning(1)
                    .foregroundStyle(theme.textDim)
                if active {
                    Text("▶ SELECTED")
                        .font(AppFont.pixel(8))
                        .kerning(2)
                        .foregroundStyle(theme.accent)
                        .padding(.top, 4)
                } else if pack.isLocked {
                    Text("COMING SOON")
                        .font(AppFont.pixel(8))
                        .kerning(2)
                        .foregroundStyle(theme.textDim)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(active ? theme.primary.opacity(0.2) : Color.clear)
            .overlay(
                Rectangle()
                    .stroke(active ? theme.primary : theme.textDim, lineWidth: 2)
            )
            .opacity(pack.isLocked ? 0.5 : 1)
            .background(
                active ? Rectangle().fill(theme.primary.opacity(0.5)).offset(x: 4, y: 4) : nil
            )
        }
        .buttonStyle(.plain)
        .disabled(pack.isLocked)
    }
}
