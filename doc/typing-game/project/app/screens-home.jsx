// Home, Onboarding, Settings, WordPacks, Leaderboard, Results screens.

function ScreenChrome({ theme, title, onBack, children, hideOverlay }) {
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: theme.bg, color: theme.text, fontFamily: PIXEL,
      overflow: 'hidden', display: 'flex', flexDirection: 'column',
    }}>
      {!hideOverlay && <CRTOverlay theme={theme} />}
      <div style={{
        padding: '20px 16px 12px', display: 'flex', alignItems: 'center', gap: 12,
        position: 'relative', zIndex: 5,
      }}>
        {onBack && (
          <button onClick={onBack} style={{
            width: 36, height: 36, background: 'transparent',
            border: `2px solid ${theme.primary}`, color: theme.text,
            fontFamily: PIXEL, fontSize: 14, cursor: 'pointer',
            boxShadow: `2px 2px 0 ${theme.primary}`,
          }}>←</button>
        )}
        {title && <div style={{
          fontSize: 14, color: theme.primary, letterSpacing: 4,
          textShadow: `0 0 8px ${theme.primary}`,
        }}>{title}</div>}
      </div>
      <div style={{ flex: 1, overflowY: 'auto', position: 'relative', zIndex: 5 }}>
        {children}
      </div>
    </div>
  );
}

// ───── ONBOARDING ─────
function Onboarding({ theme, onDone }) {
  const [step, setStep] = React.useState(0);
  const [name, setName] = React.useState('');
  const slides = [
    { jp: 'ようこそ', en: 'WELCOME', body: 'Type Japanese kana as fast as you can.' },
    { jp: 'ローマ字', en: 'TYPE ROMAJI', body: 'Use a-z keys. "ka"→か, "shi"→し. Long vowels: "kou".' },
    { jp: 'なまえ', en: 'YOUR NAME', body: 'Pick a name for the leaderboard.' },
  ];
  const s = slides[step];
  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: theme.bg, color: theme.text, fontFamily: PIXEL,
      overflow: 'hidden', display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center', padding: 24,
    }}>
      <CRTOverlay theme={theme} />
      <div style={{ position: 'relative', zIndex: 5, textAlign: 'center', maxWidth: 360 }}>
        <PixelMascot theme={theme} mood={step === 1 ? 'happy' : 'idle'} size={10} />
        <div style={{ fontFamily: KANA_F, fontSize: 22, color: theme.secondary, letterSpacing: 6, marginTop: 24 }}>{s.jp}</div>
        <div style={{ fontSize: 22, color: theme.primary, letterSpacing: 3, marginTop: 8, textShadow: `0 0 12px ${theme.primary}` }}>{s.en}</div>
        <div style={{ fontSize: 11, color: theme.text, marginTop: 20, lineHeight: 1.7, letterSpacing: 1 }}>{s.body}</div>

        {step === 2 && (
          <input value={name} onChange={e => setName(e.target.value.toUpperCase().slice(0, 8))}
            placeholder="ENTER NAME" maxLength={8}
            style={{
              marginTop: 20, padding: '10px 14px', width: '80%',
              background: 'rgba(0,0,0,0.5)', border: `2px solid ${theme.primary}`,
              color: theme.accent, fontFamily: PIXEL, fontSize: 16, textAlign: 'center',
              letterSpacing: 4, outline: 'none',
            }} />
        )}

        <div style={{ display: 'flex', gap: 8, justifyContent: 'center', marginTop: 32 }}>
          {slides.map((_, i) => (
            <div key={i} style={{
              width: 8, height: 8,
              background: i === step ? theme.primary : theme.textDim,
            }} />
          ))}
        </div>

        <div style={{ marginTop: 24, display: 'flex', gap: 12, justifyContent: 'center' }}>
          {step > 0 && <PixelBtn theme={theme} small onClick={() => setStep(step - 1)}>← BACK</PixelBtn>}
          <PixelBtn theme={theme} primary
            onClick={() => {
              if (step < slides.length - 1) setStep(step + 1);
              else if (name.trim()) onDone(name.trim());
            }}
          >{step < slides.length - 1 ? 'NEXT ▶' : 'START ▶'}</PixelBtn>
        </div>
      </div>
    </div>
  );
}

// ───── HOME ─────
function HomeView({ theme, state, onStart, onScreen }) {
  const [blink, setBlink] = React.useState(true);
  React.useEffect(() => {
    const i = setInterval(() => setBlink(b => !b), 600);
    return () => clearInterval(i);
  }, []);

  // Build leaderboard preview from history + cumulative totals
  const totals = React.useMemo(() => {
    const h = state.history || [];
    const total = h.reduce((sum, e) => sum + (e.score || 0), 0);
    const games = h.length;
    const best = h.reduce((m, e) => Math.max(m, e.score || 0), 0);
    return { total, games, best };
  }, [state.history]);

  const ranks = React.useMemo(() => {
    // Same CPU dataset as Leaderboard
    const cpu = [
      { name: 'CPU.AI',  best: 320, games: 18 },
      { name: 'KAZ★88',  best: 248, games: 24 },
      { name: 'TYPER77', best: 195, games: 41 },
      { name: 'MOMO♥',   best: 158, games: 32 },
      { name: 'NEKO99',  best: 112, games: 56 },
      { name: 'SORA22',  best: 88,  games: 12 },
      { name: 'YUKI★',   best: 70,  games: 28 },
    ].map(e => ({ ...e, total: Math.round(e.best * Math.pow(e.games, 0.7)) }));
    const youRow = {
      name: state.name || 'YOU',
      best: totals.best,
      total: totals.total,
      games: totals.games,
      you: true,
    };
    function rank(field) {
      const all = [...cpu, youRow]
        .slice()
        .sort((a, b) => b[field] - a[field])
        .map((e, i) => ({ ...e, rank: i + 1 }));
      return all;
    }
    const totalRanked = rank('total');
    const bestRanked = rank('best');
    return {
      total: totalRanked,
      best: bestRanked,
      youTotal: totalRanked.find(e => e.you),
      youBest: bestRanked.find(e => e.you),
    };
  }, [state.name, totals]);

  const youEntry = ranks.youTotal; // primary rank shown on home = total
  const board = ranks.total;
  const youIdx = youEntry.rank - 1;
  let nearby = [];
  if (youIdx <= 0) nearby = board.slice(0, 3);
  else if (youIdx >= board.length - 1) nearby = board.slice(-3);
  else nearby = board.slice(youIdx - 1, youIdx + 2);

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: theme.bg, color: theme.text, fontFamily: PIXEL,
      overflow: 'hidden', display: 'flex', flexDirection: 'column',
    }}>
      <CRTOverlay theme={theme} />

      {/* Title */}
      <div style={{ textAlign: 'center', padding: '32px 16px 0', position: 'relative', zIndex: 5 }}>
        <div style={{ fontFamily: KANA_F, fontSize: 14, color: theme.secondary, letterSpacing: 8, marginBottom: 8 }}>
          カナ・タイパー
        </div>
        <div style={{
          fontFamily: PIXEL, fontSize: 'clamp(32px, 8vw, 48px)', color: theme.primary,
          textShadow: `0 0 20px ${theme.primary}, 4px 4px 0 #000`, lineHeight: 1.1, letterSpacing: 2,
        }}>KANA</div>
        <div style={{
          fontFamily: PIXEL, fontSize: 'clamp(32px, 8vw, 48px)', color: theme.accent,
          textShadow: `0 0 20px ${theme.accent}, 4px 4px 0 #000`, lineHeight: 1.1, letterSpacing: 2, marginTop: 4,
        }}>TYPER</div>
      </div>

      {/* Cumulative + best score banner — two stacked rank tiles */}
      <div style={{ padding: '20px 16px 0', position: 'relative', zIndex: 5, display: 'flex', gap: 8 }}>
        {[
          { id: 'total', label: '★ TOTAL', value: totals.total, sub: `GAMES·${totals.games}`, accent: theme.accent, rank: ranks.youTotal.rank, of: ranks.total.length },
          { id: 'best',  label: '♕ BEST',  value: totals.best,  sub: 'SINGLE RUN',          accent: theme.primary, rank: ranks.youBest.rank,  of: ranks.best.length },
        ].map(t => (
          <button key={t.id} onClick={() => onScreen('leaderboard')} style={{
            flex: 1, background: 'transparent', cursor: 'pointer',
            border: `3px solid ${t.accent}`, padding: '12px 12px',
            boxShadow: `0 0 18px ${t.accent}30, 4px 4px 0 ${t.accent}60`,
            fontFamily: PIXEL, color: 'inherit', textAlign: 'left',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
              <span style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2 }}>{t.label}</span>
              <span style={{ fontSize: 11, color: t.accent, textShadow: `0 0 6px ${t.accent}`, letterSpacing: 1 }}>
                #{t.rank}<span style={{ fontSize: 7, color: theme.textDim }}>/{t.of}</span>
              </span>
            </div>
            <div style={{
              fontSize: 'clamp(22px, 6.5vw, 28px)', color: t.accent, letterSpacing: 1,
              textShadow: `0 0 12px ${t.accent}`, lineHeight: 1, fontFamily: PIXEL,
            }}>
              {String(t.value).padStart(5, '0')}
            </div>
            <div style={{ fontSize: 7, color: theme.textDim, letterSpacing: 2, marginTop: 6 }}>
              {t.sub}
            </div>
          </button>
        ))}
      </div>

      {/* Mascot */}
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '0 32px', minHeight: 60, position: 'relative', zIndex: 5 }}>
        <PixelMascot theme={theme} size={9} />
      </div>

      {/* Rank preview */}
      <div style={{ padding: '0 16px 12px', position: 'relative', zIndex: 5 }}>
        <button onClick={() => onScreen('leaderboard')} style={{
          width: '100%', background: 'transparent', cursor: 'pointer',
          border: `2px solid ${theme.primary}`, padding: '10px 12px',
          boxShadow: `0 0 16px ${theme.primary}40, 4px 4px 0 ${theme.primary}80`,
          fontFamily: PIXEL, color: 'inherit', textAlign: 'left',
        }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
            <span style={{ fontSize: 9, color: theme.accent, letterSpacing: 2 }}>★ NEAR YOU</span>
            <span style={{ fontSize: 9, color: theme.textDim, letterSpacing: 1 }}>
              FULL ▸
            </span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            {nearby.map(e => (
              <div key={e.name + e.rank} style={{
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
                <span style={{ color: theme.secondary, letterSpacing: 1 }}>
                  {e.total} <span style={{ fontSize: 7, color: theme.textDim }}>PTS</span>
                </span>
              </div>
            ))}
          </div>
          <div style={{ textAlign: 'right', fontSize: 8, color: theme.textDim, letterSpacing: 1, marginTop: 6 }}>
            VIEW FULL ▸
          </div>
        </button>
      </div>

      {/* Press start */}
      <div style={{ textAlign: 'center', padding: '0 24px 12px', position: 'relative', zIndex: 5 }}>
        <div onClick={onStart} style={{ cursor: 'pointer', opacity: blink ? 1 : 0.2, transition: 'opacity 0.1s' }}>
          <div style={{ fontSize: 14, color: theme.text, letterSpacing: 2, textShadow: `0 0 8px ${theme.primary}` }}>
            ▶ PRESS START
          </div>
        </div>
      </div>

      {/* Bottom nav */}
      <div style={{ display: 'flex', gap: 6, padding: '0 16px 24px', position: 'relative', zIndex: 5 }}>
        {[
          ['🏆','LEAD','leaderboard'],
          ['📚','TEXT','wordpacks'],
          ['⚙','OPTS','settings'],
        ].map(([icon, label, screen]) => (
          <button key={screen} onClick={() => onScreen(screen)} style={{
            flex: 1, background: 'transparent', border: `2px solid ${theme.primary}`,
            color: theme.text, padding: '10px 4px', cursor: 'pointer',
            fontFamily: PIXEL, fontSize: 9, letterSpacing: 1,
            boxShadow: `2px 2px 0 ${theme.primary}`,
          }}>
            <div style={{ fontSize: 16, marginBottom: 2 }}>{icon}</div>
            {label}
          </button>
        ))}
      </div>
    </div>
  );
}

window.Onboarding = Onboarding;
window.HomeView = HomeView;
window.ScreenChrome = ScreenChrome;
