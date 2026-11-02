# HR Zones

One iPhone app for hybrid athletes: strength log, run tracking, body metrics and live heart-rate zone beeps.
Built with Flutter. Project brief: `CLAUDE.md`, full spec: `docs/SPEC.md`.

## Get the app on your iPhone (no Mac needed)
1. GitHub → **Actions → Build**. Every push to `main` builds automatically; for another branch use **Run workflow**.
2. Open the finished run and download **HRZones-ipa** (a zip with `HRZones.ipa`).
3. Drag `HRZones.ipa` into **Sideloadly**, enter your Apple ID, click Start.
4. Free Apple ID: the app expires after 7 days – re-run Sideloadly to refresh.

## Web preview
Open **https://dankarmazin-a11y.github.io/HRzones/** in Safari (Share → Add to Home Screen to keep it as an icon).
It updates on every push to `main`. Native features like beeps don't work in the browser.

## Test checklist (current build)
Strength log:
- [ ] Workouts → New template ("Push A"), add 3 exercises, change sets, drag to reorder, Save.
- [ ] Start the template. Type kg and reps, tap ✓ → row turns green, rest timer starts (beep at the end).
- [ ] Tap the set number to switch Warm-up / Normal / Drop / Failure. Tap RPE to pick one.
- [ ] Close the app mid-workout and reopen → Home shows "Resume".
- [ ] Finish → summary. Do the same template again with more weight → "PREVIOUS" shows last time, summary shows a 🏆 record.
- [ ] Workouts → History shows both workouts.
- [ ] Exercises: popular ones on top (e.g. tap "Chest" → Barbell Bench Press first), then A–Z. "Stretching" filter shows stretches.
- [ ] In a workout: timer button → pick a rest time → all exercises change. ⋮ on one exercise → change only its rest / switch to "Track: time".
- [ ] Add 2 stretches, tap ▶ → countdown, beep, 10 s rest, next stretch starts by itself.
- [ ] Timer button → "1 min" or "Stopwatch" runs in the bottom bar.
- [ ] Hold an exercise name → a compact list opens → drag to reorder.
- [ ] Tap "Stretching" in a workout, pick 3 stretches → one Stretching card. ▶ runs them one after another; tap the bar → big sideways timer.
- [ ] Tap the small "kg×reps" button on a card → reps → time.
- [ ] Minimise a workout (⌄) → the bar above the tabs shows time and % done; tap it to go back.
- [ ] Profile → Connect a strap → your chest strap appears → tap it. In a workout tap ♥ → live heart rate.
- [ ] Open an exercise you did twice → records, progress chart and history.
- [ ] ⋮ on a weight exercise → Plate & 1RM calculator; ⋮ → Swap exercise.
- [ ] Tap any number next to a slider (age, target range, alert gap) and type a value.

Heart rate:
- [ ] App opens with 4 tabs: Home, Workouts, Progress, Profile.
- [ ] Home → "Test HIGH beep" plays 3 high beeps, "Test LOW beep" 2 low beeps.
- [ ] Start monitoring, drag the simulated HR above the range → after ~5 s: 3 beeps, then every 10 s.
- [ ] Below the range → 2 low beeps.
- [ ] "Simulate signal loss" → after 15 s shows "--" and beeps stop.
- [ ] With music playing: beeps play over the music without stopping it.
- [ ] Lock the screen while out of range → beeps keep coming.

## Code map
- `lib/data/` – local database (drift/SQLite), exercises, templates, workouts.
- `lib/workout/` – live workout logic, PRs and stats.
- `lib/hr/` – heart-rate sources (simulated now; Bluetooth and HealthKit later), zones, alert logic.
- `lib/beep/` – beep interface (Dart) → `ios/Runner/BeeperPlugin.swift` (native audio).
- `lib/ui/` – screens.
- `Sources/`, `project.yml` – Phase 0 Swift proof of concept, kept as reference for the HealthKit port.
