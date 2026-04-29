// All screen components for the typing game
// Themes: arcade (purple/pink neon), matrix (green CRT), sunset (warm orange)

const THEMES = {
  arcade: {
    name: 'NEON',
    bg: 'linear-gradient(180deg, #1a0d2e 0%, #0a0517 100%)',
    bgPattern: 'radial-gradient(circle at 50% 0%, rgba(255,45,149,0.15) 0%, transparent 50%)',
    primary: '#ff2d95',
    secondary: '#00f0ff',
    accent: '#ffd700',
    text: '#ffffff',
    textDim: 'rgba(255,255,255,0.6)',
    panel: 'rgba(45, 27, 78, 0.6)',
    panelBorder: '#ff2d95',
    correct: '#00ff88',
    wrong: '#ff0044',
  },
  matrix: {
    name: 'MATRIX',
    bg: 'linear-gradient(180deg, #001a0d 0%, #000a05 100%)',
    bgPattern: 'radial-gradient(circle at 50% 0%, rgba(0,255,102,0.1) 0%, transparent 50%)',
    primary: '#00ff66',
    secondary: '#88ff00',
    accent: '#ffff00',
    text: '#00ff66',
    textDim: 'rgba(0,255,102,0.5)',
    panel: 'rgba(0, 45, 26, 0.6)',
    panelBorder: '#00ff66',
    correct: '#00ff66',
    wrong: '#ff0044',
  },
  sunset: {
    name: 'SUNSET',
    bg: 'linear-gradient(180deg, #2d1b00 0%, #1a0a00 100%)',
    bgPattern: 'radial-gradient(circle at 50% 0%, rgba(255,170,0,0.15) 0%, transparent 50%)',
    primary: '#ffaa00',
    secondary: '#ff5500',
    accent: '#ffe9b8',
    text: '#ffe9b8',
    textDim: 'rgba(255,233,184,0.5)',
    panel: 'rgba(78, 45, 27, 0.6)',
    panelBorder: '#ffaa00',
    correct: '#88ff00',
    wrong: '#ff3300',
  },
};

const PIXEL_FONT = '"Press Start 2P", "Courier New", monospace';
const KANA_FONT = '"DotGothic16", "M PLUS 1 Code", "Hiragino Kaku Gothic Std", monospace';

// ────── Pixel UI bits ──────
function PixelButton({ children, onClick, theme, primary, small }) {
  const [hover, setHover] = React.useState(false);
  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        background: primary ? theme.primary : 'transparent',
        color: primary ? '#000' : theme.text,
        border: `3px solid ${theme.primary}`,
        padding: small ? '8px 14px' : '14px 24px',
        fontFamily: PIXEL_FONT,
        fontSize: small ? 10 : 12,
        letterSpacing: 1,
        cursor: 'pointer',
        position: 'relative',
        boxShadow: hover
          ? `0 0 0 2px ${theme.primary}, 0 0 24px ${theme.primary}, 4px 4px 0 ${theme.secondary}`
          : `4px 4px 0 ${theme.primary}`,
        transform: hover ? 'translate(-2px, -2px)' : 'none',
        transition: 'all 0.1s',
        textTransform: 'uppercase',
        fontWeight: 700,
      }}
    >
      {children}
    </button>
  );
}

function PixelPanel({ children, theme, style = {} }) {
  return (
    <div style={{
      background: theme.panel,
      border: `2px solid ${theme.panelBorder}`,
      boxShadow: `0 0 20px ${theme.primary}40, inset 0 0 20px rgba(0,0,0,0.4)`,
      padding: 16,
      position: 'relative',
      ...style,
    }}>
      {/* corner brackets */}
      {[
        { top: -4, left: -4, borderTop: `3px solid ${theme.accent}`, borderLeft: `3px solid ${theme.accent}` },
        { top: -4, right: -4, borderTop: `3px solid ${theme.accent}`, borderRight: `3px solid ${theme.accent}` },
        { bottom: -4, left: -4, borderBottom: `3px solid ${theme.accent}`, borderLeft: `3px solid ${theme.accent}` },
        { bottom: -4, right: -4, borderBottom: `3px solid ${theme.accent}`, borderRight: `3px solid ${theme.accent}` },
      ].map((s, i) => (
        <div key={i} style={{ position: 'absolute', width: 10, height: 10, ...s }} />
      ))}
      {children}
    </div>
  );
}

function ScanlineOverlay() {
  return (
    <div style={{
      position: 'absolute', inset: 0, pointerEvents: 'none', zIndex: 100,
      backgroundImage: 'repeating-linear-gradient(0deg, rgba(0,0,0,0.15) 0px, rgba(0,0,0,0.15) 1px, transparent 1px, transparent 3px)',
      mixBlendMode: 'multiply',
    }} />
  );
}

function ScreenWrap({ theme, children, scanlines = true }) {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: theme.bg,
      position: 'relative',
      fontFamily: PIXEL_FONT,
      color: theme.text,
      overflow: 'hidden',
    }}>
      <div style={{ position: 'absolute', inset: 0, background: theme.bgPattern, pointerEvents: 'none' }} />
      <div style={{ position: 'relative', zIndex: 1, height: '100%' }}>{children}</div>
      {scanlines && <ScanlineOverlay />}
    </div>
  );
}

// ────── HOME / START ──────
function HomeScreen({ theme, onStart, onScreen, highScore = 142 }) {
  const [blink, setBlink] = React.useState(true);
  React.useEffect(() => {
    const i = setInterval(() => setBlink(b => !b), 600);
    return () => clearInterval(i);
  }, []);

  // Build a small "your rank" preview from the shared mock board, including a YOU entry.
  const previewBoard = React.useMemo(() => {
    if (typeof MOCK_BOARD === 'undefined') return null;
    const me = { name: 'YOU', you: true, wpm: 84, acc: 94, combo: 19, words: 42, time: 60, date: '2026-04-29 12:30', course: '基本 / WORDS' };
    const all = [...MOCK_BOARD, me].map(e => ({ ...e, scoreCalc: computeScore(e) }));
    all.sort((a, b) => b.scoreCalc - a.scoreCalc);
    return all.map((e, i) => ({ ...e, rank: i + 1 }));
  }, []);
  const youEntry = previewBoard ? previewBoard.find(e => e.you) : null;
  const youIdx = youEntry ? youEntry.rank - 1 : -1;
  // Show 3 rows: row above YOU, YOU, row below YOU (or top 3 if YOU is at top)
  let nearby = [];
  if (previewBoard) {
    if (youIdx <= 0) nearby = previewBoard.slice(0, 3);
    else if (youIdx >= previewBoard.length - 1) nearby = previewBoard.slice(-3);
    else nearby = previewBoard.slice(youIdx - 1, youIdx + 2);
  }

  return (
    <ScreenWrap theme={theme}>
      <div style={{ paddingTop: 70, height: '100%', display: 'flex', flexDirection: 'column' }}>
        {/* Title */}
        <div style={{ textAlign: 'center', padding: '20px 16px 0' }}>
          <div style={{
            fontFamily: KANA_FONT, fontSize: 14, color: theme.secondary,
            letterSpacing: 8, marginBottom: 8,
          }}>カナ・タイパー</div>
          <div style={{
            fontFamily: PIXEL_FONT, fontSize: 32, color: theme.primary,
            textShadow: `0 0 20px ${theme.primary}, 4px 4px 0 #000`,
            lineHeight: 1.2, letterSpacing: 2,
          }}>KANA</div>
          <div style={{
            fontFamily: PIXEL_FONT, fontSize: 32, color: theme.accent,
            textShadow: `0 0 20px ${theme.accent}, 4px 4px 0 #000`,
            lineHeight: 1.2, letterSpacing: 2, marginTop: 4,
          }}>TYPER</div>
        </div>

        {/* Mascot / pixel character */}
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '0 32px', minHeight: 100 }}>
          <PixelMascot theme={theme} />
        </div>

        {/* Your rank preview — tap to open full leaderboard */}
        {youEntry && (
          <div style={{ padding: '0 16px 12px' }}>
            <button onClick={() => onScreen('leaderboard')} style={{
              width: '100%', background: 'transparent', cursor: 'pointer',
              border: `2px solid ${theme.primary}`, padding: '10px 12px',
              boxShadow: `0 0 16px ${theme.primary}40, 4px 4px 0 ${theme.primary}80`,
              fontFamily: PIXEL_FONT, color: 'inherit', textAlign: 'left',
            }}>
              <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
                <span style={{ fontSize: 9, color: theme.accent, letterSpacing: 2 }}>★ YOUR RANK</span>
                <span style={{ fontSize: 16, color: theme.accent, letterSpacing: 1, textShadow: `0 0 8px ${theme.accent}` }}>
                  #{youEntry.rank}<span style={{ fontSize: 9, color: theme.textDim }}>/{previewBoard.length}</span>
                </span>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                {nearby.map(e => (
                  <div key={e.name} style={{
                    display: 'flex', alignItems: 'center', padding: '4px 6px', fontSize: 9,
                    background: e.you ? `${theme.primary}30` : 'transparent',
                    border: e.you ? `1px solid ${theme.accent}` : '1px solid transparent',
                  }}>
                    <span style={{ width: 22, color: e.rank <= 3 ? theme.accent : theme.textDim }}>
                      {String(e.rank).padStart(2, '0')}
                    </span>
                    <span style={{ flex: 1, color: e.you ? theme.accent : theme.text, letterSpacing: 1 }}>
                      {e.name}{e.you && ' ◀'}
                    </span>
                    <span style={{ color: theme.secondary, letterSpacing: 1 }}>{e.scoreCalc} <span style={{ fontSize: 7, color: theme.textDim }}>PTS</span></span>
                  </div>
                ))}
              </div>
              <div style={{ textAlign: 'right', fontSize: 8, color: theme.textDim, letterSpacing: 1, marginTop: 6 }}>
                VIEW FULL ▸
              </div>
            </button>
          </div>
        )}

        {/* Press start */}
        <div style={{ textAlign: 'center', padding: '0 24px 12px' }}>
          <div onClick={onStart} style={{ cursor: 'pointer', opacity: blink ? 1 : 0.2, transition: 'opacity 0.1s' }}>
            <div style={{
              fontSize: 14, color: theme.text, letterSpacing: 2,
              textShadow: `0 0 8px ${theme.primary}`,
            }}>▶ PRESS START</div>
          </div>
        </div>

        {/* Bottom nav */}
        <div style={{ display: 'flex', gap: 6, padding: '0 16px 32px' }}>
          <NavBtn theme={theme} icon="🏆" label="LEAD" onClick={() => onScreen('leaderboard')} />
          <NavBtn theme={theme} icon="📚" label="TEXT" onClick={() => onScreen('wordpacks')} />
          <NavBtn theme={theme} icon="⚙" label="OPTS" onClick={() => onScreen('settings')} />
        </div>
      </div>
    </ScreenWrap>
  );
}

function NavBtn({ theme, icon, label, onClick }) {
  return (
    <button onClick={onClick} style={{
      flex: 1, background: 'transparent', border: `2px solid ${theme.primary}`,
      color: theme.text, padding: '10px 4px', cursor: 'pointer',
      fontFamily: PIXEL_FONT, fontSize: 9, letterSpacing: 1,
      boxShadow: `2px 2px 0 ${theme.primary}`,
    }}>
      <div style={{ fontSize: 16, marginBottom: 4 }}>{icon}</div>
      {label}
    </button>
  );
}

function PixelMascot({ theme }) {
  // Simple SVG pixel character — a bouncing typing cat
  const [bounce, setBounce] = React.useState(0);
  React.useEffect(() => {
    const i = setInterval(() => setBounce(b => (b + 1) % 2), 400);
    return () => clearInterval(i);
  }, []);
  return (
    <div style={{ transform: `translateY(${bounce ? -4 : 0}px)`, transition: 'transform 0.2s' }}>
      <svg width="160" height="160" viewBox="0 0 16 16" style={{ imageRendering: 'pixelated', filter: `drop-shadow(0 0 12px ${theme.primary})` }}>
        {/* cat body */}
        {/* ears */}
        <rect x="3" y="2" width="2" height="2" fill={theme.primary}/>
        <rect x="11" y="2" width="2" height="2" fill={theme.primary}/>
        {/* head */}
        <rect x="3" y="4" width="10" height="6" fill={theme.primary}/>
        {/* eyes */}
        <rect x="5" y="6" width="1" height="1" fill={theme.accent}/>
        <rect x="10" y="6" width="1" height="1" fill={theme.accent}/>
        {/* mouth */}
        <rect x="7" y="8" width="2" height="1" fill="#000"/>
        {/* body */}
        <rect x="4" y="10" width="8" height="3" fill={theme.secondary}/>
        {/* arms typing */}
        <rect x="2" y="11" width="2" height="1" fill={theme.primary}/>
        <rect x="12" y="11" width="2" height="1" fill={theme.primary}/>
        {/* keyboard hint */}
        <rect x="3" y="13" width="10" height="1" fill={theme.textDim}/>
        <rect x="3" y="14" width="10" height="1" fill={theme.panelBorder}/>
      </svg>
    </div>
  );
}

// ────── ACTIVE GAMEPLAY ──────
function GameScreen({ theme, duration, difficulty, onEnd }) {
  const WORDS = {
    easy: ['ねこ', 'いぬ', 'うみ', 'やま', 'はな', 'そら', 'みず', 'ひと', 'つき', 'ほし'],
    medium: ['さくら', 'ともだち', 'がっこう', 'でんしゃ', 'しんかんせん', 'おちゃ', 'りんご', 'たべる'],
    hard: ['ありがとう', 'きょうりゅう', 'としょかん', 'びじゅつかん', 'こうえんかい', 'しんりがく'],
  };
  const pool = WORDS[difficulty] || WORDS.medium;

  const [time, setTime] = React.useState(duration);
  const [target, setTarget] = React.useState(() => pool[Math.floor(Math.random() * pool.length)]);
  const [typed, setTyped] = React.useState('');
  const [score, setScore] = React.useState(0);
  const [combo, setCombo] = React.useState(0);
  const [bestCombo, setBestCombo] = React.useState(0);
  const [correctChars, setCorrectChars] = React.useState(0);
  const [wrongChars, setWrongChars] = React.useState(0);
  const [particles, setParticles] = React.useState([]);
  const [activeKey, setActiveKey] = React.useState(null);
  const [shake, setShake] = React.useState(false);
  const [paused, setPaused] = React.useState(false);

  React.useEffect(() => {
    if (paused) return;
    if (time <= 0) {
      const wpm = Math.round((correctChars / 2) / (duration / 60));
      const acc = correctChars + wrongChars > 0 ? Math.round(correctChars / (correctChars + wrongChars) * 100) : 100;
      onEnd({ wpm, acc, score, combo: bestCombo, words: score, time: duration });
      return;
    }
    const t = setTimeout(() => setTime(s => s - 1), 1000);
    return () => clearTimeout(t);
  }, [time, paused]);

  const handleKey = (k) => {
    setActiveKey(k);
    setTimeout(() => setActiveKey(null), 100);

    if (k === '__del') {
      setTyped(t => t.slice(0, -1));
      return;
    }
    if (k === '__enter') {
      // submit
      if (typed === target) {
        // success
        setScore(s => s + 1);
        setCombo(c => {
          const n = c + 1;
          setBestCombo(b => Math.max(b, n));
          return n;
        });
        setCorrectChars(c => c + target.length);
        setParticles(p => [...p, { id: Date.now(), x: 50 + (Math.random()-0.5)*20, y: 50 }]);
        setTimeout(() => setParticles(p => p.slice(1)), 800);
        setTarget(pool[Math.floor(Math.random() * pool.length)]);
        setTyped('');
      } else {
        setWrongChars(c => c + 1);
        setCombo(0);
        setShake(true);
        setTimeout(() => setShake(false), 300);
      }
      return;
    }

    // Inline kana variants (FlickKeyboard module no longer exposes KANA_VARIANTS)
    const KV = {
      'あ':['あ','い','う','え','お'], 'か':['か','き','く','け','こ'], 'さ':['さ','し','す','せ','そ'],
      'た':['た','ち','つ','て','と'], 'な':['な','に','ぬ','ね','の'], 'は':['は','ひ','ふ','へ','ほ'],
      'ま':['ま','み','む','め','も'], 'や':['や','ゆ','よ'], 'ら':['ら','り','る','れ','ろ'],
      'わ':['わ','を','ん','ー'],
    };
    const variants = KV[k] || [k];
    const nextNeeded = target[typed.length];
    const match = variants.find(v => v === nextNeeded);
    const ch = match || variants[0];
    setTyped(t => t + ch);

    // Auto-submit if match completes the word
    const newTyped = typed + ch;
    if (newTyped === target) {
      setTimeout(() => {
        setScore(s => s + 1);
        setCombo(c => {
          const n = c + 1;
          setBestCombo(b => Math.max(b, n));
          return n;
        });
        setCorrectChars(c => c + target.length);
        setParticles(p => [...p, { id: Date.now(), x: 50, y: 50 }]);
        setTimeout(() => setParticles(p => p.filter(x => x.id !== Date.now())), 800);
        setTarget(pool[Math.floor(Math.random() * pool.length)]);
        setTyped('');
      }, 50);
    }
  };

  const wpmLive = Math.round((correctChars / 2) / Math.max((duration - time) / 60, 0.01));

  return (
    <ScreenWrap theme={theme}>
      <div style={{ paddingTop: 60, height: '100%', display: 'flex', flexDirection: 'column' }}>
        {/* HUD */}
        <div style={{ display: 'flex', gap: 8, padding: '8px 12px' }}>
          <HudCell theme={theme} label="TIME" value={`${String(time).padStart(2,'0')}″`} alert={time <= 10} />
          <HudCell theme={theme} label="WPM" value={wpmLive} />
          <HudCell theme={theme} label="COMBO" value={`x${combo}`} accent={combo >= 3} />
        </div>

        {/* Stage */}
        <div style={{
          flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center',
          justifyContent: 'center', padding: '20px 16px', position: 'relative',
          transform: shake ? 'translateX(4px)' : 'none', transition: 'transform 0.05s',
          animation: shake ? 'shake 0.3s' : 'none',
        }}>
          {/* Target word */}
          <div style={{
            fontSize: 12, color: theme.textDim, letterSpacing: 2, marginBottom: 12,
          }}>▼ TYPE THIS</div>
          <div style={{
            fontFamily: KANA_FONT, fontSize: 42, letterSpacing: 4,
            color: theme.text, textShadow: `0 0 20px ${theme.primary}`,
            display: 'flex', gap: 2, marginBottom: 24,
          }}>
            {target.split('').map((ch, i) => (
              <span key={i} style={{
                color: i < typed.length ? (typed[i] === ch ? theme.correct : theme.wrong) : theme.text,
                opacity: i < typed.length ? 1 : 0.95,
                textShadow: i < typed.length && typed[i] === ch
                  ? `0 0 16px ${theme.correct}` : `0 0 12px ${theme.primary}`,
              }}>{ch}</span>
            ))}
          </div>

          {/* Input area */}
          <PixelPanel theme={theme} style={{ width: '100%', maxWidth: 320, textAlign: 'center', minHeight: 60 }}>
            <div style={{ fontSize: 9, color: theme.textDim, letterSpacing: 2, marginBottom: 6 }}>INPUT</div>
            <div style={{
              fontFamily: KANA_FONT, fontSize: 28, letterSpacing: 3,
              color: theme.accent, minHeight: 32,
            }}>
              {typed || <span style={{ color: theme.textDim }}>▮</span>}
            </div>
          </PixelPanel>

          {/* Particles */}
          {particles.map(p => (
            <ParticleBurst key={p.id} theme={theme} x={p.x} y={p.y} />
          ))}

          {/* Combo flash */}
          {combo >= 3 && (
            <div style={{
              position: 'absolute', top: 20, right: 20,
              fontSize: 14, color: theme.accent, letterSpacing: 2,
              animation: 'pulse 0.5s infinite alternate',
              textShadow: `0 0 12px ${theme.accent}`,
            }}>
              {combo}x COMBO!
            </div>
          )}
        </div>

        {/* iOS standard Japanese flick keyboard */}
        <IOSKanaKeyboard onKey={handleKey} dark />

        {/* Pause btn */}
        <button onClick={() => setPaused(p => !p)} style={{
          position: 'absolute', top: 60, right: 12, zIndex: 10,
          background: 'transparent', border: `2px solid ${theme.primary}`,
          color: theme.text, width: 32, height: 32, cursor: 'pointer',
          fontFamily: PIXEL_FONT, fontSize: 12,
        }}>{paused ? '▶' : '‖'}</button>
      </div>

      {paused && (
        <div style={{
          position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.7)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200,
          flexDirection: 'column', gap: 16,
        }}>
          <div style={{ fontSize: 24, color: theme.accent, letterSpacing: 4, textShadow: `0 0 16px ${theme.accent}` }}>PAUSED</div>
          <PixelButton theme={theme} primary onClick={() => setPaused(false)}>RESUME</PixelButton>
          <PixelButton theme={theme} small onClick={() => onEnd({ wpm: 0, acc: 0, score: 0, combo: 0, words: 0, abandoned: true })}>QUIT</PixelButton>
        </div>
      )}
      <style>{`
        @keyframes shake { 0%, 100% {transform: translateX(0)} 25% {transform: translateX(-6px)} 75% {transform: translateX(6px)} }
        @keyframes pulse { from {opacity: 0.7; transform: scale(1)} to {opacity: 1; transform: scale(1.1)} }
      `}</style>
    </ScreenWrap>
  );
}

function HudCell({ theme, label, value, alert, accent }) {
  return (
    <div style={{
      flex: 1, padding: '8px 6px', textAlign: 'center',
      border: `2px solid ${alert ? theme.wrong : (accent ? theme.accent : theme.primary)}`,
      background: 'rgba(0,0,0,0.4)',
      boxShadow: alert ? `0 0 12px ${theme.wrong}` : (accent ? `0 0 12px ${theme.accent}` : 'none'),
    }}>
      <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2, marginBottom: 2 }}>{label}</div>
      <div style={{ fontSize: 16, color: alert ? theme.wrong : (accent ? theme.accent : theme.text), letterSpacing: 1 }}>{value}</div>
    </div>
  );
}

function ParticleBurst({ theme, x, y }) {
  const particles = React.useMemo(() =>
    Array.from({ length: 14 }, (_, i) => ({
      angle: (Math.PI * 2 * i) / 14 + Math.random() * 0.4,
      dist: 60 + Math.random() * 40,
      size: 4 + Math.random() * 4,
      color: [theme.primary, theme.secondary, theme.accent, theme.correct][i % 4],
    })), []);
  return (
    <div style={{ position: 'absolute', left: `${x}%`, top: `${y}%`, pointerEvents: 'none' }}>
      {particles.map((p, i) => (
        <div key={i} style={{
          position: 'absolute', width: p.size, height: p.size,
          background: p.color, boxShadow: `0 0 8px ${p.color}`,
          animation: `burst-${i} 0.8s ease-out forwards`,
        }} />
      ))}
      <style>{particles.map((p, i) => `
        @keyframes burst-${i} {
          0% { transform: translate(0,0) scale(1); opacity: 1; }
          100% { transform: translate(${Math.cos(p.angle)*p.dist}px, ${Math.sin(p.angle)*p.dist}px) scale(0); opacity: 0; }
        }
      `).join('')}</style>
    </div>
  );
}

// ────── GAME OVER / RESULTS ──────
// Leaderboard data shared with LeaderboardScreen — keeps "your" rank consistent.
// date: ISO string when score was set; course: word/sentence pack used
const MOCK_BOARD = [
  { name: 'CPU.AI',  wpm: 142, acc: 99, combo: 48, words: 71, time: 60, date: '2026-04-29 09:14', course: '基本 / WORDS' },
  { name: 'KAZ★88',  wpm: 118, acc: 96, combo: 32, words: 59, time: 60, date: '2026-04-28 22:03', course: 'JLPT N5 / WORDS' },
  { name: 'YUKI_X',  wpm: 96,  acc: 98, combo: 28, words: 48, time: 60, date: '2026-04-29 07:42', course: '日常会話 / SENT.' },
  { name: 'TARO99',  wpm: 92,  acc: 81, combo: 12, words: 46, time: 60, date: '2026-04-27 19:11', course: '食べ物 / WORDS' },
  { name: 'M.SAKI',  wpm: 71,  acc: 88, combo: 14, words: 36, time: 60, date: '2026-04-29 12:50', course: '挨拶 / SENT.' },
  { name: 'NIN_JA',  wpm: 65,  acc: 97, combo: 22, words: 33, time: 60, date: '2026-04-26 14:25', course: '基本 / WORDS' },
  { name: 'GUEST1',  wpm: 44,  acc: 92, combo: 9,  words: 22, time: 60, date: '2026-04-29 08:30', course: '動物 / WORDS' },
  { name: 'PIXL_O',  wpm: 38,  acc: 90, combo: 8,  words: 19, time: 60, date: '2026-04-28 16:48', course: '俳句 / SENT.' },
  { name: 'BIT_99',  wpm: 31,  acc: 85, combo: 6,  words: 16, time: 60, date: '2026-04-25 10:22', course: '旅行 / WORDS' },
  { name: 'NOOB22',  wpm: 22,  acc: 70, combo: 4,  words: 11, time: 60, date: '2026-04-29 11:05', course: '基本 / WORDS' },
];

// Build a sorted, ranked board including the player's current run.
function buildBoard(playerResult) {
  const now = new Date();
  const stamp = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')} ${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`;
  const you = {
    name: 'YOU', you: true,
    wpm: playerResult.wpm, acc: playerResult.acc,
    combo: playerResult.combo, words: playerResult.score,
    time: playerResult.time || 30,
    date: playerResult.date || stamp,
    course: playerResult.course || '基本 / WORDS',
  };
  const all = [...MOCK_BOARD, you].map(e => ({
    ...e, scoreCalc: computeScore(e),
  }));
  all.sort((a, b) => b.scoreCalc - a.scoreCalc);
  return all.map((e, i) => ({ ...e, rank: i + 1 }));
}

// Build a "smart" view: top 5 always + a window around YOU.
function buildResultsView(board) {
  const youIdx = board.findIndex(e => e.you);
  const top5 = board.slice(0, 5);
  if (youIdx < 5) return { rows: top5, hasGap: false, youIdx };

  // Window: one above + you + one below
  const winStart = Math.max(5, youIdx - 1);
  const winEnd = Math.min(board.length, youIdx + 2);
  const windowRows = board.slice(winStart, winEnd);
  return {
    rows: top5,
    gapAfter: 5,
    windowRows,
    hasGap: true,
    youIdx,
  };
}

function ResultsScreen({ theme, result, onRetry, onHome }) {
  const [show, setShow] = React.useState({ wpm: 0, acc: 0, combo: 0, score: 0 });
  const [view, setView] = React.useState('stats'); // 'stats' | 'rank'
  const [openName, setOpenName] = React.useState(null);

  React.useEffect(() => {
    let i = 0;
    const tick = setInterval(() => {
      i++;
      setShow({
        wpm: Math.min(result.wpm, Math.round(result.wpm * i / 30)),
        acc: Math.min(result.acc, Math.round(result.acc * i / 30)),
        combo: Math.min(result.combo, Math.round(result.combo * i / 30)),
        score: Math.min(result.score, Math.round(result.score * i / 30)),
      });
      if (i > 30) clearInterval(tick);
    }, 30);
    return () => clearInterval(tick);
  }, []);

  const board = React.useMemo(() => buildBoard(result), [result]);
  const youEntry = board.find(e => e.you);
  const youRank = youEntry ? youEntry.rank : board.length;
  const totalScore = youEntry ? youEntry.scoreCalc : 0;
  const grade = totalScore > 110 ? 'S' : totalScore > 70 ? 'A' : totalScore > 40 ? 'B' : totalScore > 20 ? 'C' : 'D';
  const open = board.find(e => e.name === openName);

  return (
    <ScreenWrap theme={theme}>
      <div style={{ paddingTop: 70, padding: '70px 20px 20px', height: '100%', display: 'flex', flexDirection: 'column' }}>
        <div style={{ textAlign: 'center', marginBottom: 12 }}>
          <div style={{ fontSize: 11, color: theme.textDim, letterSpacing: 4 }}>—— GAME OVER ——</div>
          <div style={{
            fontSize: 24, color: theme.primary, marginTop: 6, letterSpacing: 3,
            textShadow: `0 0 16px ${theme.primary}, 4px 4px 0 #000`,
          }}>RESULTS</div>
        </div>

        {/* Tab switch */}
        <div style={{ display: 'flex', border: `2px solid ${theme.primary}`, marginBottom: 12 }}>
          {[['stats', 'YOUR STATS'], ['rank', 'RANKING']].map(([id, lbl]) => (
            <button key={id} onClick={() => setView(id)} style={{
              flex: 1, padding: '8px 4px', fontFamily: PIXEL_FONT, fontSize: 10, letterSpacing: 2,
              background: view === id ? theme.primary : 'transparent',
              color: view === id ? '#000' : theme.text, border: 'none', cursor: 'pointer',
            }}>{lbl}</button>
          ))}
        </div>

        {view === 'stats' && (
          <div style={{ flex: 1, overflow: 'auto' }}>
            {/* Grade + your rank pill */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, justifyContent: 'center', margin: '4px 0 14px' }}>
              <div style={{
                width: 80, height: 80, lineHeight: '80px', textAlign: 'center',
                border: `4px solid ${theme.accent}`, fontSize: 52, color: theme.accent,
                fontFamily: PIXEL_FONT,
                boxShadow: `0 0 24px ${theme.accent}, inset 0 0 16px ${theme.accent}40`,
                background: 'rgba(0,0,0,0.4)',
              }}>{grade}</div>
              <div>
                <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2 }}>RANK</div>
                <div style={{ fontSize: 28, color: theme.primary, letterSpacing: 1, textShadow: `0 0 8px ${theme.primary}` }}>
                  #{youRank}<span style={{ fontSize: 12, color: theme.textDim }}>/{board.length}</span>
                </div>
                <div style={{ fontSize: 9, color: theme.secondary, letterSpacing: 1, marginTop: 4 }}>{totalScore} PTS</div>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
              <StatCell theme={theme} label="WPM" value={show.wpm} big />
              <StatCell theme={theme} label="ACCURACY" value={`${show.acc}%`} big />
              <StatCell theme={theme} label="WORDS" value={show.score} />
              <StatCell theme={theme} label="MAX COMBO" value={`x${show.combo}`} />
            </div>

            {youRank <= 3 && (
              <div style={{
                textAlign: 'center', marginTop: 12, padding: '6px 10px',
                border: `2px dashed ${theme.accent}`, color: theme.accent,
                fontSize: 10, letterSpacing: 2, animation: 'pulse 1s infinite alternate',
              }}>★ TOP {youRank} FINISH ★</div>
            )}
          </div>
        )}

        {view === 'rank' && (
          <div style={{ flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column' }}>
            <ResultsBoard theme={theme} board={board} onOpen={setOpenName} />
          </div>
        )}

        <div style={{ display: 'flex', gap: 10, marginTop: 12, marginBottom: 24 }}>
          <div style={{ flex: 1 }}>
            <PixelButton theme={theme} onClick={onHome}>← HOME</PixelButton>
          </div>
          <div style={{ flex: 1 }}>
            <PixelButton theme={theme} primary onClick={onRetry}>RETRY ↻</PixelButton>
          </div>
        </div>

        {/* Player detail modal */}
        {open && (
          <div onClick={() => setOpenName(null)} style={{
            position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.78)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 200, padding: 20,
          }}>
            <div onClick={e => e.stopPropagation()} style={{
              width: '100%', maxWidth: 320,
              background: theme.bg, border: `3px solid ${theme.accent}`,
              boxShadow: `0 0 28px ${theme.accent}80`, padding: 20,
            }}>
              <PlayerDetailBody theme={theme} open={open} onClose={() => setOpenName(null)} />
            </div>
          </div>
        )}
      </div>
      <style>{`@keyframes pulse { from {opacity: 0.7} to {opacity: 1} }`}</style>
    </ScreenWrap>
  );
}

// Shared detail body — used in Results modal AND Leaderboard modal
function PlayerDetailBody({ theme, open, onClose }) {
  return (
    <>
      <div style={{ fontSize: 14, color: theme.accent, letterSpacing: 2, textShadow: `0 0 10px ${theme.accent}`, marginBottom: 4 }}>
        #{open.rank} {open.name}{open.you ? ' ◀' : ''}
      </div>
      <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2, marginBottom: 12 }}>
        {open.words} WORDS · {open.time}″
      </div>

      {/* Date + Course meta */}
      <div style={{
        display: 'flex', flexDirection: 'column', gap: 4, padding: '8px 10px',
        border: `1px dashed ${theme.textDim}`, marginBottom: 12,
        fontFamily: PIXEL_FONT, fontSize: 9,
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <span style={{ color: theme.textDim, letterSpacing: 1 }}>DATE</span>
          <span style={{ color: theme.text, letterSpacing: 1 }}>{open.date || '—'}</span>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <span style={{ color: theme.textDim, letterSpacing: 1 }}>COURSE</span>
          <span style={{ color: theme.secondary, letterSpacing: 1, fontFamily: KANA_FONT, fontSize: 11 }}>{open.course || '—'}</span>
        </div>
      </div>

      <div style={{ marginBottom: 10 }}>
        <DetailStat theme={theme} label="SCORE" value={open.scoreCalc} big />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
        <DetailStat theme={theme} label="WPM" value={open.wpm} />
        <DetailStat theme={theme} label="ACC" value={`${open.acc}%`} />
        <DetailStat theme={theme} label="COMBO" value={`x${open.combo}`} />
      </div>
      <button onClick={onClose} style={{
        width: '100%', marginTop: 16, padding: '10px',
        background: 'transparent', border: `2px solid ${theme.primary}`,
        color: theme.text, fontFamily: PIXEL_FONT, fontSize: 10, letterSpacing: 2,
        cursor: 'pointer', boxShadow: `2px 2px 0 ${theme.primary}`,
      }}>CLOSE ✕</button>
    </>
  );
}

// Compact ranking row used on Results screen
function RankRow({ theme, e, onOpen }) {
  return (
    <button onClick={() => onOpen(e.name)} style={{
      display: 'flex', alignItems: 'center', padding: '8px 10px', width: '100%',
      background: e.you ? `${theme.primary}30` : 'rgba(0,0,0,0.3)',
      border: e.you ? `2px solid ${theme.accent}` : `1px solid ${theme.textDim}`,
      fontFamily: PIXEL_FONT, fontSize: 10,
      boxShadow: e.you ? `0 0 12px ${theme.accent}80` : 'none',
      cursor: 'pointer', textAlign: 'left', color: 'inherit', marginBottom: 4,
    }}>
      <div style={{
        width: 26, color: e.rank <= 3 ? theme.accent : theme.textDim,
        fontSize: e.rank <= 3 ? 13 : 10,
      }}>
        {e.rank === 1 ? '①' : e.rank === 2 ? '②' : e.rank === 3 ? '③' : String(e.rank).padStart(2, '0')}
      </div>
      <div style={{ flex: 1, color: e.you ? theme.accent : theme.text, letterSpacing: 1 }}>
        {e.name}{e.you && ' ◀'}
      </div>
      <div style={{ color: theme.secondary, fontSize: 12, letterSpacing: 1 }}>
        {e.scoreCalc}<span style={{fontSize: 7, color: theme.textDim}}> PTS</span>
      </div>
    </button>
  );
}

function ResultsBoard({ theme, board, onOpen }) {
  const v = buildResultsView(board);
  return (
    <div>
      <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2, padding: '0 2px 6px' }}>▼ TOP 5</div>
      {v.rows.map(e => <RankRow key={e.name} theme={theme} e={e} onOpen={onOpen} />)}

      {v.hasGap && (
        <>
          <div style={{
            textAlign: 'center', color: theme.textDim, fontSize: 10, letterSpacing: 4,
            padding: '6px 0', fontFamily: PIXEL_FONT,
          }}>· · ·</div>
          <div style={{ fontSize: 8, color: theme.accent, letterSpacing: 2, padding: '0 2px 6px' }}>▼ YOUR RANGE</div>
          {v.windowRows.map(e => <RankRow key={e.name} theme={theme} e={e} onOpen={onOpen} />)}
        </>
      )}
    </div>
  );
}

function StatCell({ theme, label, value, big }) {
  return (
    <PixelPanel theme={theme} style={{ textAlign: 'center', padding: '12px 8px' }}>
      <div style={{ fontSize: 9, color: theme.textDim, letterSpacing: 2 }}>{label}</div>
      <div style={{
        fontSize: big ? 28 : 20, color: theme.accent, marginTop: 6,
        textShadow: `0 0 10px ${theme.accent}`, letterSpacing: 1,
      }}>{value}</div>
    </PixelPanel>
  );
}

// ────── LEADERBOARD ──────
// Composite score = WPM × (Accuracy/100)² × (1 + maxCombo/20)
// Accuracy is squared so wrong inputs penalize hard; combo gives a small flow bonus.
function computeScore({ wpm, acc, combo }) {
  return Math.round(wpm * Math.pow(acc / 100, 2) * (1 + combo / 20));
}

function LeaderboardScreen({ theme, onBack }) {
  const raw = [
    { name: 'CPU.AI',  wpm: 142, acc: 99, combo: 48, words: 71, time: 60 },
    { name: 'KAZ★88',  wpm: 118, acc: 96, combo: 32, words: 59, time: 60 },
    { name: 'YUKI_X',  wpm: 96,  acc: 98, combo: 28, words: 48, time: 60 },
    { name: 'YOU',     wpm: 84,  acc: 94, combo: 19, words: 42, time: 60, you: true },
    { name: 'TARO99',  wpm: 92,  acc: 81, combo: 12, words: 46, time: 60 },
    { name: 'NIN_JA',  wpm: 65,  acc: 97, combo: 22, words: 33, time: 60 },
    { name: 'M.SAKI',  wpm: 71,  acc: 88, combo: 14, words: 36, time: 60 },
    { name: 'GUEST1',  wpm: 44,  acc: 92, combo: 9,  words: 22, time: 60 },
  ];
  const entries = raw
    .map(e => ({ ...e, score: computeScore(e) }))
    .sort((a, b) => b.score - a.score)
    .map((e, i) => ({ ...e, rank: i + 1 }));

  const [openName, setOpenName] = React.useState(null);
  const open = entries.find(e => e.name === openName);

  return (
    <ScreenWrap theme={theme}>
      <div style={{ paddingTop: 70, padding: '70px 16px 24px', height: '100%', display: 'flex', flexDirection: 'column' }}>
        <ScreenHeader theme={theme} title="LEADERBOARD" onBack={onBack} />

        {/* Score formula hint */}
        <div style={{
          marginTop: 10, padding: '6px 8px', fontSize: 8, color: theme.textDim, letterSpacing: 1,
          fontFamily: PIXEL_FONT, border: `1px dashed ${theme.textDim}`, textAlign: 'center',
        }}>
          SCORE = WPM × ACC² × COMBO·BONUS
        </div>

        <div style={{ display: 'flex', gap: 6, margin: '12px 0' }}>
          {['DAILY', 'WEEKLY', 'ALL'].map((t, i) => (
            <button key={t} style={{
              flex: 1, padding: '6px 8px', fontFamily: PIXEL_FONT, fontSize: 9,
              background: i === 1 ? theme.primary : 'transparent',
              color: i === 1 ? '#000' : theme.text, border: `2px solid ${theme.primary}`,
              cursor: 'pointer', letterSpacing: 1,
            }}>{t}</button>
          ))}
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 4, flex: 1, overflow: 'auto' }}>
          {entries.map(e => (
            <button key={e.name} onClick={() => setOpenName(e.name)} style={{
              display: 'flex', alignItems: 'center', padding: '10px 12px',
              background: e.you ? `${theme.primary}30` : 'rgba(0,0,0,0.3)',
              border: e.you ? `2px solid ${theme.accent}` : `1px solid ${theme.textDim}`,
              fontFamily: PIXEL_FONT, fontSize: 11,
              boxShadow: e.you ? `0 0 12px ${theme.accent}80` : 'none',
              cursor: 'pointer', textAlign: 'left', color: 'inherit',
            }}>
              <div style={{
                width: 28, color: e.rank <= 3 ? theme.accent : theme.textDim,
                fontSize: e.rank <= 3 ? 14 : 11,
              }}>
                {e.rank === 1 ? '①' : e.rank === 2 ? '②' : e.rank === 3 ? '③' : String(e.rank).padStart(2, '0')}
              </div>
              <div style={{ flex: 1, color: e.you ? theme.accent : theme.text, letterSpacing: 1 }}>
                {e.name}{e.you && ' ◀'}
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ color: theme.secondary, fontSize: 14, letterSpacing: 1 }}>
                  {e.score} <span style={{fontSize: 8, color: theme.textDim}}>PTS</span>
                </div>
                <div style={{ fontSize: 7, color: theme.textDim, letterSpacing: 1, marginTop: 2 }}>tap ▸</div>
              </div>
            </button>
          ))}
        </div>

        {/* Player detail modal */}
        {open && (
          <div onClick={() => setOpenName(null)} style={{
            position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.78)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 200, padding: 20,
          }}>
            <div onClick={e => e.stopPropagation()} style={{
              width: '100%', maxWidth: 320,
              background: theme.bg, border: `3px solid ${theme.accent}`,
              boxShadow: `0 0 28px ${theme.accent}80`, padding: 20, position: 'relative',
            }}>
              <PlayerDetailBody theme={theme} open={{...open, scoreCalc: open.score}} onClose={() => setOpenName(null)} />
            </div>
          </div>
        )}
      </div>
    </ScreenWrap>
  );
}

function DetailStat({ theme, label, value, big }) {
  return (
    <div style={{
      flex: 1, padding: '8px 6px', textAlign: 'center',
      border: `2px solid ${theme.primary}`, background: 'rgba(0,0,0,0.4)',
      boxShadow: `0 0 10px ${theme.primary}40`,
    }}>
      <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2 }}>{label}</div>
      <div style={{
        fontSize: big ? 24 : 16, color: theme.accent, marginTop: 4,
        textShadow: `0 0 8px ${theme.accent}`, letterSpacing: 1, fontFamily: PIXEL_FONT,
      }}>{value}</div>
    </div>
  );
}

// ────── SETTINGS ──────
function SettingsScreen({ theme, onBack, settings, setSettings }) {
  return (
    <ScreenWrap theme={theme}>
      <div style={{ paddingTop: 70, padding: '70px 16px 24px', height: '100%', display: 'flex', flexDirection: 'column' }}>
        <ScreenHeader theme={theme} title="OPTIONS" onBack={onBack} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14, marginTop: 16 }}>
          <SettingRow theme={theme} label="DURATION" value={`${settings.duration}″`}
            options={[15, 30, 60]} onChange={v => setSettings(s => ({...s, duration: v}))} current={settings.duration} suffix="″" />
          <SettingRow theme={theme} label="DIFFICULTY" value={settings.difficulty.toUpperCase()}
            options={['easy', 'medium', 'hard']} onChange={v => setSettings(s => ({...s, difficulty: v}))} current={settings.difficulty} format={v => v.toUpperCase()} />
          <SettingToggle theme={theme} label="BGM" value={settings.bgm} onToggle={() => setSettings(s => ({...s, bgm: !s.bgm}))} />
          <SettingToggle theme={theme} label="SFX" value={settings.sfx} onToggle={() => setSettings(s => ({...s, sfx: !s.sfx}))} />
          <SettingToggle theme={theme} label="HAPTICS" value={settings.haptics} onToggle={() => setSettings(s => ({...s, haptics: !s.haptics}))} />
          <SettingToggle theme={theme} label="SCANLINES" value={settings.scanlines} onToggle={() => setSettings(s => ({...s, scanlines: !s.scanlines}))} />
        </div>
      </div>
    </ScreenWrap>
  );
}

function SettingRow({ theme, label, options, current, onChange, format = v => `${v}` }) {
  return (
    <div>
      <div style={{ fontSize: 9, color: theme.textDim, letterSpacing: 2, marginBottom: 6 }}>{label}</div>
      <div style={{ display: 'flex', gap: 6 }}>
        {options.map(opt => (
          <button key={opt} onClick={() => onChange(opt)} style={{
            flex: 1, padding: '10px 6px', fontFamily: PIXEL_FONT, fontSize: 11,
            background: opt === current ? theme.primary : 'transparent',
            color: opt === current ? '#000' : theme.text,
            border: `2px solid ${theme.primary}`, cursor: 'pointer',
            letterSpacing: 1, boxShadow: opt === current ? `0 0 12px ${theme.primary}` : 'none',
          }}>{format(opt)}</button>
        ))}
      </div>
    </div>
  );
}

function SettingToggle({ theme, label, value, onToggle }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
      <div style={{ fontSize: 11, color: theme.text, letterSpacing: 2 }}>{label}</div>
      <button onClick={onToggle} style={{
        width: 64, height: 28, background: value ? theme.primary : 'transparent',
        border: `2px solid ${theme.primary}`, cursor: 'pointer', position: 'relative',
        fontFamily: PIXEL_FONT, fontSize: 9, color: value ? '#000' : theme.textDim,
        letterSpacing: 1,
      }}>{value ? 'ON' : 'OFF'}</button>
    </div>
  );
}

// ────── ONBOARDING ──────
function OnboardingScreen({ theme, onDone }) {
  const [step, setStep] = React.useState(0);
  const steps = [
    {
      title: 'WELCOME',
      jp: 'ようこそ',
      desc: 'Type Japanese kana as fast as you can. Earn WPM. Climb the leaderboard.',
      icon: '🎌',
    },
    {
      title: 'FLICK INPUT',
      jp: 'フリック入力',
      desc: 'Tap a key for あ. Hold and swipe ←↑→↓ to type い・う・え・お variants.',
      icon: '👆',
    },
    {
      title: 'COMBO',
      jp: 'コンボ',
      desc: 'Chain perfect words for combo bonuses. Miss = combo broken!',
      icon: '⚡',
    },
    {
      title: 'READY?',
      jp: '準備OK？',
      desc: 'Pick a difficulty and time. The clock starts on your first key.',
      icon: '🚀',
    },
  ];
  const s = steps[step];
  return (
    <ScreenWrap theme={theme}>
      <div style={{ paddingTop: 70, padding: '80px 24px 24px', height: '100%', display: 'flex', flexDirection: 'column', textAlign: 'center' }}>
        {/* Step dots */}
        <div style={{ display: 'flex', gap: 6, justifyContent: 'center', marginBottom: 28 }}>
          {steps.map((_, i) => (
            <div key={i} style={{
              width: i === step ? 24 : 8, height: 8,
              background: i === step ? theme.accent : theme.textDim,
              transition: 'all 0.2s',
              boxShadow: i === step ? `0 0 8px ${theme.accent}` : 'none',
            }} />
          ))}
        </div>

        <div style={{ fontSize: 80, marginBottom: 16 }}>{s.icon}</div>
        <div style={{ fontFamily: KANA_FONT, fontSize: 18, color: theme.secondary, letterSpacing: 4, marginBottom: 8 }}>{s.jp}</div>
        <div style={{ fontSize: 22, color: theme.primary, letterSpacing: 3, marginBottom: 20, textShadow: `0 0 12px ${theme.primary}` }}>
          {s.title}
        </div>
        <div style={{ fontFamily: 'system-ui', fontSize: 14, color: theme.text, lineHeight: 1.6, padding: '0 12px', textWrap: 'pretty' }}>
          {s.desc}
        </div>

        <div style={{ flex: 1 }} />

        <div style={{ display: 'flex', gap: 10, marginBottom: 32 }}>
          {step > 0 && <div style={{flex: 1}}><PixelButton theme={theme} onClick={() => setStep(s => s - 1)}>← BACK</PixelButton></div>}
          <div style={{ flex: 2 }}>
            <PixelButton theme={theme} primary onClick={() => step < steps.length - 1 ? setStep(s => s + 1) : onDone()}>
              {step < steps.length - 1 ? 'NEXT →' : 'START GAME ▶'}
            </PixelButton>
          </div>
        </div>
        <div onClick={onDone} style={{ fontSize: 9, color: theme.textDim, letterSpacing: 2, cursor: 'pointer' }}>
          SKIP TUTORIAL
        </div>
      </div>
    </ScreenWrap>
  );
}

// ────── CONTENT PICKER (Words / Sentences, with future language switcher) ──────
function WordPackScreen({ theme, onBack }) {
  const [mode, setMode] = React.useState('words'); // 'words' | 'sentences'
  const [selected, setSelected] = React.useState('common');

  const wordPacks = [
    { id: 'common', jp: '基本', name: 'COMMON', sample: 'ねこ・いぬ・うみ', count: 200 },
    { id: 'food', jp: '食べ物', name: 'FOOD', sample: 'ラーメン・すし・おちゃ', count: 80 },
    { id: 'animals', jp: '動物', name: 'ANIMALS', sample: 'ねこ・うさぎ・くま', count: 60 },
    { id: 'travel', jp: '旅行', name: 'TRAVEL', sample: 'でんしゃ・ホテル・くうこう', count: 120 },
    { id: 'jlpt5', jp: 'JLPT N5', name: 'BEGINNER', sample: 'がっこう・ともだち・きょう', count: 800 },
  ];
  const sentencePacks = [
    { id: 'greet', jp: '挨拶', name: 'GREETINGS', sample: 'おはようございます', count: 30 },
    { id: 'daily', jp: '日常会話', name: 'DAILY TALK', sample: 'きょうはいいてんきですね', count: 60 },
    { id: 'travel-s', jp: '旅行会話', name: 'TRAVEL', sample: 'えきはどこですか？', count: 45 },
    { id: 'haiku', jp: '俳句', name: 'HAIKU', sample: 'ふるいけや かわずとびこむ', count: 20 },
    { id: 'lyrics', jp: '歌詞', name: 'J-POP LYRICS', sample: 'さくらさくら やよいのそらは', count: 25 },
  ];
  const items = mode === 'words' ? wordPacks : sentencePacks;

  return (
    <ScreenWrap theme={theme}>
      <div style={{ paddingTop: 70, padding: '70px 16px 24px', height: '100%', display: 'flex', flexDirection: 'column' }}>
        <ScreenHeader theme={theme} title="CHOOSE TEXT" onBack={onBack} />

        {/* Language pill — Japanese active, others teased */}
        <div style={{ display: 'flex', gap: 6, marginTop: 14, alignItems: 'center' }}>
          <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2, marginRight: 4 }}>LANG</div>
          <button style={{
            padding: '6px 10px', fontFamily: PIXEL_FONT, fontSize: 9, letterSpacing: 1,
            background: theme.primary, color: '#000', border: `2px solid ${theme.primary}`,
            cursor: 'pointer', boxShadow: `0 0 10px ${theme.primary}`,
          }}>🇯🇵 日本語</button>
          {[
            { f: '🇺🇸', l: 'EN' },
          ].map(x => (
            <button key={x.l} style={{
              padding: '6px 8px', fontFamily: PIXEL_FONT, fontSize: 9, letterSpacing: 1,
              background: 'transparent', color: theme.textDim,
              border: `2px dashed ${theme.textDim}`, cursor: 'default', opacity: 0.55,
            }}>{x.f} {x.l}</button>
          ))}
        </div>
        <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 1, marginTop: 6, fontFamily: 'system-ui' }}>
          ▸ More languages coming soon
        </div>

        {/* Mode switch — Words vs Sentences */}
        <div style={{ display: 'flex', gap: 0, marginTop: 14, border: `2px solid ${theme.primary}`, boxShadow: `2px 2px 0 ${theme.primary}` }}>
          {[
            { id: 'words', en: 'WORDS', jp: '単語' },
            { id: 'sentences', en: 'SENTENCES', jp: '文章' },
          ].map(m => (
            <button key={m.id} onClick={() => setMode(m.id)} style={{
              flex: 1, padding: '10px 8px', fontFamily: PIXEL_FONT, fontSize: 10, letterSpacing: 2,
              background: mode === m.id ? theme.primary : 'transparent',
              color: mode === m.id ? '#000' : theme.text,
              border: 'none', cursor: 'pointer',
            }}>
              <div>{m.en}</div>
              <div style={{ fontFamily: KANA_FONT, fontSize: 9, marginTop: 2, opacity: 0.85 }}>{m.jp}</div>
            </button>
          ))}
        </div>

        {/* Pack list */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginTop: 14, flex: 1, overflow: 'auto' }}>
          {items.map(p => {
            const active = selected === p.id;
            return (
              <div key={p.id} onClick={() => setSelected(p.id)} style={{
                padding: '10px 12px', cursor: 'pointer',
                border: `2px solid ${active ? theme.accent : theme.primary}`,
                background: active ? `${theme.primary}20` : 'rgba(0,0,0,0.4)',
                boxShadow: active ? `0 0 14px ${theme.accent}80` : `2px 2px 0 ${theme.primary}80`,
                position: 'relative',
              }}>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 4 }}>
                  <div style={{ fontFamily: KANA_FONT, fontSize: 14, color: active ? theme.accent : theme.text, letterSpacing: 2 }}>{p.jp}</div>
                  <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2 }}>{p.name}</div>
                  <div style={{ flex: 1 }} />
                  <div style={{ fontSize: 8, color: theme.secondary, letterSpacing: 1 }}>×{p.count}</div>
                </div>
                <div style={{ fontFamily: KANA_FONT, fontSize: 11, color: theme.textDim, letterSpacing: 1, lineHeight: 1.5 }}>
                  {p.sample}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </ScreenWrap>
  );
}

function ScreenHeader({ theme, title, onBack }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
      <button onClick={onBack} style={{
        width: 36, height: 36, background: 'transparent',
        border: `2px solid ${theme.primary}`, color: theme.text,
        fontFamily: PIXEL_FONT, fontSize: 14, cursor: 'pointer',
        boxShadow: `2px 2px 0 ${theme.primary}`,
      }}>←</button>
      <div style={{ fontSize: 16, color: theme.primary, letterSpacing: 3, textShadow: `0 0 8px ${theme.primary}` }}>{title}</div>
    </div>
  );
}

Object.assign(window, {
  THEMES, HomeScreen, GameScreen, ResultsScreen,
  LeaderboardScreen, SettingsScreen, OnboardingScreen, WordPackScreen,
  PixelButton, PixelPanel, ScreenWrap,
});
