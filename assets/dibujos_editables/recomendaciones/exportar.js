// Pasa los SVG de esta carpeta a PNG 192x192 en assets/recomendaciones/.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
(async () => {
  const dest = path.join(__dirname, '../../recomendaciones');
  fs.mkdirSync(dest, { recursive: true });
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 96, height: 96 }, deviceScaleFactor: 2 });
  for (const f of fs.readdirSync(__dirname).filter((f) => f.endsWith('.svg'))) {
    const s = fs.readFileSync(path.join(__dirname, f), 'utf8');
    await p.setContent(`<html><body style="margin:0;background:transparent">${s}</body></html>`);
    await p.locator('svg').screenshot({ path: path.join(dest, f.replace('.svg', '.png')), omitBackground: true });
  }
  await b.close();
})();
