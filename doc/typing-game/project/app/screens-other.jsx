// Settings, WordPacks, Leaderboard, Results screens.

function computeScore({ wpm, acc, combo }) {
  return Math.round(wpm * Math.pow(acc / 100, 2) * (1 + combo / 20));
}

// ───── SETTINGS ─────
function Settings({ theme, state, onUpdate, onBack }) {
  const Row = ({ label, children }) => (
    <div style={{ marginBottom: 18 }}>
      <div style={{ fontSize: 9, color: theme.textDim, letterSpacing: 2, marginBottom: 8 }}>{label}</div>
      {children}
    </div>
  );
  const Seg = ({ value, options, onChange }) => (
    <div style={{ display: 'flex', gap: 4 }}>
      {options.map(opt => (
        <button key={opt.id} onClick={() => onChange(opt.id)} style={{
          flex: 1, padding: '10px 4px', fontFamily: PIXEL, fontSize: 10,
          background: opt.id === value ? theme.primary : 'transparent',
          color: opt.id === value ? '#000' : theme.text,
          border: `2px solid ${theme.primary}`, cursor: 'pointer',
          boxShadow: opt.id === value ? `0 0 8px ${theme.primary}` : 'none',
          letterSpacing: 1,
        }}>{opt.label}</button>
      ))}
    </div>
  );

  return (
    <ScreenChrome theme={theme} title="⚙ SETTINGS" onBack={onBack}>
      <div style={{ padding: '8px 16px 32px' }}>
        <Row label="PLAYER NAME">
          <input value={state.name} onChange={e => onUpdate({ name: e.target.value.toUpperCase().slice(0, 8) })}
            maxLength={8}
            style={{
              width: '100%', padding: '10px 12px',
              background: 'rgba(0,0,0,0.5)', border: `2px solid ${theme.primary}`,
              color: theme.accent, fontFamily: PIXEL, fontSize: 14, letterSpacing: 3,
              outline: 'none',
            }}
          />
        </Row>

        <Row label="THEME">
          <Seg value={state.theme} onChange={v => onUpdate({ theme: v })} options={[
            { id: 'arcade', label: 'NEON' },
            { id: 'matrix', label: 'MATRIX' },
            { id: 'sunset', label: 'SUNSET' },
          ]} />
        </Row>

        <Row label="ROUND DURATION">
          <Seg value={state.duration} onChange={v => onUpdate({ duration: v })} options={[
            { id: 15, label: '15s' },
            { id: 30, label: '30s' },
            { id: 60, label: '60s' },
          ]} />
        </Row>

        <Row label="DIFFICULTY">
          <Seg value={state.difficulty} onChange={v => onUpdate({ difficulty: v })} options={[
            { id: 'easy', label: 'EASY' },
            { id: 'normal', label: 'NORMAL' },
            { id: 'hard', label: 'HARD' },
          ]} />
        </Row>

        <Row label="SOUND">
          <Seg value={state.sound ? 'on' : 'off'} onChange={v => onUpdate({ sound: v === 'on' })} options={[
            { id: 'on', label: 'ON' },
            { id: 'off', label: 'OFF' },
          ]} />
        </Row>

        <div style={{
          marginTop: 24, padding: 12, fontSize: 9, color: theme.textDim,
          border: `1px dashed ${theme.textDim}`, letterSpacing: 1, lineHeight: 1.6,
        }}>
          PROGRESS IS SAVED ON THIS DEVICE.
          <br/>BEST SCORE: <span style={{ color: theme.accent }}>{state.bestScore || 0} PTS</span>
          <br/>BEST WPM: <span style={{ color: theme.accent }}>{state.bestWpm || 0}</span>
          <br/>GAMES PLAYED: <span style={{ color: theme.accent }}>{state.history?.length || 0}</span>
        </div>

        <button onClick={() => {
          if (confirm('Reset all data? This will erase your name, scores, and history.')) {
            localStorage.removeItem('kanaTyper.v1');
            location.reload();
          }
        }} style={{
          marginTop: 16, width: '100%', padding: 12,
          background: 'transparent', border: `2px solid ${theme.wrong}`, color: theme.wrong,
          fontFamily: PIXEL, fontSize: 10, letterSpacing: 2, cursor: 'pointer',
        }}>↺ RESET ALL DATA</button>
      </div>
    </ScreenChrome>
  );
}

// ───── WORD PACKS ─────
function WordPacks({ theme, state, onUpdate, onBack }) {
  return (
    <ScreenChrome theme={theme} title="📚 TEXT PACKS" onBack={onBack}>
      <div style={{ padding: '8px 16px 32px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {PACKS.map(p => {
          const active = state.pack === p.id;
          const display = p.katakana ? hiraToKata(p.sample) : p.sample;
          return (
            <button key={p.id} onClick={() => onUpdate({ pack: p.id })} style={{
              padding: 14, textAlign: 'left', cursor: 'pointer',
              background: active ? `${theme.primary}20` : 'transparent',
              border: `2px solid ${active ? theme.primary : theme.textDim}`,
              boxShadow: active ? `0 0 16px ${theme.primary}60, 4px 4px 0 ${theme.primary}80` : 'none',
              color: 'inherit',
            }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 6 }}>
                <div style={{ fontFamily: KANA_F, fontSize: 16, color: active ? theme.accent : theme.text, letterSpacing: 2 }}>{p.jp}</div>
                <div style={{ fontSize: 9, color: theme.textDim, letterSpacing: 2 }}>{p.en}</div>
                <div style={{ flex: 1 }} />
                <div style={{ fontSize: 9, color: theme.secondary, letterSpacing: 1 }}>×{p.entries.length}</div>
              </div>
              <div style={{ fontFamily: KANA_F, fontSize: 13, color: theme.textDim, letterSpacing: 1 }}>
                {display}
              </div>
              {active && <div style={{ fontSize: 8, color: theme.accent, letterSpacing: 2, marginTop: 8 }}>▶ SELECTED</div>}
            </button>
          );
        })}
      </div>
    </ScreenChrome>
  );
}

// ───── LEADERBOARD ─────
function Leaderboard({ theme, state, onBack }) {
  const [view, setView] = React.useState('total'); // 'total' | 'best'

  // CPUs have a baseline best-score; their cumulative is best * a games multiplier
  // so the two boards re-shuffle differently.
  const boards = React.useMemo(() => {
    const cpu = [
      { name: 'CPU.AI',  best: 320, games: 18, wpm: 142, acc: 99, combo: 48, words: 71, time: 60, date: '2026-04-29 09:14', course: '基本 / 60s' },
      { name: 'KAZ★88',  best: 248, games: 24, wpm: 118, acc: 96, combo: 32, words: 59, time: 60, date: '2026-04-28 22:03', course: 'JLPT N5 / 60s' },
      { name: 'TYPER77', best: 195, games: 41, wpm: 102, acc: 94, combo: 24, words: 51, time: 60, date: '2026-04-28 14:50', course: '会話 / 30s' },
      { name: 'MOMO♥',   best: 158, games: 32, wpm: 88,  acc: 92, combo: 19, words: 44, time: 30, date: '2026-04-27 19:22', course: '基本 / 30s' },
      { name: 'NEKO99',  best: 112, games: 56, wpm: 71,  acc: 90, combo: 14, words: 36, time: 30, date: '2026-04-26 11:08', course: 'カタカナ / 30s' },
      { name: 'SORA22',  best: 88,  games: 12, wpm: 60,  acc: 88, combo: 11, words: 30, time: 60, date: '2026-04-25 20:40', course: '基本 / 60s' },
      { name: 'YUKI★',   best: 70,  games: 28, wpm: 52,  acc: 85, combo: 8,  words: 26, time: 30, date: '2026-04-25 08:12', course: 'JLPT N5 / 30s' },
    ].map(e => ({
      ...e,
      // approximate cumulative — scale best by game count with a fall-off
      total: Math.round(e.best * Math.pow(e.games, 0.7)),
    }));

    const h = state.history || [];
    const me = h.slice().sort((a, b) => b.score - a.score)[0];
    const myTotal = h.reduce((s, e) => s + (e.score || 0), 0);
    const myBest = me?.score || 0;
    const youRow = {
      name: state.name || 'YOU',
      best: myBest,
      total: myTotal,
      games: h.length,
      wpm: me?.wpm || 0,
      acc: me?.acc || 0,
      combo: me?.combo || 0,
      words: me?.words || 0,
      time: me?.time || 30,
      date: me?.date || '—',
      course: me?.course || '—',
      you: true,
    };

    function rank(field) {
      return [...cpu, youRow]
        .slice()
        .sort((a, b) => b[field] - a[field])
        .map((e, i) => ({ ...e, rank: i + 1 }));
    }
    return { total: rank('total'), best: rank('best') };
  }, [state]);

  const board = boards[view];
  const [open, setOpen] = React.useState(null);

  return (
    <ScreenChrome theme={theme} title="🏆 LEADERBOARD" onBack={onBack}>
      <div style={{ padding: '8px 16px 32px' }}>

        {/* Tab switcher */}
        <div style={{ display: 'flex', gap: 4, marginBottom: 12 }}>
          {[['total','★ TOTAL', '累計'], ['best','♕ BEST', 'ベスト']].map(([id, lbl, jp]) => {
            const active = view === id;
            return (
              <button key={id} onClick={() => setView(id)} style={{
                flex: 1, padding: '10px 4px', fontFamily: PIXEL, fontSize: 10, letterSpacing: 2,
                background: active ? theme.primary : 'transparent',
                color: active ? '#000' : theme.text,
                border: `2px solid ${theme.primary}`, cursor: 'pointer',
                boxShadow: active ? `0 0 12px ${theme.primary}` : 'none',
              }}>
                <div>{lbl}</div>
                <div style={{ fontFamily: KANA_F, fontSize: 9, marginTop: 2, opacity: 0.85 }}>{jp}</div>
              </button>
            );
          })}
        </div>

        <div style={{
          padding: '6px 8px', fontSize: 8, color: theme.textDim, letterSpacing: 1,
          fontFamily: PIXEL, border: `1px dashed ${theme.textDim}`, textAlign: 'center', marginBottom: 12,
        }}>
          {view === 'total'
            ? '累計スコア = ALL GAMES SUMMED'
            : 'ベストスコア = SINGLE BEST RUN'}
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          {board.map(e => {
            const value = view === 'total' ? e.total : e.best;
            return (
              <button key={`${view}-${e.rank}`} onClick={() => setOpen(e)} style={{
                padding: '10px 12px', display: 'flex', alignItems: 'center',
                background: e.you ? `${theme.primary}30` : 'rgba(0,0,0,0.3)',
                border: e.you ? `2px solid ${theme.accent}` : `1px solid ${theme.textDim}`,
                fontFamily: PIXEL, fontSize: 11,
                boxShadow: e.you ? `0 0 12px ${theme.accent}80` : 'none',
                cursor: 'pointer', color: 'inherit', textAlign: 'left',
              }}>
                <div style={{
                  width: 32, fontSize: 14,
                  color: e.rank === 1 ? theme.accent : e.rank <= 3 ? theme.secondary : theme.textDim,
                  textShadow: e.rank <= 3 ? `0 0 8px currentColor` : 'none',
                }}>{String(e.rank).padStart(2, '0')}</div>
                <div style={{ flex: 1, color: e.you ? theme.accent : theme.text, letterSpacing: 1 }}>
                  {e.name}{e.you && ' ◀'}
                </div>
                <div style={{ color: theme.secondary, letterSpacing: 1, marginRight: 10, fontSize: 8 }}>
                  {view === 'total' ? `×${e.games}` : `${e.wpm}wpm`}
                </div>
                <div style={{ color: theme.accent, letterSpacing: 1 }}>
                  {value}<span style={{ fontSize: 7, color: theme.textDim, marginLeft: 2 }}>PTS</span>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {open && (
        <div onClick={() => setOpen(null)} style={{
          position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.85)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          padding: 16, zIndex: 50,
        }}>
          <div onClick={e => e.stopPropagation()} style={{
            background: theme.bg, border: `3px solid ${theme.primary}`, padding: 20,
            width: '100%', maxWidth: 320, boxShadow: `0 0 40px ${theme.primary}80`,
          }}>
            <div style={{ fontSize: 12, color: theme.accent, letterSpacing: 2, marginBottom: 4 }}>#{open.rank} {open.name}</div>
            <div style={{ display: 'flex', gap: 12, alignItems: 'baseline', marginBottom: 12 }}>
              <div>
                <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2 }}>★ TOTAL</div>
                <div style={{ fontSize: 22, color: theme.accent, textShadow: `0 0 10px ${theme.accent}` }}>{open.total}</div>
              </div>
              <div>
                <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2 }}>♕ BEST</div>
                <div style={{ fontSize: 22, color: theme.primary, textShadow: `0 0 10px ${theme.primary}` }}>{open.best}</div>
              </div>
              <div>
                <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2 }}>GAMES</div>
                <div style={{ fontSize: 22, color: theme.secondary }}>{open.games}</div>
              </div>
            </div>
            <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2, marginBottom: 6 }}>BEST RUN STATS</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 12 }}>
              <StatBlock theme={theme} label="WPM" value={open.wpm} />
              <StatBlock theme={theme} label="ACC" value={`${open.acc}%`} />
              <StatBlock theme={theme} label="COMBO" value={open.combo} />
              <StatBlock theme={theme} label="WORDS" value={open.words} />
            </div>
            <div style={{ fontSize: 9, color: theme.textDim, letterSpacing: 1, lineHeight: 1.6 }}>
              <div>COURSE: <span style={{ color: theme.secondary, fontFamily: KANA_F }}>{open.course}</span></div>
              <div>WHEN: <span style={{ color: theme.text }}>{open.date}</span></div>
            </div>
            <PixelBtn theme={theme} small style={{ marginTop: 16, width: '100%' }} onClick={() => setOpen(null)}>CLOSE ✕</PixelBtn>
          </div>
        </div>
      )}
    </ScreenChrome>
  );
}

// ───── RESULTS ─────
function Results({ theme, result, state, onRestart, onHome }) {
  const score = computeScore(result);
  const isNewBest = score > (state.bestScore || 0);
  const rank = score >= 300 ? 'S' : score >= 200 ? 'A' : score >= 120 ? 'B' : score >= 60 ? 'C' : 'D';
  const rankColors = { S: theme.accent, A: theme.primary, B: theme.secondary, C: theme.textDim, D: theme.textDim };

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: theme.bg, color: theme.text, fontFamily: PIXEL,
      overflow: 'auto',
    }}>
      <CRTOverlay theme={theme} />
      <div style={{ position: 'relative', zIndex: 5, padding: '40px 16px 32px', textAlign: 'center' }}>
        <div style={{
          fontSize: 16, color: theme.primary, letterSpacing: 6, textShadow: `0 0 12px ${theme.primary}`,
        }}>★ TIME UP ★</div>
        <div style={{ fontFamily: KANA_F, fontSize: 12, color: theme.textDim, letterSpacing: 6, marginTop: 4 }}>じかん きれ</div>

        {isNewBest && (
          <div style={{
            marginTop: 16, fontSize: 11, color: theme.accent, letterSpacing: 3,
            animation: 'kt-pulse 1s infinite',
          }}>♕ NEW BEST SCORE ♕</div>
        )}

        {/* Big rank */}
        <div style={{
          margin: '32px auto', width: 110, height: 110,
          border: `5px solid ${rankColors[rank]}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 72, color: rankColors[rank], fontFamily: PIXEL,
          textShadow: `0 0 24px ${rankColors[rank]}`,
          boxShadow: `0 0 32px ${rankColors[rank]}, inset 0 0 24px ${rankColors[rank]}40`,
          background: 'rgba(0,0,0,0.4)',
        }}>{rank}</div>

        <div style={{ fontSize: 32, color: theme.accent, textShadow: `0 0 16px ${theme.accent}`, letterSpacing: 2 }}>
          {score} <span style={{ fontSize: 12, color: theme.textDim }}>PTS</span>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, margin: '24px 16px 0' }}>
          <StatBlock theme={theme} label="WPM" value={result.wpm} big />
          <StatBlock theme={theme} label="ACCURACY" value={`${result.acc}%`} big />
          <StatBlock theme={theme} label="MAX COMBO" value={result.combo} />
          <StatBlock theme={theme} label="WORDS" value={result.words} />
        </div>

        <div style={{ display: 'flex', gap: 12, justifyContent: 'center', marginTop: 28 }}>
          <PixelBtn theme={theme} primary onClick={onRestart}>↻ AGAIN</PixelBtn>
          <PixelBtn theme={theme} small onClick={onHome}>🏠 HOME</PixelBtn>
        </div>
      </div>
    </div>
  );
}

window.computeScore = computeScore;
window.Settings = Settings;
window.WordPacks = WordPacks;
window.Leaderboard = Leaderboard;
window.Results = Results;
