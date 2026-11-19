// Records the review page's line-figure drawing for every "done" exercise as vector ops.
const { chromium } = require('playwright'); const fs = require('fs'); const path = require('path');
(async () => {
  const page = process.argv[2], dir = process.argv[3], out = process.argv[4];
  const done = {};
  for (const f of fs.readdirSync(dir)) { const d = JSON.parse(fs.readFileSync(path.join(dir, f))); if (d.v === 'done' && d.baked) done[f.replace(/\.json$/, '')] = d.baked; }
  const b = await chromium.launch(); const p = await b.newPage();
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.goto('file://' + page); await p.waitForTimeout(500);
  const res = await p.evaluate((done) => {
    window.__ms = 0; // alternating exercises: first side
    const W = 200, out = {}, fails = [];
    const r = n => Math.round(n / W * 1000) / 1000;
    const COL = { '#141b2b': 'i', '#ff7a2d': 'b', '#ffc09a': 's', '#d4d8df': 'f', 'rgba(20,27,43,.16)': 'p', 'rgba(20, 27, 43, 0.16)': 'p' };
    for (const [id, bk] of Object.entries(done)) {
      if (!D3[id]) { fails.push(id + ':nod3'); continue; }
      D3[id].id = id;
      try { applyBaked(id, bk); } catch (e) { fails.push(id + ':bake ' + e); continue; }
      const frames = [];
      for (const t of [0, 1]) {
        const ops = []; const cv = document.createElement('canvas'); cv.width = cv.height = W;
        const real = cv.getContext('2d');
        const col = v => { const k = String(v).toLowerCase().replace(/\s/g, ''); const c = COL[k] ?? COL[String(v).toLowerCase()]; if (c === undefined) return 'x' + k.replace('#', ''); return c; };
        const ctx = new Proxy(real, {
          get(tg, k) {
            const f = tg[k];
            if (typeof f !== 'function') return f;
            return (...a) => {
              switch (k) {
                case 'beginPath': ops.push(['B']); break;
                case 'moveTo': ops.push(['M', r(a[0]), r(a[1])]); break;
                case 'lineTo': ops.push(['L', r(a[0]), r(a[1])]); break;
                case 'stroke': ops.push(['S']); break;
                case 'fill': ops.push(['F']); break;
                case 'arc': ops.push(['A', r(a[0]), r(a[1]), r(a[2]), +a[3].toFixed(3), +a[4].toFixed(3)]); break;
                case 'ellipse': ops.push(['E', r(a[0]), r(a[1]), r(a[2]), r(a[3]), +a[4].toFixed(3), +a[5].toFixed(3), +a[6].toFixed(3)]); break;
                case 'roundRect': ops.push(['R', r(a[0]), r(a[1]), r(a[2]), r(a[3]), r(typeof a[4] === 'number' ? a[4] : 0)]); break;
                case 'fillRect': ops.push(['FR', r(a[0]), r(a[1]), r(a[2]), r(a[3])]); break;
                case 'clearRect': case 'save': case 'restore': break;
                default: ops.push(['?' + String(k)]);
              }
              return f.apply(tg, a);
            };
          },
          set(tg, k, v) {
            if (k === 'strokeStyle') ops.push(['C', col(v)]);
            else if (k === 'fillStyle') ops.push(['K', col(v)]);
            else if (k === 'lineWidth') ops.push(['W', r(v)]);
            else if (k === 'lineCap') ops.push(['P', v[0]]);
            else if (k === 'lineJoin') {}
            else if (k === 'globalAlpha') ops.push(['G', +(+v).toFixed(3)]);
            else ops.push(['?=' + String(k)]);
            tg[k] = v; return true;
          }
        });
        const fake = { width: W, height: W, getContext: () => ctx };
        try { draw3d(fake, id, t, 'line'); } catch (e) { fails.push(id + ':' + e); }
        frames.push(ops);
      }
      out[id] = frames;
    }
    return { out, fails };
  }, done);
  fs.writeFileSync(out, JSON.stringify(res.out));
  console.log('ids', Object.keys(res.out).length, 'fails', res.fails.length, res.fails.slice(0, 10), 'errs', errs.slice(0, 3));
  const unk = new Set(); for (const fr of Object.values(res.out)) for (const ops of fr) for (const o of ops) if (String(o[0]).startsWith('?')) unk.add(o.join(':'));
  console.log('unknown', [...unk].slice(0, 20));
  await b.close();
})();
