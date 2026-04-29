// Three retro-arcade themes.
const APP_THEMES = {
  arcade: {
    id: 'arcade',
    name: 'NEON',
    jp: 'ネオン',
    bg: '#0a0014',
    surface: '#1a0930',
    primary: '#ff2a8a',
    secondary: '#9d4edd',
    accent: '#ffd60a',
    text: '#fff5fb',
    textDim: '#a878b8',
    correct: '#39ff14',
    wrong: '#ff003c',
    grid: 'rgba(255, 42, 138, 0.08)',
  },
  matrix: {
    id: 'matrix',
    name: 'MATRIX',
    jp: 'マトリクス',
    bg: '#000800',
    surface: '#001a08',
    primary: '#00ff66',
    secondary: '#33cc55',
    accent: '#ccff00',
    text: '#d4ffd4',
    textDim: '#3d7a3d',
    correct: '#ccff00',
    wrong: '#ff3030',
    grid: 'rgba(0, 255, 102, 0.08)',
  },
  sunset: {
    id: 'sunset',
    name: 'SUNSET',
    jp: 'サンセット',
    bg: '#1a0a00',
    surface: '#2d1408',
    primary: '#ff6b1a',
    secondary: '#ff3d6e',
    accent: '#ffe600',
    text: '#fff0e0',
    textDim: '#a06544',
    correct: '#ffe600',
    wrong: '#ff003c',
    grid: 'rgba(255, 107, 26, 0.08)',
  },
};

// Storage helpers — namespaced to avoid collisions.
const KEY = 'kanaTyper.v1';
function loadState() {
  try {
    const s = localStorage.getItem(KEY);
    return s ? JSON.parse(s) : null;
  } catch (e) { return null; }
}
function saveState(state) {
  try { localStorage.setItem(KEY, JSON.stringify(state)); }
  catch (e) {}
}
function getDefaults() {
  return {
    name: '',
    onboarded: false,
    theme: 'arcade',
    duration: 30,        // seconds: 15/30/60
    pack: 'basic',
    difficulty: 'normal', // 'easy' | 'normal' | 'hard'
    sound: true,
    history: [],         // { date, wpm, acc, combo, words, time, course, score }
    bestScore: 0,
    bestWpm: 0,
  };
}

window.APP_THEMES = APP_THEMES;
window.loadState = loadState;
window.saveState = saveState;
window.getDefaults = getDefaults;
