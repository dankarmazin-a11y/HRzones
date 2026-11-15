"""Offline tool: NVIDIA Kimodo (text-to-motion, NVIDIA Open Model License) makes a full exercise
movement from a text description. Saves the 3D joints (somaskel77, metres, Y up) per exercise.

usage: python kimodo_gen.py <prompts.json> <out.json>
env: KIMODO_MODEL (default Kimodo-SOMA-RP-v1.2), DURATION (s, default 4), SAMPLES (default 2),
     STEPS (diffusion steps, default 50), OUT_FPS (default 15)
"""
import json, os, sys, time
import numpy as np
import torch
from kimodo.model.load_model import load_model

prompts = json.load(open(sys.argv[1]))
out_path = sys.argv[2]
model = load_model(os.environ.get('KIMODO_MODEL', 'Kimodo-SOMA-RP-v1.2'), device='cpu', default_family='Kimodo')
fps = model.fps
frames = int(float(os.environ.get('DURATION', '4')) * fps)
step = max(1, round(fps / float(os.environ.get('OUT_FPS', '15'))))
names = list(model.skeleton.bone_order_names)
res = {'joint_names': names, 'fps': fps / step, 'motions': {}}
for ex, text in prompts.items():
    t0 = time.time()
    try:
        torch.manual_seed(0)
        out = model([text], [frames], constraint_lst=[], num_denoising_steps=int(os.environ.get('STEPS', '50')),
                    num_samples=int(os.environ.get('SAMPLES', '2')), multi_prompt=True,
                    post_processing=True, return_numpy=True)
        pj = np.asarray(out['posed_joints'])  # [samples, T, J, 3]
        res['motions'][ex] = {'text': text, 'samples': [np.round(s[::step], 3).tolist() for s in pj]}
        print(ex, pj.shape, f'{time.time() - t0:.0f}s', flush=True)
    except Exception as e:  # keep going – one failure must not lose the rest
        print('FAILED', ex, repr(e), flush=True)
    json.dump(res, open(out_path, 'w'), separators=(',', ':'))
