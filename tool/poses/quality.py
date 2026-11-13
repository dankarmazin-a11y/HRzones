"""Score each exercise's two poses: detected, joints visible, limbs the same length in both frames."""
import json, sys, math
data = json.load(open(sys.argv[1]))
KEY = [11,12,13,14,15,16,23,24,25,26,27,28]
LIMBS = [(11,13),(13,15),(12,14),(14,16),(23,25),(25,27),(24,26),(26,28),(11,23),(12,24)]
good, bad, reasons = [], [], {}
for ex, frames in data.items():
    if not all(frames):
        bad.append(ex); reasons[ex] = 'not found'; continue
    vis = min(sum(f['pts'][i][2] for i in KEY)/len(KEY) for f in frames)
    def L(f, a, b):
        pa, pb = f['pts'][a], f['pts'][b]
        return math.hypot((pa[0]-pb[0])*f['w'], (pa[1]-pb[1])*f['h'])
    # compare limb lengths relative to torso size between frames (camera zoom cancels out)
    def rel(f):
        t = (L(f,11,23)+L(f,12,24))/2 or 1
        return [L(f,a,b)/t for a,b in LIMBS]
    r0, r1 = rel(frames[0]), rel(frames[1])
    worst = max(abs(math.log((a+1e-6)/(b+1e-6))) for a,b in zip(r0,r1))
    if vis < 0.45: bad.append(ex); reasons[ex] = f'hard to see ({vis:.2f})'
    else: good.append(ex)
print(len(good), 'good,', len(bad), 'need a look')
json.dump({'good': good, 'bad': reasons}, open(sys.argv[2], 'w'), indent=0)
