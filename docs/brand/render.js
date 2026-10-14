// Renders every app icon, splash picture and symbol PNG from the SVGs in this
// folder, so the pictures can be redrawn after a change to the mark.
//
// It is a Playwright function: run it in a Chromium page with
// devicePixelRatio 1, for example through the Playwright MCP tool
// browser_run_code_unsafe. Set ROOT to the absolute path of this checkout
// first. Chromium draws the SVG at each exact pixel size, so small icons are
// drawn small rather than shrunk from a large picture.
async (page) => {
  const ROOT = '/absolute/path/to/chorus';
  const APP = `${ROOT}/chorus_flutter`;
  const RES = `${APP}/android/app/src/main/res`;
  const SYMBOLS = `${ROOT}/chorus_ui/assets/symbols`;

  const CARD = '#F6F2EA';
  const LINE = '#DCD6CB';

  const p = await page.context().newPage();

  // Reads an SVG file by opening it: the page has no file system access.
  // Then back to a blank HTML page, which setContent needs.
  const readSvg = async (path) => {
    await p.goto(`file://${path}`);
    const svg = await p.content();
    await p.goto('about:blank');
    return svg;
  };
  // The drawing inside an <svg> element, without its title.
  const inner = (svg) =>
    svg
      .replace(/^[\s\S]*?<svg[^>]*>/, '')
      .replace(/<\/svg>\s*$/, '')
      .replace(/<title>[\s\S]*?<\/title>/, '');

  const mark = inner(await readSvg(`${ROOT}/docs/brand/mark.svg`));
  const mono = inner(await readSvg(`${ROOT}/docs/brand/mark-monochrome.svg`));

  // One icon, N x N pixels. `markSize` is the width of the 64-unit mark as a
  // fraction of N. `plate` is 'none' (transparent), 'full' (card to the
  // edges, for icons the platform masks itself) or a rounded card square
  // { inset, radius } in fractions of N, with a hairline so it holds its
  // shape on a white launcher.
  const icon = async (path, n, { drawing = mark, markSize, plate = 'none' }) => {
    const m = n * markSize;
    const at = (n - m) / 2;
    let back = '';
    if (plate === 'full') {
      back = `<rect width="${n}" height="${n}" fill="${CARD}"/>`;
    } else if (plate !== 'none') {
      const line = Math.max(1, n / 96);
      const x = n * plate.inset + line / 2;
      const size = n - 2 * x;
      back =
        `<rect x="${x}" y="${x}" width="${size}" height="${size}" ` +
        `rx="${n * plate.radius}" fill="${CARD}" stroke="${LINE}" ` +
        `stroke-width="${line}"/>`;
    }
    await p.setViewportSize({ width: n, height: n });
    await p.setContent(
      `<!doctype html><style>html,body{margin:0;background:transparent}` +
        `svg{display:block}</style>` +
        `<svg xmlns="http://www.w3.org/2000/svg" width="${n}" height="${n}" ` +
        `viewBox="0 0 ${n} ${n}">${back}` +
        `<svg x="${at}" y="${at}" width="${m}" height="${m}" ` +
        `viewBox="0 0 64 64">${drawing}</svg></svg>`,
    );
    // An opaque plate is shot on white so the PNG carries no see-through
    // pixels; iOS rejects icons with an alpha channel.
    await p.screenshot({
      path,
      omitBackground: plate !== 'full',
      clip: { x: 0, y: 0, width: n, height: n },
    });
    return `${path} ${n}x${n}`;
  };

  const done = [];
  const densities = [
    ['mdpi', 1],
    ['hdpi', 1.5],
    ['xhdpi', 2],
    ['xxhdpi', 3],
    ['xxxhdpi', 4],
  ];

  // Android launcher. Legacy icon: the mark on a rounded card square.
  // Adaptive foreground and themed (monochrome) layer: 108 dp, the 48 dp mark
  // inside the 66 dp safe circle.
  const legacy = { inset: 2 / 48, radius: 8 / 48 };
  for (const [bucket, scale] of densities) {
    const dir = `${RES}/mipmap-${bucket}`;
    done.push(
      await icon(`${dir}/ic_launcher.png`, 48 * scale, {
        markSize: 0.58,
        plate: legacy,
      }),
      await icon(`${dir}/ic_launcher_foreground.png`, 108 * scale, {
        markSize: 48 / 108,
      }),
      await icon(`${dir}/ic_launcher_monochrome.png`, 108 * scale, {
        drawing: mono,
        markSize: 48 / 108,
      }),
    );
  }

  // Android splash (12+ system splash and the older launch background): a
  // 288 dp picture with the mark inside the central 192 dp circle, one PNG per
  // density so it stays sharp when the system scales it to 288 dp.
  for (const [bucket, scale] of densities) {
    done.push(
      await icon(`${RES}/drawable-${bucket}/splash_mark.png`, 288 * scale, {
        markSize: 136 / 288,
      }),
    );
  }

  // Web. The maskable icons and the Apple touch icon are card to the edges;
  // the mark stays inside the maskable 80% safe circle.
  done.push(
    await icon(`${APP}/web/favicon.png`, 32, { markSize: 1 }),
    await icon(`${APP}/web/icons/Icon-192.png`, 192, {
      markSize: 0.58,
      plate: legacy,
    }),
    await icon(`${APP}/web/icons/Icon-512.png`, 512, {
      markSize: 0.58,
      plate: legacy,
    }),
    await icon(`${APP}/web/icons/Icon-maskable-192.png`, 192, {
      markSize: 0.6,
      plate: 'full',
    }),
    await icon(`${APP}/web/icons/Icon-maskable-512.png`, 512, {
      markSize: 0.6,
      plate: 'full',
    }),
    await icon(`${APP}/web/icons/apple-touch-icon.png`, 180, {
      markSize: 0.6,
      plate: 'full',
    }),
  );

  // iOS: card to the edges, the system rounds the corners.
  const ios = [
    ['20x20@1x', 20],
    ['20x20@2x', 40],
    ['20x20@3x', 60],
    ['29x29@1x', 29],
    ['29x29@2x', 58],
    ['29x29@3x', 87],
    ['40x40@1x', 40],
    ['40x40@2x', 80],
    ['40x40@3x', 120],
    ['60x60@2x', 120],
    ['60x60@3x', 180],
    ['76x76@1x', 76],
    ['76x76@2x', 152],
    ['83.5x83.5@2x', 167],
    ['1024x1024@1x', 1024],
  ];
  const iosDir = `${APP}/ios/Runner/Assets.xcassets/AppIcon.appiconset`;
  for (const [name, n] of ios) {
    done.push(
      await icon(`${iosDir}/Icon-App-${name}.png`, n, {
        markSize: 0.6,
        plate: 'full',
      }),
    );
  }

  // macOS: the rounded card square on the standard 1024 grid (824 square,
  // 100 margin), with the mark inside.
  const macDir = `${APP}/macos/Runner/Assets.xcassets/AppIcon.appiconset`;
  for (const n of [16, 32, 64, 128, 256, 512, 1024]) {
    done.push(
      await icon(`${macDir}/app_icon_${n}.png`, n, {
        markSize: 0.5,
        plate: { inset: 100 / 1024, radius: 185 / 1024 },
      }),
    );
  }

  // Mulberry symbols: each one trimmed to what is drawn, then fitted and
  // centred in a square with 6% padding, on a transparent background. The
  // drawn area is found from the pixels, so strokes count and empty margins
  // in the original artwork do not.
  const words = [
    'finished', 'get', 'go', 'good', 'help', 'i', 'in', 'look', 'make',
    'more', 'on', 'open', 'put', 'same', 'some', 'turn', 'up', 'want',
    'what', 'when', 'where', 'who', 'why',
  ];
  for (const word of words) {
    const svg = await readSvg(`${ROOT}/docs/brand/mulberry/${word}.svg`);
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
      const path = `${SYMBOLS}/${dir}${word}.png`;
      await p.screenshot({
        path,
        omitBackground: true,
        clip: { x: 0, y: 0, width: n, height: n },
      });
      done.push(`${path} ${n}x${n}`);
    }
  }

  await p.close();
  return done.join('\n');
}
