import SwiftUI

enum MascotMood {
    case idle, happy
}

struct PixelMascot: View {
    let theme: Theme
    let mood: MascotMood
    let dotSize: CGFloat

    init(theme: Theme, mood: MascotMood = .idle, dotSize: CGFloat = 8) {
        self.theme = theme
        self.mood = mood
        self.dotSize = dotSize
    }

    private static let idleGrid: [String] = [
        "...XXXX...",
        "..XXXXXX..",
        "..XOOOXX..",
        "..XOOOXX..",
        "..XXXXXX..",
        "..XXMMXX..",
        ".XXXXXXXX.",
        "X.XXXXXX.X",
        "X.X....X.X",
        "...XXXX...",
    ]

    private static let happyGrid: [String] = [
        "...XXXX...",
        "..XXXXXX..",
        "..X.X.XX..",
        "..XXXXXX..",
        "..XMMMMX..",
        ".XXMMMMXX.",
        "X.XXXXXX.X",
        "...XXXX...",
        "...X..X...",
        "...X..X...",
    ]

    private var grid: [String] {
        mood == .idle ? Self.idleGrid : Self.happyGrid
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<grid.count, id: \.self) { r in
                let row = Array(grid[r])
                HStack(spacing: 0) {
                    ForEach(0..<row.count, id: \.self) { c in
                        cell(for: row[c])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for ch: Character) -> some View {
        switch ch {
        case "X":
            Rectangle()
                .fill(theme.primary)
                .frame(width: dotSize, height: dotSize)
                .glow(theme.primary, radius: 4)
        case "O":
            Rectangle()
                .fill(Color.black)
                .frame(width: dotSize, height: dotSize)
        case "M":
            Rectangle()
                .fill(theme.accent)
                .frame(width: dotSize, height: dotSize)
        default:
            Color.clear
                .frame(width: dotSize, height: dotSize)
        }
    }
}
