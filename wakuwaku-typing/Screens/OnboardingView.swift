import SwiftUI

struct OnboardingView: View {
    let theme: Theme
    let onDone: (String) -> Void

    @State private var step = 0
    @State private var name = ""

    private struct Slide {
        let jp: String
        let en: String
        let body: String
    }

    private let slides: [Slide] = [
        Slide(jp: "ようこそ", en: "WELCOME", body: "わくわくタイピングへようこそ。\nことわざをタイプしよう。"),
        Slide(jp: "かなキーボード", en: "KANA KEYBOARD", body: "iOSの「かな」キーボードに切り替えてフリック入力でどうぞ。\n゛゜小キーで濁音・半濁音・小書きにできるよ。"),
        Slide(jp: "なまえ", en: "YOUR NAME", body: "ランキングに使う名前を入れてね。"),
    ]

    var body: some View {
        let s = slides[step]
        ZStack {
            theme.bg.ignoresSafeArea()
            CRTOverlay(theme: theme)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                PixelMascot(theme: theme, mood: step == 1 ? .happy : .idle, dotSize: 10)
                Text(s.jp)
                    .font(AppFont.kana(22))
                    .kerning(6)
                    .foregroundStyle(theme.secondary)
                Text(s.en)
                    .font(AppFont.pixel(22))
                    .kerning(3)
                    .foregroundStyle(theme.primary)
                    .glow(theme.primary, radius: 12)
                Text(s.body)
                    .font(AppFont.pixel(11))
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, 32)

                if step == 2 {
                    TextField("ENTER NAME", text: $name)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(AppFont.pixel(16))
                        .kerning(4)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.accent)
                        .padding(10)
                        .frame(maxWidth: 260)
                        .background(Color.black.opacity(0.5))
                        .overlay(Rectangle().stroke(theme.primary, lineWidth: 2))
                        .onChange(of: name) { _, newValue in
                            let trimmed = String(newValue.prefix(8)).uppercased()
                            if trimmed != newValue { name = trimmed }
                        }
                }

                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { i in
                        Rectangle()
                            .fill(i == step ? theme.primary : theme.textDim)
                            .frame(width: 8, height: 8)
                    }
                }

                HStack(spacing: 12) {
                    if step > 0 {
                        PixelButton(theme: theme, small: true, "← BACK") { step -= 1 }
                    }
                    PixelButton(theme: theme, primary: true, step < slides.count - 1 ? "NEXT ▶" : "START ▶") {
                        if step < slides.count - 1 {
                            step += 1
                        } else {
                            let trimmed = name.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty { onDone(trimmed) }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .foregroundStyle(theme.text)
    }
}
