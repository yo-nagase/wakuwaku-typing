// iOS Japanese Flick Keyboard — visual replica of the standard iOS かな keyboard.
// Tapping a key inputs the center kana. (In the real OS, swipe gestures select vowel
// variants — for the prototype we treat tap as the canonical input.)

const KANA_KEYS_IOS = [
  // row 1: あ か さ
  [{ c: 'あ', v: ['あ','い','う','え','お'] },
   { c: 'か', v: ['か','き','く','け','こ'] },
   { c: 'さ', v: ['さ','し','す','せ','そ'] }],
  // row 2: た な は
  [{ c: 'た', v: ['た','ち','つ','て','と'] },
   { c: 'な', v: ['な','に','ぬ','ね','の'] },
   { c: 'は', v: ['は','ひ','ふ','へ','ほ'] }],
  // row 3: ま や ら
  [{ c: 'ま', v: ['ま','み','む','め','も'] },
   { c: 'や', v: ['や','（','ゆ','）','よ'] },
   { c: 'ら', v: ['ら','り','る','れ','ろ'] }],
  // row 4: ゛゜小 / わ / 、。?!
  [{ c: '゛゜小', special: true },
   { c: 'わ', v: ['わ','を','ん','ー','〜'] },
   { c: '、。?!', special: true }],
];

const SIDE_LEFT = [
  { c: 'ABC', sub: 'abc' },
  { c: '☆123' },
  { c: '🌐' },
  { c: '☺︎' },
];
const SIDE_RIGHT = [
  { c: '⌫', action: '__del' },
  { c: '空白', sub: 'space' },
  { c: '改行', primary: true, action: '__enter' },
];

function IOSKanaKeyboard({ onKey, dark = true }) {
  const bg = dark ? '#2c2c2e' : '#d1d4d9';
  const keyBg = dark ? '#5c5c61' : '#fcfcfd';
  const sideBg = dark ? '#3a3a3c' : '#abafb6';
  const text = dark ? '#fff' : '#000';
  const subText = dark ? 'rgba(255,255,255,0.55)' : 'rgba(0,0,0,0.55)';
  const primary = '#0a84ff';

  const Key = ({ k, onTap, side }) => (
    <button
      onClick={() => onTap && onTap(k)}
      style={{
        flex: 1,
        height: '100%',
        background: k.primary ? primary : (side ? sideBg : keyBg),
        color: k.primary ? '#fff' : text,
        border: 'none',
        borderRadius: 5,
        boxShadow: dark
          ? '0 1px 0 rgba(0,0,0,0.5)'
          : '0 1px 0 rgba(0,0,0,0.28)',
        fontFamily: '-apple-system, "Hiragino Kaku Gothic ProN", system-ui',
        fontSize: k.c.length > 1 ? 13 : 22,
        fontWeight: 400,
        cursor: 'pointer',
        padding: 0,
        display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center',
        lineHeight: 1.1,
      }}
    >
      <span>{k.c}</span>
      {k.sub && <span style={{ fontSize: 9, color: subText, marginTop: 2 }}>{k.sub}</span>}
    </button>
  );

  return (
    <div style={{
      background: bg,
      padding: '6px 3px 0',
      borderTop: dark ? '0.5px solid rgba(255,255,255,0.1)' : '0.5px solid rgba(0,0,0,0.15)',
    }}>
      {/* candidate bar */}
      <div style={{
        height: 36, display: 'flex', alignItems: 'center',
        padding: '0 12px',
        fontFamily: '-apple-system, "Hiragino Kaku Gothic ProN", system-ui',
        fontSize: 14, color: subText,
      }}>
        <span style={{ opacity: 0.6 }}>予測変換</span>
      </div>

      {/* 5-column grid: side(L) | 3 kana cols | side(R) */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: '52px 1fr 1fr 1fr 52px',
        gap: 6,
        padding: '0 3px 6px',
      }}>
        {/* Left side column (4 keys) */}
        <div style={{ display: 'grid', gridTemplateRows: 'repeat(4, 42px)', gap: 6 }}>
          {SIDE_LEFT.map((k, i) => (
            <Key key={i} k={k} side onTap={() => {}} />
          ))}
        </div>

        {/* Center 3 columns × 4 rows */}
        {[0, 1, 2].map(col => (
          <div key={col} style={{ display: 'grid', gridTemplateRows: 'repeat(4, 42px)', gap: 6 }}>
            {KANA_KEYS_IOS.map((row, r) => {
              const k = row[col];
              return (
                <Key
                  key={r}
                  k={k}
                  onTap={() => !k.special && k.v && onKey(k.c)}
                />
              );
            })}
          </div>
        ))}

        {/* Right side column (3 keys: del, space, enter — enter takes 2 rows) */}
        <div style={{ display: 'grid', gridTemplateRows: '42px 42px 1fr', gap: 6 }}>
          <Key k={SIDE_RIGHT[0]} side onTap={k => onKey(k.action)} />
          <Key k={SIDE_RIGHT[1]} side onTap={() => {}} />
          <Key k={SIDE_RIGHT[2]} onTap={k => onKey(k.action)} />
        </div>
      </div>
    </div>
  );
}

// Backwards-compat shim — old name still imported elsewhere
function FlickKeyboard({ onKey }) {
  return <IOSKanaKeyboard onKey={onKey} dark />;
}

Object.assign(window, { IOSKanaKeyboard, FlickKeyboard });
