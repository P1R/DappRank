// Theme management — persists the user's choice and applies it to <html data-theme>.
// The palettes themselves live in `src/app.css` under `:root[data-theme="..."]`.

const STORAGE_KEY = "dapprank-theme";

/** @type {{ id: string; label: string }[]} */
export const themes = [
  { id: "original", label: "Neon" },
  { id: "light", label: "Light" },
  { id: "dark", label: "Dark" },
];

export const currentTheme = $state({ id: "original" });

function applyTheme(/** @type {string} */ id) {
  currentTheme.id = id;
  if (typeof document !== "undefined") {
    document.documentElement.dataset.theme = id;
  }
  try {
    localStorage.setItem(STORAGE_KEY, id);
  } catch {
    // Ignore storage errors (e.g. private browsing).
  }
}

/** @param {string} id */
export function setTheme(id) {
  if (themes.some((t) => t.id === id)) {
    applyTheme(id);
  }
}

// Apply the saved preference once at import time, before the first paint.
if (typeof window !== "undefined") {
  let saved = "original";
  try {
    saved = localStorage.getItem(STORAGE_KEY) || "original";
  } catch {
    saved = "original";
  }
  applyTheme(saved);
}
