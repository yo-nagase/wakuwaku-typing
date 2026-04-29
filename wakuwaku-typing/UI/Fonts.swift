import SwiftUI

enum AppFont {
    static let pixelName = "PressStart2P-Regular"
    static let kanaName = "DotGothic16-Regular"

    static func pixel(_ size: CGFloat) -> Font {
        .custom(pixelName, size: size, relativeTo: .body)
    }

    static func kana(_ size: CGFloat) -> Font {
        .custom(kanaName, size: size, relativeTo: .body)
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 8) -> some View {
        self.shadow(color: color, radius: radius / 2)
            .shadow(color: color.opacity(0.6), radius: radius)
    }
}
