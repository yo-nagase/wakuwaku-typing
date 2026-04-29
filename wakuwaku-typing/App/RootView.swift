import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 8) {
                Text("わくわく")
                    .font(.system(size: 14))
                    .foregroundStyle(.purple)
                    .tracking(8)
                Text("WAKUWAKU")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.pink)
                    .tracking(2)
                Text("TYPING")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.yellow)
                    .tracking(2)
            }
        }
    }
}

#Preview {
    RootView()
}
