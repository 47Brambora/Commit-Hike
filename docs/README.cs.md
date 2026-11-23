# Commit Hike

[![JetBrains Plugin](https://img.shields.io/jetbrains/plugin/v/34595?label=JetBrains&logo=jetbrains)](https://plugins.jetbrains.com/plugin/34595)
[![JetBrains Downloads](https://img.shields.io/jetbrains/plugin/d/34595?label=downloads)](https://plugins.jetbrains.com/plugin/34595)
[![Open VSX](https://img.shields.io/open-vsx/v/shchusia/commit-hike?label=Open%20VSX&logo=eclipseide)](https://open-vsx.org/extension/shchusia/commit-hike)
[![Open VSX Downloads](https://img.shields.io/open-vsx/dt/shchusia/commit-hike?label=downloads)](https://open-vsx.org/extension/shchusia/commit-hike)
[![GitHub stars](https://img.shields.io/github/stars/Shchusia/Commit-Hike?style=flat&logo=github)](https://github.com/Shchusia/Commit-Hike)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](../LICENSE)

*[English](../README.md) · [Українська](README.uk.md) · [Polski](README.pl.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Čeština](README.cs.md) · [Co je nového](../CHANGELOG.md)*

Každý tvůj commit tě posune po turistické stezce přímo v IDE.
Den poctivé práce tě zavede asi deset kilometrů po skutečném horském hřebeni, pouští nebo pohádkou, se scénou, která se cestou mění, mapou, příběhy, zajímavostmi a úspěchy.

<p>
  <img src="https://raw.githubusercontent.com/Shchusia/Commit-Hike/master/docs/screenshots/cs-hike.png" width="49%" alt="Túra: pohled na trasu z boku">
  <img src="https://raw.githubusercontent.com/Shchusia/Commit-Hike/master/docs/screenshots/cs-map.png" width="49%" alt="Mapa: skutečná GPS stopa po hřebeni Čornohory">
</p>
<p>
  <img src="https://raw.githubusercontent.com/Shchusia/Commit-Hike/master/docs/screenshots/cs-places.png" width="49%" alt="Místa: ke každé zastávce se váže příběh">
  <img src="https://raw.githubusercontent.com/Shchusia/Commit-Hike/master/docs/screenshots/cs-stats.png" width="49%" alt="Statistiky: nepřetržitá řada, denní vzdálenost a úspěchy">
</p>

## Vlastnosti

- **Skutečné, příběhové, ale i uživatelské trasy:** Přes Čornohorský hřeben, který se táhne přes Hoverlu. Nebo přes novozélandský Tongariro Alpine Crossing, který je stejný jako v realitě díky GPS. Či dokonce Španělskem, Marokem, Saharou, Egyptem, které se všechny zakládají na skutečném mapovém podkladu. Nebo pokud budete chtít tak se můžete vydat pohádkovými Karpaty a nebo na fantazii cestu okolo sedmi majáků.  
  Každá trasa má své vlastní zastávky, příběh, fakta, zajímavosti a úspěchy.  
- **Trasy z webu přístupné v IDE:** Najdi trasy které vytvořil někdo jiný na [commit-hike.dev](https://commit-hike.dev) přímo v IDE:  
  - vyhledávání, filtry, přebaly, hodnocení  
  - instalace a aktualizace na jedno kliknutí v IDE  
  - Instalace a aktualizace v Neovimu: `:CommitHike find`  
- **Několik jazyků na výběr:** Čeština, angličtina, ukrajinština, polština, němčina, španělština  
  Výběr je automatický dle IDE a nebo manuálním výběrem
- **Pokračující trasy:** Když dokončíš trasu, tak cesta nekončí, můžeš v ní pokračovat dále.  
  např.: (`Čornohora` → `Svidovec` → `Gorgany`) nebo (`Tour du Mont Blanc` → `Camino Francés do Santiaga`).  
- **Reálné převýšení:** Trasy mají reálný výškový profil (klesání/stoupání)
  v IDE vidíme nastoupané metry, nadmořskou výšku, sklon a stoupání k další zastávce
- **Reálné prostředí:** Obloha se řídí časem na tvém zařízení.  
  Počasí se mění každý den  
  Prostředí přechází mezi sebou plynule (lesy, louky, step, poušť, skály, jezera,...)  
  Roční období (V zimě sníh, na podzim krásně zbarvená krajina)  
  Když nepřijde ten den commit, tak se zastavíš a rozděláš oheň a odpočíváš  
- **Mapa a minimapa:** Topografická mapa celé trasy: (Vrstevnice, lesy, louky, jezera,...)  
  Skutečné trasy dle GPS souřadnic

- **Mapa a minimapa:** Topografická mapa celé stezky: vrstevnice, stínování, lesy a jezera; skutečné trasy podle GPS stopy ve skutečném měřítku.
- **Skutečné vzdálenosti, tvoje obtížnost:** Typický den commitů je asi 10 km na střední obtížnost (12,5 na lehkou, 8 na těžkou), takže dlouhá trasa je cíl na měsíce.
- **Bez spoilerů:** Cestu, kterou máš za sebou, si můžeš prohlédnout, ale co leží před tebou, uvidíš až ve chvíli, kdy se tam dostaneš.
- **Rok na stezce a pas:** Kalendář aktivity, nejlepší den, nejdelší série a v pasu razítko s datem za každou zastávku.
- **Sdílej:** Pohlednice z místa, kde právě jsi: ulož ji, zkopíruj nebo zveřejni na X, Bluesky, Mastodonu, Threads, LinkedInu, Facebooku, Telegramu nebo Redditu s připraveným textem.
- **I v terminálu:** Jeden řádek ve výzvě shellu (starship, bash, zsh, fish) a ve stavovém řádku Neovimu, ze stejného jádra: `🥾 16,0 km · Jezero Nesamovyte`.
- **Choďte spolu:** Všichni, kdo commitují do projektu, na jedné stezce, s žebříčkem, přehledem týdne a týmovým cílem: trasou, kterou jdete společně a na které se sčítají commity všech.
- **Férová vzdálenost:** Metry rostou s velikostí commitu, od pár kroků za jednořádkovou opravu po skoro 4 km za velkou změnu, a rychleji než asi 5 km za hodinu nepůjdeš: drobné commity ani commity v dávkách nic nepřinesou, zatímco dlouhý pracovní den se počítá celý, pozdní commity taky. Lock soubory, generovaný kód, změny jen v mezerách a cizí commity se nepočítají; po squash, rebase nebo amend se historie přepočítá, nikdy se nepočítá dvakrát.
- **Soukromí na prvním místě:** Nic se nezapisuje do tvých repozitářů a nic o tobě neopouští tvůj počítač: jediné požadavky jdou na [commit-hike.dev](https://commit-hike.dev), když otevřeš *Trasy z webu* nebo instaluješ trasu, a čtou veřejný katalog, aniž by o tobě cokoli posílaly. Neukládáme kód, zprávy commitů, názvy souborů ani repozitářů.

## Podporovaná IDE

| IDE | Kde získat |
|---|---|
| IDE JetBrains 2024.3+: PyCharm, IntelliJ IDEA, GoLand, WebStorm, PhpStorm, RubyMine, CLion, Rider… | [JetBrains Marketplace](https://plugins.jetbrains.com/plugin/34595) |
| VSCodium, Cursor, Windsurf a další editory, které používají Open VSX | [Open VSX](https://open-vsx.org/extension/shchusia/commit-hike) |
| VS Code 1.85+ | brzy ve Visual Studio Marketplace; do té doby nainstaluj `.vsix` z Open VSX |
| Neovim 0.10+ a libovolná výzva shellu: starship, bash, zsh, fish | [commit-hike.nvim](https://github.com/Shchusia/commit-hike.nvim), [docs/terminal.md](terminal.md) |
| Zed | přes jeho terminál, viz [docs/terminal.md](terminal.md#zed) |

## Instalace

**IDE JetBrains.** Otevři **Settings → Plugins → Marketplace**, vyhledej
*Commit Hike* a klikni na **Install**.

**VSCodium, Cursor, Windsurf.** Otevři zobrazení rozšíření, vyhledej
*Commit Hike* a klikni na **Install**.

**VS Code.** Dokud Commit Hike není ve Visual Studio Marketplace, stáhni
`.vsix` ze [stránky Open VSX](https://open-vsx.org/extension/shchusia/commit-hike)
(**Download**) a pak ve VS Code: zobrazení rozšíření, **⋯ → Install from VSIX…**.

**Terminál a Neovim.** Nainstaluj jádro jedním příkazem a pak ho přidej do
výzvy shellu nebo do stavového řádku, viz [docs/terminal.md](terminal.md):

```sh
curl -fsSL https://raw.githubusercontent.com/Shchusia/Commit-Hike/master/scripts/install.sh | sh
```

V Neovimu 0.10+ s lazy.nvim, a pak přidej `require("commit-hike").statusline` do stavového řádku:

```lua
{ "Shchusia/commit-hike.nvim", version = "*", opts = {} }
```

## Jak na to

Otevři okno **Commit Hike** (JetBrains) nebo zobrazení Commit Hike na panelu
aktivit (VS Code). Napoprvé se tě krátké nastavení zeptá, které projekty se
počítají a odkud cesta začíná. Pak už jen commituj.

Karty: **Túra** (scéna, dnešní vzdálenost, příběh místa), **Mapa**,
**Místa**, **Tým** a **Statistiky**. Všechno ostatní — výběr trasy, vlastní
trasy, ikonu turisty, obtížnost, jazyk — najdeš v **Tools → Commit Hike**
(JetBrains) nebo v paletě příkazů pod *Commit Hike* (VS Code).

**↗ Sdílet** pod túrou (a na pohlednici roku ve statistikách) uloží nebo
zkopíruje pohlednici, nebo otevře příspěvek s připraveným textem; pohlednice
už je ve schránce, stačí ji vložit.

<p><img src="https://raw.githubusercontent.com/Shchusia/Commit-Hike/master/docs/screenshots/cs-share.png" width="49%" alt="Nabídka Sdílet: ulož, zkopíruj nebo zveřejni pohlednici"></p>

## Pro vývojáře

Sestavení, testy, vydání, architektura a přidávání tras jsou popsané v
[anglickém README](../README.md#development) a v [docs/](./). Překlady tras
a rozhraní jsou vítány: viz [docs/routes.md](routes.md).
Vydání, včetně pluginu pro Neovim, popisuje [docs/publishing.md](publishing.md).

## Podpoř projekt

Commit Hike je zdarma a open source. Jestli tě ta túra baví:

- ⭐ dej repozitáři hvězdičku — pomůže to ostatním ho najít;
- ohodnoť plugin na [JetBrains Marketplace](https://plugins.jetbrains.com/plugin/34595) nebo [Open VSX](https://open-vsx.org/extension/shchusia/commit-hike/reviews);
- hlas chyby a nápady v [issues](https://github.com/Shchusia/Commit-Hike/issues);
- vytvoř trasu a poděl se o ni: viz [docs/routes.md](routes.md).

## Licence

[MIT](../LICENSE)
