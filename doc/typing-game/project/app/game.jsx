// Game engine: handles real-time keyboard input, romaji→kana matching,
// timer, WPM/accuracy/combo tracking, and particle bursts.

const STARS = ['Z', 'X', '*', '+', '·'];

function GameScreen({ theme, settings, onEnd, onExit }) {
  const pack = PACKS.find(p => p.id === settings.pack) || PACKS[0];
  const isKata = pack.katakana;

  const [target, setTarget] = React.useState(() => randWord(pack.entries));
  const [buf, setBuf] = React.useState('');           // romaji typed for current kana progress
  const [done, setDone] = React.useState('');          // hiragana already completed in current word
  const [time, setTime] = React.useState(settings.duration);
  const [stats, setStats] = React.useState({ correctChars: 0, wrongChars: 0, words: 0, combo: 0, maxCombo: 0 });
  const [particles, setParticles] = React.useState([]);
  const [shake, setShake] = React.useState(0);
  const [paused, setPaused] = React.useState(false);
  const [started, setStarted] = React.useState(false);
  const inputRef = React.useRef(null);
  const wrongFlash = React.useRef(0);
  const [, force] = React.useReducer(x => x + 1, 0);

  // Target as romaji
  const targetRomaji = React.useMemo(() => hiraToRomaji(target), [target]);
  const doneRomaji = React.useMemo(() => hiraToRomaji(done), [done]);
  // Remaining romaji (what user still needs to type for current word)
  const remainingRomaji = targetRomaji.slice(doneRomaji.length);

  function randWord(list) {
    return list[Math.floor(Math.random() * list.length)];
  }

  // Timer
  React.useEffect(() => {
    if (!started || paused) return;
    if (time <= 0) {
      onEnd({
        wpm: Math.round((stats.words / settings.duration) * 60),
        acc: stats.correctChars + stats.wrongChars > 0
          ? Math.round((stats.correctChars / (stats.correctChars + stats.wrongChars)) * 100)
          : 100,
        combo: stats.maxCombo,
        words: stats.words,
        time: settings.duration,
        course: `${pack.jp} / ${settings.duration}s`,
      });
      return;
    }
    const t = setTimeout(() => setTime(t => t - 1), 1000);
    return () => clearTimeout(t);
  }, [time, started, paused]);

  // Keyboard handler
  React.useEffect(() => {
    function onKey(e) {
      if (paused) return;
      if (e.key === 'Escape') { setPaused(true); return; }
      if (!/^[a-zA-Z\-,.?!]$/.test(e.key)) return;
      e.preventDefault();
      if (!started) setStarted(true);
      handleChar(e.key.toLowerCase());
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [target, buf, done, paused, started]);

  // Mobile: hidden input drives onInput so iOS keyboard works
  React.useEffect(() => {
    if (inputRef.current) inputRef.current.focus();
  }, []);

  function handleChar(ch) {
    const newBuf = buf + ch;
    // What kana would the next char of remainingRomaji require?
    const expected = remainingRomaji;
    if (!expected) return;

    // Find a matching romaji in ROMAJI_MAP that prefixes the remaining target.
    // Try lengths 4..1 to greedily match digraph romaji.
    let matched = null;
    for (let len = 4; len >= 1; len--) {
      const cand = newBuf.slice(-len);
      const hira = ROMAJI_MAP[cand];
      if (hira && expected.startsWith(hiraToRomaji(hira))) {
        matched = { romaji: cand, hira };
        break;
      }
    }

    if (matched) {
      // Successful kana — accumulate
      const newDone = done + matched.hira;
      setDone(newDone);
      setBuf('');
      setStats(s => ({
        ...s,
        correctChars: s.correctChars + matched.romaji.length,
        combo: s.combo + 1,
        maxCombo: Math.max(s.maxCombo, s.combo + 1),
      }));
      spawnParticles();

      if (newDone === target) {
        // Word complete
        setStats(s => ({ ...s, words: s.words + 1 }));
        // Big burst
        spawnParticles(20);
        setTimeout(() => {
          setDone('');
          setBuf('');
          setTarget(randWord(pack.entries));
        }, 120);
      }
      return;
    }

    // Could the buffer still be a partial prefix of any valid kana? If yes, keep waiting.
    const couldExtend = Object.keys(ROMAJI_MAP).some(r => r.startsWith(newBuf) && expected.startsWith(hiraToRomaji(ROMAJI_MAP[r])));
    if (couldExtend) {
      setBuf(newBuf);
    } else {
      // Wrong input
      setStats(s => ({ ...s, wrongChars: s.wrongChars + 1, combo: 0 }));
      setShake(s => s + 1);
      wrongFlash.current = Date.now();
      setBuf('');
      force();
    }
  }

  function spawnParticles(n = 8) {
    const id = Date.now() + Math.random();
    const ps = Array.from({ length: n }, (_, i) => ({
      id: id + i,
      x: 50 + (Math.random() - 0.5) * 30,
      y: 50 + (Math.random() - 0.5) * 10,
      vx: (Math.random() - 0.5) * 4,
      vy: -2 - Math.random() * 2,
      char: STARS[Math.floor(Math.random() * STARS.length)],
      color: [theme.primary, theme.accent, theme.secondary][Math.floor(Math.random() * 3)],
      ttl: 30 + Math.random() * 20,
    }));
    setParticles(p => [...p, ...ps]);
    setTimeout(() => setParticles(p => p.filter(x => !ps.find(np => np.id === x.id))), 1000);
  }

  // Shake animation
  const shakeStyle = shake ? {
    animation: 'kt-shake 0.18s',
  } : {};

  // Live WPM
  const elapsed = Math.max(1, settings.duration - time);
  const liveWpm = Math.round((stats.words / elapsed) * 60);
  const totalChars = stats.correctChars + stats.wrongChars;
  const liveAcc = totalChars > 0 ? Math.round((stats.correctChars / totalChars) * 100) : 100;

  // Render the word with done/remaining hiragana split
  const displayWord = isKata ? hiraToKata(target) : target;
  const displayDone = isKata ? hiraToKata(done) : done;

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative',
      background: theme.bg, color: theme.text, fontFamily: PIXEL,
      overflow: 'hidden',
      ...shakeStyle,
    }}>
      <style>{`
        @keyframes kt-shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-6px); }
          75% { transform: translateX(6px); }
        }
        @keyframes kt-pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
      `}</style>
      <CRTOverlay theme={theme} />

      {/* Hidden input — only used to summon the iOS keyboard on mobile.
          On desktop, the global keydown handler does the work. */}
      <input
        ref={inputRef}
        autoFocus
        autoCapitalize="off"
        autoCorrect="off"
        spellCheck="false"
        inputMode="latin"
        value=""
        onChange={e => {
          const v = e.target.value;
          if (v) {
            for (const ch of v) {
              if (/^[a-zA-Z\-,.?!]$/.test(ch)) {
                if (!started) setStarted(true);
                handleChar(ch.toLowerCase());
              }
            }
            e.target.value = '';
          }
        }}
        style={{
          position: 'absolute', opacity: 0, height: 1, width: 1,
          border: 0, padding: 0, top: '50%', left: '50%',
        }}
      />

      {/* HUD */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, padding: '16px 16px 12px',
        display: 'flex', gap: 8, zIndex: 10,
        background: `linear-gradient(180deg, ${theme.bg}, transparent)`,
      }}>
        <button onClick={onExit} style={{
          width: 36, height: 36, background: 'transparent',
          border: `2px solid ${theme.primary}`, color: theme.text,
          fontFamily: PIXEL, fontSize: 14, cursor: 'pointer',
        }}>✕</button>
        <StatBlock theme={theme} label="TIME" value={`${time}s`} big />
        <StatBlock theme={theme} label="WPM" value={liveWpm} big />
        <StatBlock theme={theme} label="ACC" value={`${liveAcc}%`} big />
        <button onClick={() => setPaused(p => !p)} style={{
          width: 36, height: 36, background: 'transparent',
          border: `2px solid ${theme.primary}`, color: theme.text,
          fontFamily: PIXEL, fontSize: 12, cursor: 'pointer',
        }}>{paused ? '▶' : '‖'}</button>
      </div>

      {/* Combo */}
      {stats.combo > 2 && (
        <div style={{
          position: 'absolute', top: 96, left: '50%', transform: 'translateX(-50%)',
          fontSize: 14, letterSpacing: 2, color: theme.accent, zIndex: 10,
          textShadow: `0 0 12px ${theme.accent}`,
        }}>
          ★ COMBO ×{stats.combo}
        </div>
      )}

      {/* Word */}
      <div style={{
        position: 'absolute', inset: 0, display: 'flex',
        alignItems: 'center', justifyContent: 'center', flexDirection: 'column',
        padding: '0 24px', zIndex: 5,
      }}>
        <div style={{
          fontSize: 9, color: theme.textDim, letterSpacing: 4, marginBottom: 16,
        }}>
          {started ? '▼ TYPE THIS ▼' : '▶ START TYPING TO BEGIN'}
        </div>
        <div style={{
          fontFamily: KANA_F, fontSize: 'clamp(48px, 12vw, 80px)', letterSpacing: 4,
          textShadow: `0 0 24px ${theme.primary}`, marginBottom: 24, lineHeight: 1.1,
          textAlign: 'center', minHeight: 90,
        }}>
          <span style={{ color: theme.correct, opacity: 0.6 }}>{displayDone}</span>
          <span style={{ color: theme.text }}>{displayWord.slice(displayDone.length)}</span>
        </div>

        {/* Romaji hint (helpful for learners) */}
        <div style={{
          fontSize: 14, letterSpacing: 3, color: theme.textDim, marginBottom: 16,
          fontFamily: PIXEL,
        }}>
          <span style={{ color: theme.correct, opacity: 0.7 }}>{doneRomaji}</span>
          <span style={{ color: theme.accent }}>{buf}</span>
          <span style={{ color: theme.textDim }}>{remainingRomaji.slice(buf.length)}</span>
        </div>

        {/* Progress bar */}
        <div style={{
          width: 'min(80%, 320px)', height: 8, background: 'rgba(0,0,0,0.5)',
          border: `1px solid ${theme.textDim}`, marginBottom: 12,
        }}>
          <div style={{
            height: '100%',
            width: `${(time / settings.duration) * 100}%`,
            background: time < 10 ? theme.wrong : theme.primary,
            transition: 'width 0.5s linear, background 0.2s',
            boxShadow: `0 0 8px currentColor`,
          }} />
        </div>

        <div style={{ fontSize: 9, color: theme.textDim, letterSpacing: 2 }}>
          WORDS·{stats.words}  ·  COMBO·{stats.combo}/{stats.maxCombo}
        </div>
      </div>

      {/* Particles */}
      {particles.map(p => (
        <div key={p.id} style={{
          position: 'absolute', left: `${p.x}%`, top: `${p.y}%`,
          color: p.color, fontFamily: PIXEL, fontSize: 18, zIndex: 8,
          textShadow: `0 0 6px currentColor`, pointerEvents: 'none',
          animation: 'kt-rise 0.8s ease-out forwards',
        }}>{p.char}</div>
      ))}
      <style>{`
        @keyframes kt-rise {
          0% { transform: translate(-50%, -50%) scale(1); opacity: 1; }
          100% { transform: translate(-50%, -200%) scale(0.6); opacity: 0; }
        }
      `}</style>

      {/* Pause overlay */}
      {paused && (
        <div style={{
          position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.85)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexDirection: 'column', gap: 16, zIndex: 50,
        }}>
          <div style={{ fontSize: 24, color: theme.accent, letterSpacing: 4 }}>‖ PAUSED</div>
          <PixelBtn theme={theme} primary onClick={() => setPaused(false)}>▶ RESUME</PixelBtn>
          <PixelBtn theme={theme} small onClick={onExit}>✕ QUIT</PixelBtn>
        </div>
      )}
    </div>
  );
}

window.GameScreen = GameScreen;
