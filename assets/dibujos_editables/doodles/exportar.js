// Pasa cada SVG de esta carpeta a PNG 192x192 con fondo transparente
// en assets/doodles/. Uso: node exportar.js
const {chromium} = require('playwright');
const fs = require('fs'), path = require('path');
(async () => {
  const salida = path.join(__dirname, '..', '..', 'doodles');
  fs.mkdirSync(salida, {recursive: true});
  const b = await chromium.launch();
  const p = await b.newPage({viewport: {width: 96, height: 96}, deviceScaleFactor: 2});
  for (const f of fs.readdirSync(__dirname).filter(f => f.endsWith('.svg'))) {
    const svg = fs.readFileSync(path.join(__dirname, f), 'utf8');
    await p.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
    await p.locator('svg').screenshot({path: path.join(salida, f.replace('.svg', '.png')), omitBackground: true});
  }
  await b.close();
})();
