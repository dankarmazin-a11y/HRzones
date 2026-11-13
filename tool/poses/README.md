# Line-figure poses (Phase 4, waiting for the owner's style pick)

Body keypoints read from the two free-exercise-db photos of each exercise with
MediaPipe Pose Landmarker (heavy model), offline – nothing runs in the app.

- `extract.py <imgdir> <out.json> <model.task> <ids…>` – downloads `<id>/0.jpg` and `1.jpg`,
  writes the 33 landmarks per photo. Needs `pip install mediapipe` and the model
  `pose_landmarker_heavy.task` (storage.googleapis.com/mediapipe-models/…), plus `libegl1`.
- `quality.py <all.json> <quality.json>` – marks exercises where the body wasn't found or is
  hard to see (average joint visibility < 0.45). 2026-11-13: 821 good, 52 need a look.
- `compact.py <all.json> <poses.json>` – 15 points per frame (head, shoulders, elbows, wrists,
  hips, knees, ankles, toes), both frames in one 0–1000 box per exercise.

Mockup: https://claude.ai/artifact/GNPyueDWW1a8yTupNqxtUf (styles A / B / C).
