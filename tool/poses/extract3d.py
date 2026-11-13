"""Like extract.py but also keeps MediaPipe's 3D world landmarks (metres, hip-centred). Uses the cached photos."""
import json, sys, os, urllib.request
import mediapipe as mp
from mediapipe.tasks import python as mpt
from mediapipe.tasks.python import vision
base, out_path, model = sys.argv[1], sys.argv[2], sys.argv[3]
ids = [l.strip() for l in open(sys.argv[4]) if l.strip()]
det = vision.PoseLandmarker.create_from_options(vision.PoseLandmarkerOptions(
    base_options=mpt.BaseOptions(model_asset_path=model), num_poses=1, min_pose_detection_confidence=0.3))
out = {}
for n, ex in enumerate(ids):
    frames = []
    for i in (0, 1):
        p = os.path.join(base, f'{ex}_{i}.jpg')
        if not os.path.exists(p):
            urllib.request.urlretrieve(f'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{ex}/{i}.jpg', p)
        img = mp.Image.create_from_file(p)
        r = det.detect(img)
        if not r.pose_landmarks:
            frames.append(None); continue
        frames.append({'w': img.width, 'h': img.height,
                       'pts': [[round(l.x, 4), round(l.y, 4), round(l.visibility, 2)] for l in r.pose_landmarks[0]],
                       'world': [[round(l.x, 4), round(l.y, 4), round(l.z, 4)] for l in r.pose_world_landmarks[0]]})
    out[ex] = frames
    if n % 50 == 0: print(n, flush=True)
json.dump(out, open(out_path, 'w'))
print('done', flush=True)
