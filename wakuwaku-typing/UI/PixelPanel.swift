import SwiftUI

struct PixelPanel<Content: View>: View {
    let theme: Theme
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(Color.black.opacity(0.4))
            .overlay(
                Rectangle()
                    .stroke(theme.primary, lineWidth: 2)
            )
            .background(
                Rectangle()
                    .fill(theme.primary.opacity(0.5))
                    .offset(x: 4, y: 4)
            )
            .overlay(
                Rectangle()
                    .stroke(theme.primary.opacity(0.2), lineWidth: 8)
                    .blur(radius: 4)
            )
    }
}

struct StatBlock: View {
    let theme: Theme
    let label: String
    let value: String
    let big: Bool

    init(theme: Theme, label: String, value: String, big: Bool = false) {
        self.theme = theme
        self.label = label
        self.value = value
        self.big = big
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppFont.pixel(8))
                .kerning(2)
                .foregroundStyle(theme.textDim)
            Text(value)
                .font(AppFont.pixel(big ? 24 : 16))
                .kerning(1)
                .foregroundStyle(theme.accent)
                .glow(theme.accent, radius: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(Color.black.opacity(0.3))
        .overlay(Rectangle().stroke(theme.textDim, lineWidth: 1))
    }
}
