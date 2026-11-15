# Exercise line figures – generation rules

Owner-approved look (2026-11-14, mockup rounds 1–7: https://claude.ai/artifact/GNPyueDWW1a8yTupNqxtUf).
Every exercise figure is made with these rules, in this order. Code: `mockup3d_template.html`
(drawing) and `sam3d_extract.py` (3D data). Change a rule here first, then in the code.

## 1. Source
1. Each exercise has two free-exercise-db photos: start and end position.
2. Meta **SAM 3D Body** (SAM License, commercial use allowed) fits a 3D body to each photo.
3. Every pose is **redrawn on one standard body**: shape component 0 at −2 (`c0m`, lean and
   athletic – owner: "fit, slim"), mean proportions. All figures have the same proportions.
4. Exercises whose photos fail (no body found, broken pose) keep a plain icon + Show photos
   until fixed by hand.

## 2. Ground and alignment
5. **Floor** = the lowest point of the body. Nothing is drawn below it.
6. The two photos are lined up on the body parts **touching the floor/pad in both** (feet,
   hands, forearms, knees…). Hanging exercises are lined up on the hands. **Seated and lying
   exercises** (machines, benches, preacher, incline/decline, lying/prone/supine) are lined up
   on the **hips** – the seat holds them (lining up on the feet froze leg extensions and leg
   curls). Rollouts / ab wheel / slides never line up on the rolling hands.
7. **Lying exercises** are often photographed from above: the camera is tilted so the torso
   lies flat. Lying = the name has lying, prone, supine, bench press, floor press, pullover,
   skull crusher, Tate press, fly/flye, chest press or close-grip press – and not incline,
   decline, standing, seated, machine or cable.
8. **Hands and feet both on the floor** (push-up, plank): the body is turned around the feet
   until the hands rest on the floor too.
9. **Level body:** the shoulders and hips are levelled left-to-right. Tilts under 25° are
   removed (photo or model error); bigger ones are kept (side plank etc.).

## 3. Camera
10. One fixed camera per exercise, framed from the whole movement – only the body moves.
11. **Side view** (left-right line 25° from the viewing direction) for front-to-back movements;
    **front three-quarter view** (75°) when the arms/legs move mainly out to the sides
    (side movement > 1.2 × front-back movement, measured relative to the pelvis).
12. Facing: upright bodies look to screen-right; lying bodies have the head on the left.
    **Lying exercises are always seen from the side** (the end-on view made a bench press look
    seated). **Hanging exercises** are seen from the front. The camera is level for everything
    standing (a raised camera made bars look tilted); lying exercises without a barbell get a
    camera 14° higher so both arms/legs show.
13. Same scale for every exercise (2.4 m across the frame), floor at 94 % of the height.
    Hanging exercises are centred and have no floor line. The frame is centred on the body
    **and the barbell ends**, so a bar never runs off the edge.

## 4. Movement
14. Joints turn between the two poses (bone directions interpolated on the sphere); bones
    keep their length. Ease in/out, short hold at both ends.
15. A bone that turns less than **6°** between the photos stays still (**2°** for a bone a working
    muscle sits on). A pelvis that moves less than 4 cm stays still.
15a. **Idle body parts hold one pose:** legs (when no leg muscle works and the knees/ankles move
    < 25 cm against the pelvis), arms (no arm/shoulder/chest/back muscle works), torso (no core
    or back muscle works) keep the average of the two photos – no drifting or whole-body sway.
15b. **Symmetry:** two-sided exercises are mirrored left/right so both sides move the same.
    One-sided exercises (the app's one-sided list, or "single/one-arm/one-leg/alternating" in the
    name) keep the photo's sides.
15c. **Static holds** (tracked by time, or plank / wall sit / dead hang / hold / hollow /
    superman) and **carries** (farmer's walk – owner: walking looked like running) show one
    still pose.
15e. **Calf exercises**: the toes stay on the floor and the heels rise; feet are never pinned
    flat.
15f. **Ab exercises** (crunch, sit-up…) draw the spine as a curve that rounds forward as the
    shoulders come towards the knees.
16. **Planted feet:** a foot on the floor in both photos that does not rise (< 8 cm) (and moving < 30 cm, or the foot that
    moves least when < 45 cm – lunges) is pinned; the leg bends to reach it (two-bone reach,
    knee bending the way it bends in the photos). Never when hanging.
17. **Fixed hands:** hands on the floor in both photos, or on a pull-up bar, are pinned the
    same way. When the hands are fixed the **body moves** (pull-ups rise, dips sink) even if no
    core muscle works. A planted foot the leg cannot reach moves the whole body to it – feet
    never slide.
17a. **Small movements are made visible:** when the biggest joint moves less than 8 cm between
    the photos (stretches, wrist curls), the movement is stretched to ~12 cm (at most 3×).
17b. **Added movements** the photos can't show: **shrugs** – the body holds still and the
    shoulders (with the arms and weight) rise 6 cm; **calf raises** – heels rise 7 cm along the
    shin (standing: the whole body rises, toes stay down; seated/machine: only feet and knees).
17c. **Alternating** exercises switch sides every round (the pose is mirrored across the body).
17d. Photo pairs that are the same picture can't be animated by rules – they keep a still
    figure and are listed for a hand fix.
18. **Planted feet** are found by the lowest of ankle and toe. **Idle legs:** when no leg muscle works (main or secondary), the legs hold one pose (the
    straighter photo). When hanging they hang in line with the body with soft knees.

## 5. Equipment and props
19. **Barbell placement** (coaching guides):
    - upper back, top of the traps behind the neck: back squat, good morning, barbell lunge,
      split squat, step-up, calf raise;
    - front of the shoulders: front squat (and front rack / Zercher);
    - across the hips: hip thrust, glute bridge;
    - across the palms: everything else (deadlift, row, curl, press, bench, raise, shrug…).
19a. **The bar is drawn in front of the body** when it is held in the hands, on the front of the
    shoulders or across the hips; a back-squat bar is drawn behind the neck. The nearer plate is
    in front of the body, the farther plate behind it.
20. The bar runs along the body's left-right line, keeps **one direction** for the whole
    movement (it never rotates), stays **level**, is 2.2 m long with plates 0.92 m from the
    centre (E-Z bar: 1.25 m with small plates and the zig-zag bend in the middle) (Ø 45 cm, 6 cm thick: real discs – darker rim, lighter face, centre
    hole, drawn as a stack so they have thickness).
21. **One grip width** for the whole movement (average of the photos; back squat ≥ 1.6 ×
    shoulder width, front squat 1.05 ×, hip thrust ≥ 1.2 ×). Both hands are placed exactly on
    the bar – no floating, no impossible arm movement.
22. Dumbbells: in each palm along the shoulder line; kettlebells hang below the hand.
    **Hammer** grip = the dumbbell lies along the forearm's cross line; **goblet / pullover / two-hand
    swing** = one weight held between both hands; **one-arm** exercises = a weight only in the moving hand;
    carries = a weight in each hanging hand.
22a. **Drawing order** (what is in front) is decided once from the middle of the movement – the
    colours never flicker as lines swap places.
23. Props need the name to agree (geometry alone mistook crawls and stretches for sitting):
    a shoulder bench needs hip thrust / bench / bridge / skull crusher / Tate press / pullover /
    lying triceps in the name; a seat needs seated /
    sitting / seat / machine / bench / chair / box. **Hanging** is decided by the name only:
    pull-up, chin-up, hanging, muscle-up, toes-to-bar, knees-to-elbows ("hang position" in a
    clean is not hanging).
23a. More props by name: **incline/decline** = a slanted backrest under the back (hips to
    shoulders); **seat** under the hips for seated machines/benches when the hips are off the
    floor; **box** under the hips at the bottom of a box squat / squat to a bench; **bench**
    under the hands for bench dips (when the hands are off the floor). Lying exercises are
    never "reverse/bent-over/rear-delt flyes" (those are bent over, not lying).
24. **Bench under the shoulders** when the shoulders rest 30–75 cm high in both photos and the
    torso is close to horizontal (hip thrust). **Seat** when the pelvis is 30–80 cm high with
    thighs roughly level and shins upright (seated press). **Pull-up bar** above the hands when
    hanging. Props are flat, grey, behind the body.

## 6. Look
25. Line figure only (owner pick). Style **B** in light mode (dark lines), style **C** in dark
    mode (white lines). Head = filled oval; equal line widths.
26. **Working muscles only:** main muscles in the bright colour, secondary muscles lighter,
    everything else plain. Each line is split where the muscles sit: shoulders = top 35 % of
    the upper arm + shoulder line; biceps/triceps = rest of the upper arm; forearms; glutes =
    top 25 % of the thigh + hip line; quads/hamstrings/adductors/abductors = rest of the thigh;
    calves = shin; abs/lower back = lower 45 % of the spine; chest/lats/middle back = upper
    spine; traps/neck = neck.
27. In the app: moving on the exercise page and in the exercise list; **still** (end pose)
    when small next to a name in a workout or template. Show photos stays one tap away.

## 7. Checking
28. After a full run every exercise is checked by eye in batches (review page) **and by an
    automatic check** (`audit.js`-style: figures that don't move, planted feet that slide, a
    figure or bar leaving the frame, drawing errors). Fixes go in as
    rules first; only true one-offs get a per-exercise override.
29. **What the owner's marks mean (owner, 2026-11-15):** **Done** = perfect (locked, rule 30);
    **Good** = close, small fixes in the note; **Bad** = poorly made, big fix. Notes on Good and Bad
    are both fix requests.
    **Every round, before showing the owner:** run the automatic check on all exercises; Done
    exercises are locked and can't change; every Good exercise must not get worse apart from the
    fix its note asks for (its unchanged parts are compared before/after); look at every exercise
    that has a note. The report says what was fixed and checked, what was changed but not checked,
    and what a rule can't fix.
30. **Done = locked.** The owner taps Done on a perfect figure: the page saves the finished
    movement (25 frames with the camera applied, plus frame, floor, props, bar direction and
    grip) in the review database (`reviews/<id>.baked`). From then on that exercise plays the
    saved frames – rule changes never touch it – and the saved frames are what goes into the
    app. Only colours and line style still follow the theme. Unlock removes the saved copy.

## 8. Tried and parked
- **NVIDIA Kimodo** (text-to-motion, Hugging Face, 2026-11-15): 10-exercise test, two versions
  each. Owner: all 20 bad ("look nothing like the exercises"); the current figures were 10/10
  good. Kimodo is trained on walking, everyday actions, combat and dance, not gym exercises.
  Tools kept (`kimodo_gen.py`, `kimodo_build.py`, workflow `poses_kimodo.yml`, full-movement
  playback in the figure page) – re-test when a gym-trained motion model appears.
- **HyperFrames** (HeyGen, HTML → video): renders existing animation, makes no body movement.
  Noted for App Store preview / launch videos (Phase 6–7).
