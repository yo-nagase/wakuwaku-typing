import SwiftUI

struct ScreenChrome<Content: View>: View {
    let theme: Theme
    let title: String?
    let onBack: (() -> Void)?
    @ViewBuilder let content: () -> Content

    init(theme: Theme, title: String? = nil, onBack: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.theme = theme
        self.title = title
        self.onBack = onBack
        self.content = content
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()
            CRTOverlay(theme: theme)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    content()
                }
            }
        }
        .foregroundStyle(theme.text)
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    Text("←")
                        .font(AppFont.pixel(14))
                        .foregroundStyle(theme.text)
                        .frame(width: 36, height: 36)
                        .overlay(Rectangle().stroke(theme.primary, lineWidth: 2))
                        .background(
                            Rectangle()
                                .fill(theme.primary.opacity(0.6))
                                .offset(x: 2, y: 2)
                        )
                }
                .buttonStyle(.plain)
            }
            if let title {
                Text(title)
                    .font(AppFont.pixel(14))
                    .kerning(4)
                    .foregroundStyle(theme.primary)
                    .glow(theme.primary, radius: 8)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}
