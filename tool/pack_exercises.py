"""Packs assets/exercises.json into assets/exercises.json.gz – the copy the app ships.

The phone keeps app files unpacked, so shipping the packed copy saves ~700 KB without changing a
single word. assets/exercises.json stays in the repo as the readable source (tools and tests use
it); test/exercise_asset_test.dart fails if the two differ. Run after every change to
exercises.json (tool/build_exercises.py does it by itself).
"""
import gzip

with open('assets/exercises.json', 'rb') as f:
    raw = f.read()
with open('assets/exercises.json.gz', 'wb') as f:
    # mtime 0 → the same input always gives the same file (no noise in git)
    f.write(gzip.compress(raw, compresslevel=9, mtime=0))
print(f'{len(raw)} → {len(gzip.compress(raw, 9, mtime=0))} bytes')
