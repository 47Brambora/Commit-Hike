// The screenshots of the READMEs and the marketplace pages, made from the real
// panel with data from the real core (the same fixtures as the tests):
//
//   task screenshots          → docs/screenshots/<lang>-<shot>.png, 1280×800
//
// Every picture is a frame: a headline on the left, the panel on the right.
// Change the words below, run the task, commit the pictures.
import { chromium } from "@playwright/test";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { browserPath } from "./test/browser.mjs";
import setupFixtures, { FIXTURES, LANGUAGES } from "./test/fixtures.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(here, "..", "docs", "screenshots");
const PANEL = fs.readFileSync(path.join(here, "panel", "panel.html"), "utf8")
  .replace("{{CSP}}", "default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-shot'; img-src data:")
  .replace(/\{\{NONCE\}\}/g, "shot");

// The words of each language come from the screenshots section of
// i18n/<lang>.json; *word* is drawn in the trail colour.
const words = l => JSON.parse(fs.readFileSync(path.join(here, "..", "i18n", `${l}.json`), "utf8")).screenshots;
const COPY = Object.fromEntries(LANGUAGES.map(l => [l, Object.fromEntries(Object.entries(words(l)).map(([k, v]) => [k, [v.title, v.text]]))]));
const SHOTS = { hike: 0, map: 1, places: 2, stats: 4, share: 0 }; // tab index

const PW = 404, PH = 700; // the panel, in CSS pixels

async function panelPicture(page, lang, shot) {
  const status = JSON.parse(fs.readFileSync(path.join(FIXTURES, `status-${lang}.json`), "utf8"));
  await page.setViewportSize({ width: PW, height: PH });
  await page.clock.setFixedTime(new Date("2026-09-28T13:00:00Z"));
  await page.setContent(PANEL);
  await page.evaluate(() => { window.commitHikeHost = { send: () => {} }; });
  await page.evaluate(d => window.commitHike.update(d), {
    type: "update", state: "ok", repo: "/work/repo", locale: lang, status, build: { version: "0.7.0", flavor: "prod" },
  });
  if (SHOTS[shot]) await page.getByRole("tab").nth(SHOTS[shot]).click();
  await page.waitForTimeout(900); // the scene, the map tiles and the pictures settle
  if (shot === "share") {
    const btn = page.locator(".hike-actions .share");
    await btn.scrollIntoViewIfNeeded();
    await btn.click();
    await page.locator(".share-wrap .menu").evaluate(m => m.scrollIntoView({ block: "end" }));
    await page.waitForTimeout(200);
  }
  return (await page.screenshot({ type: "png" })).toString("base64");
}

function frameHtml(lang, shot, panelPng) {
  const [title, sub] = COPY[lang][shot];
  const t = title.replace(/\*([^*]+)\*/, '<em>$1</em>');
  return `<!DOCTYPE html><html lang="${lang}"><head><meta charset="utf-8"><style>
  * { box-sizing: border-box; margin: 0; }
  body { width: 1280px; height: 800px; overflow: hidden; font-family: "DejaVu Sans", "Noto Sans", system-ui, sans-serif;
    background: radial-gradient(1200px 700px at 30% 40%, #262b2f, #16191b); color: #ece8de; position: relative; }
  svg.contours { position: absolute; inset: 0; }
  .brand { position: absolute; left: 92px; top: 76px; font-weight: 700; font-size: 21px; display: flex; gap: 12px; align-items: center; }
  .brand i { width: 8px; height: 26px; background: #e8b53d; border-radius: 2px; }
  .copy { position: absolute; left: 92px; top: 205px; width: 560px; display: flex; flex-direction: column; gap: 34px; }
  h1 { font-size: 52px; line-height: 1.1; font-weight: 800; letter-spacing: -0.5px; }
  h1 em { font-style: normal; color: #e8b53d; }
  p { width: 500px; font-size: 21px; line-height: 1.5; color: #aab1b3; }
  .win { position: absolute; right: 92px; top: 40px; width: ${PW + 18}px; height: 720px; border-radius: 12px; overflow: hidden;
    background: #1e2124; box-shadow: 0 24px 60px rgba(0,0,0,.55), 0 0 0 1px rgba(255,255,255,.06); }
  .win .bar { height: 32px; padding: 9px 14px; font-size: 13px; color: #9aa1a4; border-bottom: 1px solid rgba(255,255,255,.06); }
  .win img { display: block; width: ${PW}px; height: ${PH}px; margin: 0 9px; }
  </style></head><body>
  <svg class="contours" viewBox="0 0 1280 800">${Array.from({ length: 14 }, (_, k) =>
    `<ellipse cx="${300 + k * 4}" cy="${420 - k * 3}" rx="${120 + k * 70}" ry="${80 + k * 48}" fill="none" stroke="rgba(255,255,255,.035)"/>`).join("")}</svg>
  <div class="brand"><i></i>Commit Hike</div>
  <div class="copy"><h1>${t}</h1><p>${sub}</p></div>
  <div class="win"><div class="bar">Commit Hike</div><img src="data:image/png;base64,${panelPng}" alt=""></div>
  </body></html>`;
}

const only = process.argv[2]; // e.g. "uk" or "uk-map"
setupFixtures();
fs.mkdirSync(OUT, { recursive: true });
const browser = await chromium.launch({ executablePath: browserPath() || undefined });
try {
  const panel = await browser.newPage({ deviceScaleFactor: 2, timezoneId: "UTC", locale: "en-US" });
  const frame = await browser.newPage({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 });
  for (const lang of Object.keys(COPY)) {
    for (const shot of Object.keys(SHOTS)) {
      const name = `${lang}-${shot}`;
      if (only && name !== only && lang !== only) continue;
      const png = await panelPicture(panel, lang, shot);
      await frame.setContent(frameHtml(lang, shot, png));
      await frame.waitForTimeout(100);
      await frame.screenshot({ path: path.join(OUT, `${name}.png`) });
      console.log("docs/screenshots/" + name + ".png");
    }
  }
} finally {
  await browser.close();
}
