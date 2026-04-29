// Romaji → Hiragana conversion table.
// Greedy match: try 3-char, then 2-char, then 1-char.
// Includes っ (sokuon) handling and ん edge cases.

const ROMAJI_MAP = {
  // 3-char
  'kya':'きゃ','kyu':'きゅ','kyo':'きょ',
  'sha':'しゃ','shu':'しゅ','sho':'しょ','shi':'し',
  'cha':'ちゃ','chu':'ちゅ','cho':'ちょ','chi':'ち',
  'tsu':'つ',
  'nya':'にゃ','nyu':'にゅ','nyo':'にょ',
  'hya':'ひゃ','hyu':'ひゅ','hyo':'ひょ',
  'mya':'みゃ','myu':'みゅ','myo':'みょ',
  'rya':'りゃ','ryu':'りゅ','ryo':'りょ',
  'gya':'ぎゃ','gyu':'ぎゅ','gyo':'ぎょ',
  'jya':'じゃ','jyu':'じゅ','jyo':'じょ',
  'bya':'びゃ','byu':'びゅ','byo':'びょ',
  'pya':'ぴゃ','pyu':'ぴゅ','pyo':'ぴょ',
  // 2-char
  'ka':'か','ki':'き','ku':'く','ke':'け','ko':'こ',
  'sa':'さ','si':'し','su':'す','se':'せ','so':'そ',
  'ta':'た','ti':'ち','tu':'つ','te':'て','to':'と',
  'na':'な','ni':'に','nu':'ぬ','ne':'ね','no':'の',
  'ha':'は','hi':'ひ','hu':'ふ','fu':'ふ','he':'へ','ho':'ほ',
  'ma':'ま','mi':'み','mu':'む','me':'め','mo':'も',
  'ya':'や','yu':'ゆ','yo':'よ',
  'ra':'ら','ri':'り','ru':'る','re':'れ','ro':'ろ',
  'wa':'わ','wo':'を','nn':'ん','xn':'ん',
  'ga':'が','gi':'ぎ','gu':'ぐ','ge':'げ','go':'ご',
  'za':'ざ','zi':'じ','ji':'じ','zu':'ず','ze':'ぜ','zo':'ぞ',
  'da':'だ','di':'ぢ','du':'づ','de':'で','do':'ど',
  'ba':'ば','bi':'び','bu':'ぶ','be':'べ','bo':'ぼ',
  'pa':'ぱ','pi':'ぴ','pu':'ぷ','pe':'ぺ','po':'ぽ',
  'ja':'じゃ','ju':'じゅ','jo':'じょ',
  // 1-char vowels
  'a':'あ','i':'い','u':'う','e':'え','o':'お',
  // small kana
  'xa':'ぁ','xi':'ぃ','xu':'ぅ','xe':'ぇ','xo':'ぉ',
  'xya':'ゃ','xyu':'ゅ','xyo':'ょ','xtu':'っ','xtsu':'っ',
  // long mark / punctuation
  '-':'ー',',':'、','.':'。','?':'?','!':'!',
};

// Reverse lookup: for a given hiragana, return one canonical romaji string the user can type.
const HIRA_TO_ROMAJI = (() => {
  // Prefer the most "natural" romaji per kana — pick first occurrence in this priority order.
  const priority = [
    'a','i','u','e','o',
    'ka','ki','ku','ke','ko','sa','shi','su','se','so',
    'ta','chi','tsu','te','to','na','ni','nu','ne','no',
    'ha','hi','fu','he','ho','ma','mi','mu','me','mo',
    'ya','yu','yo','ra','ri','ru','re','ro','wa','wo','nn',
    'ga','gi','gu','ge','go','za','ji','zu','ze','zo',
    'da','de','do','ba','bi','bu','be','bo','pa','pi','pu','pe','po',
    'kya','kyu','kyo','sha','shu','sho','cha','chu','cho',
    'nya','nyu','nyo','hya','hyu','hyo','mya','myu','myo','rya','ryu','ryo',
    'gya','gyu','gyo','ja','ju','jo','bya','byu','byo','pya','pyu','pyo',
    '-',',','.','?','!',
  ];
  const map = {};
  for (const r of priority) {
    const h = ROMAJI_MAP[r];
    if (h && !map[h]) map[h] = r;
  }
  return map;
})();

// Convert a hiragana string to a typeable romaji buffer.
// Handles っ (small tsu) → double the next consonant. ん → "nn".
function hiraToRomaji(hira) {
  let out = '';
  for (let i = 0; i < hira.length; i++) {
    const c = hira[i];
    // Handle digraphs (e.g., きゃ)
    const di = hira.substr(i, 2);
    if (HIRA_TO_ROMAJI[di]) {
      out += HIRA_TO_ROMAJI[di];
      i++;
      continue;
    }
    if (c === 'っ') {
      // double next consonant
      const nextDi = hira.substr(i + 1, 2);
      const nextCh = hira[i + 1];
      const nextR = HIRA_TO_ROMAJI[nextDi] || HIRA_TO_ROMAJI[nextCh] || '';
      if (nextR) out += nextR[0];
      continue;
    }
    if (HIRA_TO_ROMAJI[c]) {
      out += HIRA_TO_ROMAJI[c];
    } else {
      // pass-through (kanji not converted — but our packs are kana-only)
      out += c;
    }
  }
  return out;
}

window.ROMAJI_MAP = ROMAJI_MAP;
window.hiraToRomaji = hiraToRomaji;
