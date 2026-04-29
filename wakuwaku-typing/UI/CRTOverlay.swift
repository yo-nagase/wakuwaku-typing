import SwiftUI

struct CRTOverlay: View {
    let theme: Theme

    var body: some View {
        ZStack {
            gridLayer
            scanlines
            vignette
        }
        .allowsHitTesting(false)
    }

    private var scanlines: some View {
        Canvas { ctx, size in
            let lineHeight: CGFloat = 1
            let stride: CGFloat = 3
            var y: CGFloat = 0
            ctx.opacity = 0.4
            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: lineHeight)
                ctx.fill(Path(rect), with: .color(.black.opacity(0.18)))
                y += stride
            }
        }
    }

    private var vignette: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [.clear, theme.bg]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 600
                )
            )
            .blendMode(.normal)
            .opacity(0.95)
    }

    private var gridLayer: some View {
        Canvas { ctx, size in
            let cell: CGFloat = 24
            ctx.opacity = 1
            let gridColor = theme.grid
            var x: CGFloat = 0
            while x < size.width {
                ctx.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(gridColor),
                    lineWidth: 1
                )
                x += cell
            }
            var y: CGFloat = 0
            while y < size.height {
                ctx.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(gridColor),
                    lineWidth: 1
                )
                y += cell
            }
        }
    }
}
