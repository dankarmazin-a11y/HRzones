import sys, numpy as np
from PIL import Image, ImageDraw
M = np.load(sys.argv[1]); F = M['faces']; out = sys.argv[2]
names = ['', '_mean', '_c0m', '_c0p', '_c1m', '_c1p', '_c2m', '_c2p', '_c3m', '_c3p']
exs = ['Barbell_Squat_0', 'Side_Lateral_Raise_1', 'Barbell_Hip_Thrust_1']
def render(v, size=240):
    v = v.astype(np.float32); P = v[:, :2]; lo, hi = P.min(0), P.max(0); s = size * .9 / max(hi - lo); c = (lo + hi) / 2
    xy = (P - c) * s + size / 2; tri = v[F]; n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0]); n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-9
    L = np.array([-.4, -.6, -.7]); L /= np.linalg.norm(L); sh = np.abs(n @ L); order = np.argsort(-tri[:, :, 2].mean(1))
    im = Image.new('RGB', (size, size), 'white'); d = ImageDraw.Draw(im)
    for i in order:
        a = .35 + .65 * sh[i]; d.polygon([tuple(xy[k]) for k in F[i]], fill=tuple(int(x * a) for x in (120, 128, 140)))
    return im
sheet = Image.new('RGB', (240 * len(names), 260 * len(exs)), 'white'); dr = ImageDraw.Draw(sheet)
for r, ex in enumerate(exs):
    for c, n in enumerate(names):
        sheet.paste(render(M[ex + n]), (c * 240, r * 260 + 20)); dr.text((c * 240 + 6, r * 260 + 4), (n or '_photo')[1:], fill='black')
sheet.save(out)
