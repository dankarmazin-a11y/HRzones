"""Uniform 2D line-figure poses (the photographer's camera angle, normalised).

- One transform per exercise for both frames (the camera stays put between the photos).
- Scale: every body gets the same size (median of torso, leg and arm length, so a limb
  pointing at the camera doesn't shrink the figure).
- Floor: the lowest point of both frames sits on the same floor line; centred horizontally.
- Mirrored so side-on figures face right.
- side: 0 = seen from the front … 1 = seen from the side (fixed per exercise, for the bar).
Output {id: {"f": [frame0, frame1], "s": side}} with 15 [x, y] points in a 0..1000 box.
"""
import json, math, statistics, sys

UNIT = 370          # px per "body unit" (≈ hip-to-shoulder ×2) – sets the figure size
FLOOR = 880
IDX = [None, 11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28, 31, 32]  # head = ears mid

def pts2d(f):
    P = [(x * f['w'], y * f['h']) for x, y, _ in f['pts']]
    head = ((P[7][0] + P[8][0]) / 2, (P[7][1] + P[8][1]) / 2)
    return [head if i is None else P[i] for i in IDX], P

def d(a, b): return math.hypot(a[0] - b[0], a[1] - b[1])
def mid(a, b): return ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)

def body_unit(P):
    torso = d(mid(P[11], P[12]), mid(P[23], P[24])) / 0.50
    leg = max(d(P[23], P[25]) + d(P[25], P[27]), d(P[24], P[26]) + d(P[26], P[28])) / 0.87
    arm = max(d(P[11], P[13]) + d(P[13], P[15]), d(P[12], P[14]) + d(P[14], P[16])) / 0.57
    return statistics.median([torso, leg, arm])

def main(src, quality, dst):
    data = json.load(open(src))
    good = set(json.load(open(quality))['good'])
    res = {}
    for ex, frames in data.items():
        if ex not in good or not frames or not all(frames):
            continue
        F = [pts2d(f) for f in frames]
        u = statistics.mean(body_unit(P) for _, P in F) or 1
        k = UNIT / u
        # Facing: nose in front of the ears → which way the person looks.
        P0 = F[0][1]
        look = P0[0][0] - (P0[7][0] + P0[8][0]) / 2
        sh = statistics.mean(d(P[11], P[12]) for _, P in F)
        torso = statistics.mean(d(mid(P[11], P[12]), mid(P[23], P[24])) for _, P in F) or 1
        side = max(0.0, min(1.0, 1 - sh / (torso * 0.75)))
        flip = -1 if (look < 0 and side > 0.35) else 1
        allp = [p for pts, _ in F for p in pts]
        xs = [p[0] * flip for p in allp]; ys = [p[1] for p in allp]
        cx = (min(xs) + max(xs)) / 2; low = max(ys)
        w, h = (max(xs) - min(xs)) * k, (low - min(ys)) * k
        k *= min(1.0, 920 / max(w, 1), (FLOOR - 30) / max(h, 1))
        res[ex] = {
            'f': [[[round(500 + (p[0] * flip - cx) * k), round(FLOOR + (p[1] - low) * k)] for p in pts] for pts, _ in F],
            's': round(side, 2),
            'k': round(k / (UNIT / u), 2),
        }
    json.dump(res, open(dst, 'w'), separators=(',', ':'))
    print(len(res), 'exercises,', len(json.dumps(res, separators=(',', ':'))), 'bytes')

if __name__ == '__main__':
    main(*sys.argv[1:4])
