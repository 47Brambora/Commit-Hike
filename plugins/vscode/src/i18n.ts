// Plugin messages (notifications, pickers). The language follows the core's
// setting (Commit Hike menu → Language), else the editor's display language.
// Command titles in the Command Palette come from package.nls*.json and follow
// VS Code's own display language. Both are generated from i18n/<lang>.json.
import { catalogs, UNITS, type Key } from "./i18n.catalog";

export { catalogs, LANGUAGES, LANGUAGE_NAMES } from "./i18n.catalog";

const en = catalogs.en;
let current: Record<Key, string> = en;
let currentLang = "en";

export function setLanguage(tag: string | undefined): void {
  const base = (tag || "en").toLowerCase().split(/[-_]/)[0];
  currentLang = catalogs[base] ? base : "en";
  current = catalogs[currentLang];
}
export function language(): string { return currentLang; }

export function t(key: Key, ...args: (string | number)[]): string {
  return (current[key] ?? en[key]).replace(/\{(\d)}/g, (_, i: string) => String(args[Number(i)] ?? ""));
}

export function formatDistanceL(m: number): string {
  const unit = UNITS[currentLang] ?? UNITS.en;
  if (m < 1000) return `${Math.round(m)} ${unit.m}`;
  const km = m / 1000;
  return `${km < 100 ? km.toFixed(1).replace(".", unit.decimal) : Math.round(km)} ${unit.km}`;
}
