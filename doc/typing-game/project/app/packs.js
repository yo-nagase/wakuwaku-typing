// Word/sentence packs for Kana Typer.
// Each pack: id, jp, en, sample (display blurb), entries (hiragana strings).

const PACKS = [
  {
    id: 'basic',
    jp: '基本',
    en: 'BASIC',
    sample: 'ねこ・いぬ・さくら・あめ',
    desc: 'Common everyday hiragana words.',
    entries: [
      'ねこ','いぬ','さくら','あめ','つき','ほし','かわ','やま','うみ','そら',
      'はな','とり','むし','さかな','くるま','でんしゃ','ひこうき','ふね',
      'たべもの','のみもの','ごはん','みず','おちゃ','りんご','ばなな','いちご',
      'がっこう','せんせい','ともだち','かぞく','おとうさん','おかあさん',
      'あさ','ひる','よる','きょう','あした','きのう','じかん','ぷれぜんと',
    ],
  },
  {
    id: 'n5',
    jp: 'N5',
    en: 'JLPT N5',
    sample: 'がくせい・しごと・でんわ',
    desc: 'Common JLPT N5 vocabulary in hiragana.',
    entries: [
      'がくせい','しごと','でんわ','びょういん','ぎんこう','としょかん',
      'ゆうびんきょく','えき','こうえん','れすとらん','ほてる','くうこう',
      'なまえ','じゅうしょ','こくせき','たんじょうび','じかん','ようび',
      'たべる','のむ','みる','きく','よむ','かく','はなす','あるく','はしる',
      'ねる','おきる','かう','つくる','あう','まつ','かえる','つかう','すわる',
      'おおきい','ちいさい','たかい','やすい','はやい','おそい','あたらしい','ふるい',
    ],
  },
  {
    id: 'phrases',
    jp: '会話',
    en: 'PHRASES',
    sample: 'こんにちは・ありがとう',
    desc: 'Short conversational phrases.',
    entries: [
      'こんにちは','ありがとう','すみません','おはよう','こんばんは','おやすみ',
      'はじめまして','よろしく','さようなら','またね','いってきます','ただいま',
      'いただきます','ごちそうさま','どういたしまして','ごめんなさい',
      'おねがいします','だいじょうぶ','がんばって','おめでとう',
      'おなかすいた','のどがかわいた','うれしい','たのしい','すごい',
    ],
  },
  {
    id: 'katakana',
    jp: 'カタカナ',
    en: 'KATAKANA',
    sample: 'コーヒー・テレビ・ピアノ',
    desc: 'Loanwords in katakana (still typed via romaji).',
    entries: [
      // We store these as hiragana so the romaji engine still works; display layer
      // converts to katakana for the prompt.
      'こーひー','てれび','ぴあの','ぱそこん','すまほ','てぃーしゃつ',
      'はんばーがー','あいすくりーむ','ちょこれーと','けーき','ぱん',
      'ばす','たくしー','ほてる','れすとらん','すーぱー','こんびに',
      'にゅーよーく','ろんどん','ぱり','とうきょう',
    ],
    katakana: true,
  },
];

// Hiragana → Katakana mapping (for display when pack.katakana = true)
const H2K_OFFSET = 0x60;
function hiraToKata(s) {
  return s.replace(/[\u3041-\u3096]/g, c => String.fromCharCode(c.charCodeAt(0) + H2K_OFFSET));
}

window.PACKS = PACKS;
window.hiraToKata = hiraToKata;
