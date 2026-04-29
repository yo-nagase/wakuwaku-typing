import SwiftUI

struct PixelButton<Label: View>: View {
    let theme: Theme
    let primary: Bool
    let small: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var pressed = false

    init(theme: Theme, primary: Bool = false, small: Bool = false, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.theme = theme
        self.primary = primary
        self.small = small
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .font(AppFont.pixel(small ? 10 : 12))
                .kerning(1)
                .padding(.horizontal, small ? 14 : 24)
                .padding(.vertical, small ? 8 : 14)
                .foregroundStyle(primary ? Color.black : theme.text)
                .background(primary ? theme.primary : Color.clear)
                .overlay(
                    Rectangle()
                        .stroke(theme.primary, lineWidth: 3)
                )
                .offset(x: pressed ? 2 : 0, y: pressed ? 2 : 0)
                .background(
                    Rectangle()
                        .fill(theme.primary.opacity(pressed ? 0 : 0.5))
                        .offset(x: 4, y: 4)
                )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

extension PixelButton where Label == Text {
    init(theme: Theme, primary: Bool = false, small: Bool = false, _ title: String, action: @escaping () -> Void) {
        self.init(theme: theme, primary: primary, small: small, action: action) {
            Text(title)
        }
    }
}
