# Line-figure poses (Phase 4, waiting for the owner's style pick)

Body keypoints read from the two free-exercise-db photos of each exercise with
MediaPipe Pose Landmarker (heavy model), offline – nothing runs in the app.

- `extract.py <imgdir> <out.json> <model.task> <ids…>` – downloads `<id>/0.jpg` and `1.jpg`,
  writes the 33 landmarks per photo. Needs `pip install mediapipe` and the model
  `pose_landmarker_heavy.task` (storage.googleapis.com/mediapipe-models/…), plus `libegl1`.
- `quality.py <all.json> <quality.json>` – marks exercises where the body wasn't found or is
  hard to see (average joint visibility < 0.45). 2026-11-13: 821 good, 52 need a look.
- `canon2d.py <all.json> <quality.json> <poses.json>` – uniform figures: 15 points per frame (head, shoulders, elbows, wrists,
  hips, knees, ankles, toes), same body size, floor at y=880, side-on figures face right, `s` = how side-on (for the bar).

Mockup: https://claude.ai/artifact/GNPyueDWW1a8yTupNqxtUf (owner: style B in light mode, C in dark).

- `sam3d_extract.py` + `.github/workflows/poses3d.yml` (manual "Poses 3D" run): Meta SAM 3D Body
  (SAM License, commercial use allowed) fits a 3D body with real proportions to the photos of
  `test_group.json`; needs the GitHub secret `HF_TOKEN` (Hugging Face account with access to
  facebook/sam-3d-body-dinov3). Output artifact `poses3d` (keypoints, joints, pose parameters, meshes).
- Results of a "Poses 3D" run are pushed to the branch `poses3d-results` (this cloud session can't
  download Actions artifacts). `prep3d.py <poses3d.json> <meshes.npz> <mock3d.json>` turns them into
  mockup data (skeleton joints in metres + same-scale mesh stills); `mockup3d_template.html` is the
  round-3 mockup (3D joints, bone directions slerped so limbs keep their length, every body turned to
  the same three-quarter side view, bars drawn in 3D through both hands).
- Round 5 (2026-11-14): every pose is redrawn with one standard body – shape component 0 at −2
  (`c0m`, lean/athletic; owner wanted a slim, fit body), scale = mean. `prep3d.py … c0m`.
  `shapesheet.py` renders the shape candidates side by side. Barbell placement rules (`barPlace`
  in the template): back (squat, good morning, barbell lunge/split squat/step-up/calf raise),
  front (front squat), hips (hip thrust, glute bridge), hands (everything else); bar along the
  body's left-right axis. Working muscles: main = bright, secondary = light (`PIECES` split).
- Round 7 rules: level the left-right body line (roll < 25° removed), align the two photos on
  the body parts touching the floor/pad in both (`touching`), no foot pinning when hanging,
  idle hanging legs follow the spine with soft knees.
