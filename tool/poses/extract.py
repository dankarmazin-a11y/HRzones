"""Download the two free-exercise-db photos of each exercise and extract body keypoints."""
import json, sys, os, urllib.request
import mediapipe as mp
from mediapipe.tasks import python as mpt
from mediapipe.tasks.python import vision

base, out_path, model = sys.argv[1], sys.argv[2], sys.argv[3]
ids = sys.argv[4:]
opts = vision.PoseLandmarkerOptions(base_options=mpt.BaseOptions(model_asset_path=model), num_poses=1,
                                    min_pose_detection_confidence=0.3)
det = vision.PoseLandmarker.create_from_options(opts)
out = {}
for ex in ids:
    frames = []
    for i in (0, 1):
        p = os.path.join(base, f'{ex.replace("/", "_")}_{i}.jpg')
        if not os.path.exists(p):
            urllib.request.urlretrieve(f'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{ex}/{i}.jpg', p)
        img = mp.Image.create_from_file(p)
        r = det.detect(img)
        if not r.pose_landmarks:
            frames.append(None); continue
        frames.append({'w': img.width, 'h': img.height,
                       'pts': [[round(l.x, 4), round(l.y, 4), round(l.visibility, 2)] for l in r.pose_landmarks[0]]})
    out[ex] = frames
    print(ex, [f is not None for f in frames], flush=True)
json.dump(out, open(out_path, 'w'))
