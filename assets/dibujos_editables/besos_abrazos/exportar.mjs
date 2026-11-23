// Exporta los SVG de esta carpeta a PNG (1350x840, fondo transparente)
// en assets/animaciones/.   Uso: node exportar.mjs
import { createRequire } from "node:module";
import { readdirSync, readFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const { chromium } = createRequire(import.meta.url)("playwright");
const aqui = dirname(fileURLToPath(import.meta.url));
const destino = join(aqui, "..", "..", "animaciones");
mkdirSync(destino, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 900, height: 560 }, deviceScaleFactor: 1.5 });
// Los iconitos (96x96) salen a 192x192 (escala 2).
const iconos = await browser.newPage({ viewport: { width: 96, height: 96 }, deviceScaleFactor: 2 });
for (const f of readdirSync(aqui).filter((f) => f.endsWith(".svg"))) {
  const p = f.startsWith("icono_") ? iconos : page;
  await p.setContent(`<style>html,body{margin:0;background:transparent}</style>${readFileSync(join(aqui, f), "utf8")}`);
  await p.locator("svg").screenshot({ path: join(destino, f.replace(".svg", ".png")), omitBackground: true });
}
await browser.close();
