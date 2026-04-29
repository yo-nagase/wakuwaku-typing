// Shared UI primitives for the playable app.

const PIXEL = '"Press Start 2P", "Courier New", monospace';
const KANA_F = '"DotGothic16", "Hiragino Kaku Gothic Std", monospace';

function CRTOverlay({ theme }) {
  return (
    <>
      {/* Scanlines */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'repeating-linear-gradient(to bottom, transparent 0, transparent 2px, rgba(0,0,0,0.18) 2px, rgba(0,0,0,0.18) 3px)',
        zIndex: 100,
      }} />
      {/* Vignette */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `radial-gradient(ellipse at center, transparent 50%, ${theme.bg} 100%)`,
        zIndex: 99,
      }} />
      {/* Grid bg */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        backgroundImage: `linear-gradient(${theme.grid} 1px, transparent 1px), linear-gradient(90deg, ${theme.grid} 1px, transparent 1px)`,
        backgroundSize: '24px 24px',
        zIndex: 1,
      }} />
    </>
  );
}

function PixelBtn({ theme, children, onClick, primary, small, style, ...rest }) {
  const [hover, setHover] = React.useState(false);
  const [active, setActive] = React.useState(false);
  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => { setHover(false); setActive(false); }}
      onMouseDown={() => setActive(true)}
      onMouseUp={() => setActive(false)}
      onTouchStart={() => setActive(true)}
      onTouchEnd={() => setActive(false)}
      style={{
        background: primary ? theme.primary : 'transparent',
        color: primary ? '#000' : theme.text,
        border: `3px solid ${theme.primary}`,
        padding: small ? '8px 14px' : '14px 24px',
        fontFamily: PIXEL,
        fontSize: small ? 10 : 12,
        letterSpacing: 1,
        cursor: 'pointer',
        boxShadow: active
          ? `0 0 0 ${theme.primary}`
          : (hover
            ? `0 0 16px ${theme.primary}, 6px 6px 0 ${theme.primary}80`
            : `4px 4px 0 ${theme.primary}80`),
        transform: active ? 'translate(2px, 2px)' : 'translate(0, 0)',
        transition: 'transform 60ms, box-shadow 60ms',
        userSelect: 'none',
        WebkitTapHighlightColor: 'transparent',
        ...style,
      }}
      {...rest}
    >{children}</button>
  );
}

function PixelPanel({ theme, children, style }) {
  return (
    <div style={{
      background: 'rgba(0,0,0,0.4)',
      border: `2px solid ${theme.primary}`,
      padding: 16,
      boxShadow: `inset 0 0 20px ${theme.primary}30, 4px 4px 0 ${theme.primary}80`,
      ...style,
    }}>{children}</div>
  );
}

function StatBlock({ theme, label, value, big }) {
  return (
    <div style={{
      flex: 1, padding: '10px 8px', textAlign: 'center',
      border: `1px solid ${theme.textDim}`,
      background: 'rgba(0,0,0,0.3)',
    }}>
      <div style={{ fontSize: 8, color: theme.textDim, letterSpacing: 2 }}>{label}</div>
      <div style={{
        fontSize: big ? 24 : 16, color: theme.accent, marginTop: 4,
        textShadow: `0 0 8px ${theme.accent}`, letterSpacing: 1, fontFamily: PIXEL,
      }}>{value}</div>
    </div>
  );
}

// Sit-still pixel mascot (8-color palette, drawn from a string grid)
function PixelMascot({ theme, mood = 'idle', size = 8 }) {
  const sprites = {
    idle: [
      '...XXXX...',
      '..XXXXXX..',
      '..XOOOXX..',  // O = eyes
      '..XOOOXX..',
      '..XXXXXX..',
      '..XXMMXX..',  // M = mouth
      '.XXXXXXXX.',
      'X.XXXXXX.X',
      'X.X....X.X',
      '...XXXX...',
    ],
    happy: [
      '...XXXX...',
      '..XXXXXX..',
      '..X.X.XX..',
      '..XXXXXX..',
      '..XMMMMX..',
      '.XXMMMMXX.',
      'X.XXXXXX.X',
      '...XXXX...',
      '...X..X...',
      '...X..X...',
    ],
  };
  const grid = sprites[mood] || sprites.idle;
  return (
    <div style={{ display: 'inline-grid', gridTemplateColumns: `repeat(10, ${size}px)`, gap: 0 }}>
      {grid.flatMap((row, r) => row.split('').map((cell, c) => (
        <div key={`${r}-${c}`} style={{
          width: size, height: size,
          background: cell === 'X' ? theme.primary
            : cell === 'O' ? '#000'
            : cell === 'M' ? theme.accent
            : 'transparent',
          boxShadow: cell === 'X' ? `0 0 4px ${theme.primary}` : 'none',
        }} />
      )))}
    </div>
  );
}

window.PIXEL = PIXEL;
window.KANA_F = KANA_F;
window.CRTOverlay = CRTOverlay;
window.PixelBtn = PixelBtn;
window.PixelPanel = PixelPanel;
window.StatBlock = StatBlock;
window.PixelMascot = PixelMascot;
