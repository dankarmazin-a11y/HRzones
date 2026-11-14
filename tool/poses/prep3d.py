"""SAM 3D Body results -> mockup data: skeleton joints (metres, camera axes) + mesh still renders."""
import json, sys, base64, io
import numpy as np
from PIL import Image, ImageDraw
src, meshes, out = sys.argv[1:4]
VARIANT = sys.argv[4] if len(sys.argv) > 4 else ''  # e.g. c0m = the slim, fit standard body
d = json.load(open(src)); M = np.load(meshes); F = M['faces']
J = {'neck': 69, 'sh_l': 5, 'sh_r': 6, 'el_l': 7, 'el_r': 8, 'wr_l': 62, 'wr_r': 41,
     'hip_l': 9, 'hip_r': 10, 'kn_l': 11, 'kn_r': 12, 'an_l': 13, 'an_r': 14,
     'toe_l': 15, 'toe_r': 18, 'heel_l': 17, 'heel_r': 20, 'ear_l': 3, 'ear_r': 4, 'nose': 0}
res = {}
PXM = 360 / 2.4  # the same pixels per metre for every exercise
def render(v, cx, low, size=360, col=(120, 128, 140)):
    v = v.copy()
    P = v[:, :2]
    xy = np.stack([(P[:, 0] - cx) * PXM + size / 2, (P[:, 1] - low) * PXM + size * 0.94], 1)
    tri = v[F]; n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0]); n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-9
    light = np.array([-0.4, -0.6, -0.7]); light /= np.linalg.norm(light)
    shade = np.clip(np.abs(n @ light), 0, 1)
    order = np.argsort(-tri[:, :, 2].mean(1))  # far first (z away from camera)
    im = Image.new('RGBA', (size, size), (0, 0, 0, 0)); dr = ImageDraw.Draw(im)
    for i in order:
        a = 0.35 + 0.65 * shade[i]
        dr.polygon([tuple(xy[k]) for k in F[i]], fill=tuple(int(c_ * a) for c_ in col) + (255,))
    b = io.BytesIO(); im.save(b, 'PNG', optimize=True); return 'data:image/png;base64,' + base64.b64encode(b.getvalue()).decode()
for ex, frames in d.items():
    if not all(frames): continue
    fr = []
    for f in frames:
        k = np.array(f['variants'][VARIANT] if VARIANT else f['kp3d'])
        fr.append({n: [round(float(x), 4) for x in k[i]] for n, i in J.items()})
    vs = [M[f'{ex}_{i}' + (f'_{VARIANT}' if VARIANT else '')].astype(np.float32) for i in (0, 1)]
    allv = np.concatenate(vs)
    cx = (allv[:, 0].min() + allv[:, 0].max()) / 2; low = allv[:, 1].max()
    res[ex] = {'j': fr, 'mesh': [render(v, cx, low) for v in vs]}
    print(ex, flush=True)
json.dump(res, open(out, 'w'), separators=(',', ':'))
