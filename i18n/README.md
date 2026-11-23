# Interface languages

Every text of the interface lives here, one file per language: `en.json`,
`uk.json`, `cs.json`… `scripts/i18n.mjs` writes them where each plugin reads
them, so a new language or a fixed typo is one file and one command.

| Section       | Where it shows                                                        | Written to                                          |
|---------------|-----------------------------------------------------------------------|-----------------------------------------------------|
| `meta`        | the language's own name, number format, decimal separator, units      | every plugin and the core                           |
| `panel`       | the trail panel shared by VS Code and JetBrains IDEs                  | `ui/panel/panel.html`, between `// <i18n>` markers  |
| `vscode`      | VS Code notifications and pickers                                     | `plugins/vscode/src/i18n.catalog.ts`                |
| `commands`    | VS Code command titles in the Command Palette                         | `plugins/vscode/package.nls*.json`                  |
| `jetbrains`   | JetBrains dialogs, menus, notifications, the status bar               | `plugins/jetbrains/src/main/resources/i18n.json`    |
| `neovim`      | Neovim messages and pickers                                           | `plugins/neovim/lua/commit-hike/i18n.lua`           |
| `screenshots` | the words on the README and marketplace screenshots (`task screenshots`) | read by `ui/screenshots.mjs`                     |

The core gets the list of languages and their units in
`core/internal/i18n/languages.go`. All generated files are committed (the
Neovim plugin is installed straight from git) and must not be edited by hand.

## Add a language

```bash
task i18n:new CODE=cs      # i18n/cs.json, a copy of English with the plural forms of Czech
# translate every text and fill in meta
task i18n:check            # what's missing or wrong
task i18n                  # write the plugins' files
task check                 # everything else
```

Then, outside this folder:

- route texts: `core/content/routes/*/locales/<code>.json` and the series names
  in `core/content/series.json` (optional: they fall back to English;
  `task routes:check` checks them);
- the README: `docs/README.<code>.md` and its link in the language bar of
  the other READMEs;
- the screenshots: `task screenshots ARGS=<code>`.

## The rules `task i18n:check` enforces

- Every key of English, nothing more, in every section.
- The same placeholders as English: `{0}`, `{n}`, `{name}`… and `%s`, `%d`
  in the `neovim` section.
- Plural forms by the language's own rules (`kmWord`, `mWord`, `days`,
  `commitsN`). `task i18n:new` lists them with examples. They are the
  [Unicode CLDR forms](https://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html)
  that `Intl.PluralRules` uses, and their names don't mean the same in every
  language. In Czech `other` is 0 and 5 and more ("5 kilometrů") and `many`
  is for decimals ("8,4 kilometru"); in Polish and Ukrainian `many` is 5 and
  more.
- `meta.numberLocale` is a real locale: it decides how whole numbers are
  grouped (1,925 · 1 925 · 1.925 · 1925).

The language picker lists English first, then the other languages by code.
