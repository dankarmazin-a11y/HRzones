"""Turn MediaPipe landmarks into a compact line-figure pose: 15 points per frame, 0..1000 in a shared box."""
import json, sys
data = json.load(open(sys.argv[1]))
# head (ears mid), nose, shoulders, elbows, wrists, hips, knees, ankles, toes
IDX = {'ear_l':7,'ear_r':8,'sh_l':11,'sh_r':12,'el_l':13,'el_r':14,'wr_l':15,'wr_r':16,'hip_l':23,'hip_r':24,'kn_l':25,'kn_r':26,'an_l':27,'an_r':28,'to_l':31,'to_r':32}
out = {}
for ex, frames in data.items():
    if not all(frames): continue
    pts = []
    for f in frames:
        P = {k: (f['pts'][i][0]*f['w'], f['pts'][i][1]*f['h']) for k, i in IDX.items()}
        head = ((P['ear_l'][0]+P['ear_r'][0])/2, (P['ear_l'][1]+P['ear_r'][1])/2)
        order = ['sh_l','sh_r','el_l','el_r','wr_l','wr_r','hip_l','hip_r','kn_l','kn_r','an_l','an_r','to_l','to_r']
        pts.append([head] + [P[k] for k in order])
    xs = [p[0] for fr in pts for p in fr]; ys = [p[1] for fr in pts for p in fr]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    s = max(x1-x0, y1-y0)
    cx, cy = (x0+x1)/2, (y0+y1)/2
    out[ex] = [[[round((p[0]-cx)/s*1000+500), round((p[1]-cy)/s*1000+500)] for p in fr] for fr in pts]
json.dump(out, open(sys.argv[2], 'w'), separators=(',', ':'))
print(len(json.dumps(out, separators=(',', ':'))), 'bytes for', len(out))
