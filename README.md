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
