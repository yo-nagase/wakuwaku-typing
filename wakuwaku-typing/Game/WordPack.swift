import Foundation

struct WordPack: Identifiable, Equatable {
    let id: String
    let jp: String
    let en: String
    let sample: String
    let desc: String
    let entries: [String]
    let displayKatakana: Bool
    let isLocked: Bool

    init(id: String, jp: String, en: String, sample: String, desc: String, entries: [String], displayKatakana: Bool = false, isLocked: Bool = false) {
        self.id = id
        self.jp = jp
        self.en = en
        self.sample = sample
        self.desc = desc
        self.entries = entries
        self.displayKatakana = displayKatakana
        self.isLocked = isLocked
    }
}

enum WordPacks {
    static let kotowaza = WordPack(
        id: "kotowaza",
        jp: "ことわざ",
        en: "PROVERBS",
        sample: "ねこにこばん・とらのこ",
        desc: "Classic Japanese proverbs in hiragana.",
        entries: ProverbsData.entries
    )

    static let comingSoonVocab = WordPack(
        id: "vocab",
        jp: "たんご",
        en: "VOCAB",
        sample: "─",
        desc: "Coming soon.",
        entries: [],
        isLocked: true
    )

    static let comingSoonShortText = WordPack(
        id: "shorttext",
        jp: "たんぶん",
        en: "SHORT TEXT",
        sample: "─",
        desc: "Coming soon.",
        entries: [],
        isLocked: true
    )

    static let comingSoonKatakana = WordPack(
        id: "katakana",
        jp: "カタカナ",
        en: "KATAKANA",
        sample: "─",
        desc: "Coming soon.",
        entries: [],
        displayKatakana: true,
        isLocked: true
    )

    /// Order matters: active modes first, locked modes after.
    static let all: [WordPack] = [
        kotowaza,
        comingSoonVocab,
        comingSoonShortText,
        comingSoonKatakana,
    ]

    static let active: [WordPack] = all.filter { !$0.isLocked }

    static func pack(id: String) -> WordPack {
        all.first { $0.id == id } ?? kotowaza
    }
}
