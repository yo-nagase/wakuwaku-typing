import SwiftUI

struct SpriteSheetView: View {
    let imageName: String
    let frameSize: CGSize
    let frameCount: Int
    let frameDuration: TimeInterval
    let scale: CGFloat

    init(
        imageName: String,
        frameSize: CGSize,
        frameCount: Int,
        frameDuration: TimeInterval = 0.2,
        scale: CGFloat = 1
    ) {
        self.imageName = imageName
        self.frameSize = frameSize
        self.frameCount = frameCount
        self.frameDuration = frameDuration
        self.scale = scale
    }

    var body: some View {
        let displayWidth = frameSize.width * scale
        let displayHeight = frameSize.height * scale
        let sheetWidth = displayWidth * CGFloat(frameCount)
        TimelineView(.periodic(from: .now, by: frameDuration)) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let frame = Int(elapsed / frameDuration) % frameCount
            Image(imageName)
                .resizable()
                .interpolation(.none)
                .frame(width: sheetWidth, height: displayHeight)
                .offset(x: -CGFloat(frame) * displayWidth)
                .frame(width: displayWidth, height: displayHeight, alignment: .leading)
                .clipped()
        }
        .frame(width: displayWidth, height: displayHeight)
    }
}
