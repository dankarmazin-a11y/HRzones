# HR Zones – project brief for Claude

Read this first in every session. The full product spec is in `docs/SPEC.md`.

## What we're building
One iPhone app for hybrid athletes (strength + running): a Hevy-level strength log, Nike-Run-Club-level run tracking (tracking only, no coaching), body metrics, and **live heart-rate zone monitoring with audible beeps** when the user leaves a target range – during any workout, screen locked, music playing.

The owner is not a developer. Explain steps plainly, keep instructions short, and do the technical work yourself (commit, push, read CI logs, fix).

## Decisions so far
- **Framework: Flutter** (Dart), iPhone first, Android later from the same codebase. Platform-specific parts (HealthKit, background audio/beeps, GPS background) live in small native modules (Swift on iOS) behind platform channels.
- **UI language: English** for now; Hebrew/RTL later.
- **Data: local only** (SQLite) for the MVP, every record has a UUID + updatedAt to allow cloud sync later. No accounts, no analytics SDKs.
- **Exercise database:** seed from the open free-exercise-db (~800 exercises, primary/secondary muscles, equipment, images). Custom exercises allowed.
- **Heart-rate sources (pluggable interface):**
  1. **Simulated HR** (slider) – for development and testing the zone/beep logic. Default for now.
  2. **Bluetooth LE Heart Rate Profile** (service 0x180D, characteristic 0x2A37) – chest straps, armbands, watches in broadcast mode. Works without HealthKit.
  3. **HealthKit live workout (HKWorkoutSession + HKLiveWorkoutBuilder)** – the only way to get AirPods Pro 3 heart rate. Requires the HealthKit entitlement → needs the paid Apple Developer account (not yet purchased).
- **Beeps:** 3 high beeps above range, 2 low beeps below; 5 s grace period, configurable cooldown (default 10 s); mixes over music (AVAudioSession .playback + .mixWithOthers); must keep working with the screen locked (UIBackgroundModes: audio).

## Build & install (no Mac)
- GitHub Actions (`.github/workflows/`) builds on `macos-26` runners and uploads an unsigned, ad-hoc-signed `.ipa` artifact.
- The owner installs it from Windows with **Sideloadly** using a **free Apple ID** (app expires every 7 days; Developer Mode is on).
- **Known limitation (Phase 0 result, 2026-11-01):** Sideloadly + free Apple ID strips the HealthKit entitlement → "Missing com.apple.developer.healthkit entitlement". Everything else (build, install, beeps) works. HealthKit/AirPods HR waits for the paid account; then switch distribution to TestFlight from CI.
- There is no Mac or simulator: CI is the compiler. After pushing, check the Actions run (`gh api repos/dankarmazin-a11y/hrzones/actions/runs`) and fix failures yourself.
- Goal for UI iteration: also build a **Flutter web preview** in CI (e.g. GitHub Pages) so the owner can review screens from his phone before installing. Native features are stubbed on web.

## Roadmap
- **Phase 0 – feasibility (done):** native Swift proof of concept in `Sources/` + `project.yml` (XcodeGen). Keep its HealthKit/beep code as the reference for the Flutter iOS module; remove it once ported.
- **Phase 1 – Flutter skeleton + strength log (in progress):** 4 tabs (Home, Workouts, Progress, Profile); local DB; HR source interface with simulated + BLE sources; beep engine (native iOS module); exercise DB with muscle filters; templates; live workout logging (sets, weight, reps, RPE, set types, previous values, rest timer, supersets); post-workout summary and PRs; web preview + IPA in CI.
- **Phase 2 – running:** GPS route + map, pace, km splits, voice announcements, HR zones on route, PRs (1k/5k/10k/HM).
- **Phase 3 – body & progress:** weight, body fat, circumferences, charts, muscle heat map, weekly stats, export (JSON/CSV).
- **Gate:** owner uses it for a full month instead of Hevy/NRC → buy Developer account.
- **Phase 4 – closed beta:** HealthKit + AirPods HR, TestFlight to 20–50 testers, Live Activity.
- **Phase 5 – public:** cloud sync, Android, design polish, App Store.

### Phase 1 status
- Done: Flutter project at repo root (`lib/`, `ios/`, `web/`, bundle id `com.hrzones.app`, Flutter 3.47.9 pinned in CI); 4-tab shell; `HeartRateSource` interface + simulated source; 5 zones (220 − age); `ZoneAlertEngine` (5 s grace, 2 bpm hysteresis, cooldown, 15 s no-signal) with unit tests; native iOS beeper ported from Phase 0 (`ios/Runner/BeeperPlugin.swift`, channel `hrzones/beeper`); CI workflow `build.yml` (check → web preview + IPA).
- Done (strength log): drift/SQLite DB (`lib/data/`, schema in `database.dart`, generated `database.g.dart` – run `dart run build_runner build` after changing tables; CI fails if it is stale). Dates stored as ISO text with ms (`build.yaml`). Web uses `web/sqlite3.wasm` (from sqlite3.dart release `sqlite3-3.5.2`) + `web/drift_worker.js` (drift release `drift-2.35.3`); versions must match `pubspec.lock` – re-download both when upgrading. After `build_runner`, run `dart format lib test` (CI checks both). Exercise library seeded from `assets/exercises.json` (free-exercise-db, Unlicense; bump `exerciseSeedVersion` when it changes), search + muscle/equipment filters, custom exercises, images loaded from GitHub raw. Templates (reorder, sets, rest). Live workout (`lib/workout/workout_session.dart`): set types W/N/D/F, kg/reps or seconds, RPE, previous values (tap to copy, auto-fill on ✓), rest timer with beep, supersets (rest after last in group), HR chip + max HR per set, auto-saved after every change and restored on relaunch. Finish → summary (duration, volume, sets, avg/max HR, muscles, PRs: heaviest, est. 1RM (Epley), set volume, reps, time; no PRs on an exercise's first workout). History list. Home: resume banner, this week, last workout. HR settings persisted.
- Done (owner feedback round 1, 2026-11-02):
  - Exercise list is curated by `tool/build_exercises.py` (renames popular exercises to clean "Equipment + Name", adds missing ones with `hz_` ids, popularity ranks per muscle, `tracking: duration` for holds). Edit the script, run it, bump `exerciseSeedVersion`. Re-seeding keeps the user's tracking type/rest (upsert only updates catalogue fields). DB schema v2 adds `exercises.popularity` (migration in `database.dart`).
  - Library: Type filter (Strength / Stretching / Cardio) + muscle + equipment; 5 most popular for the current filter first, then A–Z.
  - Rest: one tap in the workout timer sheet sets the default rest for all (non-stretch) exercises and saves it (`defaultRestS` setting; also in Profile). Stretches default to 10 s. Per-exercise rest via ⋮.
  - Tracking type per exercise (weight × reps / reps / time) from ⋮ in a workout or the exercise detail page; saved globally.
  - Timed sets (stretches, plank…): ▶ starts a countdown (default 30 s), beep at the end, set marked done, rest, then the next timed set starts automatically (same exercise, or the next exercise if it is timed). One `RunningTimer` in `WorkoutSession` drives rest / set timer / standalone countdown / stopwatch (bottom bar).
  - Hold an exercise name and drag to reorder in a workout.
  - Every slider/± value can also be typed (`lib/ui/number_input.dart`: `EditableNumber`, `promptNumber`, rest picker with Custom).
- Next: BLE HR source (flutter_blue_plus), plate/1RM calculators, exercise history/progress chart, edit past workouts, swap exercise, template folders, body-map muscle filter.
- Owner preferences: clean, short exercise names; popular items first; everything adjustable both by tapping presets and by typing a value.
- **DB changes checklist** (a forgotten migration broke the live preview on 2026-11-02): add the column as nullable/defaulted, bump `schemaVersion`, add an `onUpgrade` step, and extend `test/migration_test.dart` (it builds an old-version DB file and opens it with the current code). `_addMissingColumns()` in `beforeOpen` is only a safety net.
- State management: plain `ChangeNotifier` + `InheritedWidget` (`Services`, `HrScope`) – no package yet.
- Tests: `flutter test`. Widget tests use an in-memory DB; don't close it inside `testWidgets` (hangs in the fake clock).
- The repo is **public** (made public 2026-11-01 so GitHub Pages is free). Pages source = GitHub Actions; every push to `main` deploys the web preview to https://dankarmazin-a11y.github.io/HRzones/. The iOS job runs only on `main` / manual dispatch.

## Working conventions
- Small, working increments; every push to `main` should build green.
- Prefer well-maintained packages (e.g. sqflite/drift, flutter_blue_plus, fl_chart); avoid anything that needs a paid entitlement until Phase 4.
- Keep this file updated when a decision changes or a phase completes.
- Format Dart with plain `dart format lib test` (page width 120 comes from `analysis_options.yaml`; don't pass `-l`); CI fails on unformatted code.
