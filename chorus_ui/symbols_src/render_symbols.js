// Draws the symbol PNGs in `chorus_ui/assets/symbols/` from SVG files, the
// way docs/brand/render.js draws the first 23: each picture trimmed to what
// is drawn, then fitted and centred in a square with 6% padding, on a
// transparent background, at 128, 256 (2.0x/) and 384 (3.0x/) pixels.
// Chromium draws the SVG at each exact size.
//
// Usage, with Playwright installed for Node:
//   node render_symbols.js <svg_dir> <symbols_dir> [word ...]
// With no words, every <word>.svg in <svg_dir> is drawn.
const { chromium } = require(process.env.PLAYWRIGHT || 'playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const [svgDir, outDir, ...only] = process.argv.slice(2);
  const words = only.length
    ? only
    : fs.readdirSync(svgDir).filter((f) => f.endsWith('.svg')).map((f) => f.slice(0, -4));
  const browser = await chromium.launch();
  const p = await browser.newPage({ deviceScaleFactor: 1 });
  const done = [];
  for (const word of words) {
    const svg = fs.readFileSync(path.join(svgDir, `${word}.svg`), 'utf8');
    const src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
    await p.setContent('<!doctype html><body></body>');
    const box = await p.evaluate(async (src) => {
      const size = 1024;
      const img = new Image(size, size);
      img.src = src;
      await img.decode();
      const canvas = document.createElement('canvas');
      canvas.width = canvas.height = size;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0, size, size);
      const { data } = ctx.getImageData(0, 0, size, size);
      let left = size, top = size, right = -1, bottom = -1;
      for (let y = 0; y < size; y++) {
        for (let x = 0; x < size; x++) {
          if (data[(y * size + x) * 4 + 3] >= 16) {
            if (x < left) left = x;
            if (x > right) right = x;
            if (y < top) top = y;
            if (y > bottom) bottom = y;
          }
        }
      }
      return {
        x: left / size,
        y: top / size,
        w: (right + 1 - left) / size,
        h: (bottom + 1 - top) / size,
      };
    }, src);
    for (const [dir, n] of [['', 128], ['2.0x/', 256], ['3.0x/', 384]]) {
      const scale = (n * 0.88) / Math.max(box.w, box.h);
      const left = n / 2 - (box.x + box.w / 2) * scale;
      const top = n / 2 - (box.y + box.h / 2) * scale;
      await p.setViewportSize({ width: n, height: n });
      await p.setContent(
        `<!doctype html><style>html,body{margin:0;background:transparent}` +
          `img{position:absolute;left:${left}px;top:${top}px;` +
          `width:${scale}px;height:${scale}px}</style><img src="${src}">`,
      );
      await p.evaluate(() => document.images[0].decode());
      const file = path.join(outDir, `${dir}${word}.png`);
      await p.screenshot({
        path: file,
        omitBackground: true,
        clip: { x: 0, y: 0, width: n, height: n },
      });
      done.push(`${file} ${n}x${n}`);
    }
  }
  await browser.close();
  console.log(done.join('\n'));
})();
