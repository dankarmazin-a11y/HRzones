"""SAM 3D Body run results (one or more part files) -> review data: skeleton joints of the
standard fit body (variant c0m) per exercise, plus lists of exercises that failed."""
import json, sys
VARIANT = 'c0m'
J = {'neck': 69, 'sh_l': 5, 'sh_r': 6, 'el_l': 7, 'el_r': 8, 'wr_l': 62, 'wr_r': 41,
     'hip_l': 9, 'hip_r': 10, 'kn_l': 11, 'kn_r': 12, 'an_l': 13, 'an_r': 14,
     'toe_l': 15, 'toe_r': 18, 'heel_l': 17, 'heel_r': 20, 'ear_l': 3, 'ear_r': 4, 'nose': 0}
out, failed = {}, []
for path in sys.argv[2:]:
    for ex, frames in json.load(open(path)).items():
        if not frames or not all(frames) or not all(VARIANT in f.get('variants', {}) for f in frames):
            failed.append(ex); continue
        out[ex] = {'j': [{n: [round(float(x), 3) for x in f['variants'][VARIANT][i]] for n, i in J.items()} for f in frames]}
json.dump({'d': out, 'failed': sorted(failed)}, open(sys.argv[1], 'w'), separators=(',', ':'))
print(len(out), 'ok,', len(failed), 'failed')
