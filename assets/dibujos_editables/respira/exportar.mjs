// Exporta los SVG de esta carpeta a PNG (1350x840, fondo transparente)
// en assets/images/.   Uso: node exportar.mjs
import { createRequire } from "node:module";
import { readdirSync, readFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const { chromium } = createRequire(import.meta.url)("playwright");
const aqui = dirname(fileURLToPath(import.meta.url));
const destino = join(aqui, "..", "..", "images");
mkdirSync(destino, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 900, height: 560 }, deviceScaleFactor: 1.5 });
for (const f of readdirSync(aqui).filter((f) => f.endsWith(".svg"))) {
  await page.setContent(`<style>html,body{margin:0;background:transparent}</style>${readFileSync(join(aqui, f), "utf8")}`);
  await page.locator("svg").screenshot({ path: join(destino, f.replace(".svg", ".png")), omitBackground: true });
}
await browser.close();
