"""Fit Meta's SAM 3D Body (3D body with real proportions) to the two photos of each exercise.

Runs in GitHub Actions (.github/workflows/poses3d.yml) – the model download needs a Hugging Face
token with access to facebook/sam-3d-body-dinov3 (GitHub secret HF_TOKEN).

usage: sam3d_extract.py <sam-3d-body checkout> <group.json> <out_dir>
group.json: {exercise_id: [[x0,y0,x1,y1] or null for photo 0, ... photo 1]} (person boxes)
Writes <out_dir>/poses3d.json (70 keypoints 3D + 2D, camera, pose parameters per photo) and
<out_dir>/meshes.npz (body mesh vertices per photo + faces, for a preview render).
"""
import json, os, sys, urllib.request
import numpy as np

repo, group_path, out_dir = sys.argv[1:4]
sys.path.insert(0, repo)
import torch  # noqa: E402
from sam_3d_body import load_sam_3d_body, SAM3DBodyEstimator  # noqa: E402
from sam_3d_body.build_models import _hf_download  # noqa: E402

torch.set_num_threads(os.cpu_count() or 4)
ckpt, mhr = _hf_download(os.environ.get('SAM3D_REPO', 'facebook/sam-3d-body-dinov3'))
model, cfg = load_sam_3d_body(checkpoint_path=ckpt, device='cpu', mhr_path=mhr)
est = SAM3DBodyEstimator(model, cfg)
group = json.load(open(group_path))
os.makedirs(out_dir, exist_ok=True)
img_dir = os.path.join(out_dir, 'img')
os.makedirs(img_dir, exist_ok=True)
res, meshes = {}, {'faces': est.faces}

def r(a, n=4):
    return np.round(np.asarray(a, dtype=float), n).tolist()

for ex, boxes in group.items():
    frames = []
    for i in (0, 1):
        p = os.path.join(img_dir, f'{ex}_{i}.jpg')
        if not os.path.exists(p):
            urllib.request.urlretrieve(
                f'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{ex}/{i}.jpg', p)
        box = boxes[i]
        out = est.process_one_image(p, bboxes=np.array([box], dtype=float) if box else None)
        if not out:
            frames.append(None)
            continue
        o = out[0]
        frames.append({
            'kp3d': r(o['pred_keypoints_3d']), 'kp2d': r(o['pred_keypoints_2d'], 1),
            'focal': float(np.asarray(o['focal_length']).reshape(-1)[0]), 'cam_t': r(o['pred_cam_t']),
            'global_rot': r(o['global_rot']), 'body_pose': r(o['body_pose_params']),
            'shape': r(o['shape_params']), 'scale': r(o['scale_params']),
            'joints': r(o['pred_joint_coords']),
        })
        meshes[f'{ex}_{i}'] = np.asarray(o['pred_vertices'], dtype=np.float32)
        print(ex, i, 'ok', flush=True)
    res[ex] = frames
json.dump(res, open(os.path.join(out_dir, 'poses3d.json'), 'w'))
np.savez_compressed(os.path.join(out_dir, 'meshes.npz'), **meshes)
print('done', len(res))
