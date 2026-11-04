# HR Zones – project brief for Claude

Read this first in every session. The full product spec is in `docs/SPEC.md`.

## What we're building
One iPhone app for hybrid athletes (strength + running): a Hevy-level strength log, Nike-Run-Club-level run tracking (tracking only, no coaching), body metrics, and **live heart-rate zone monitoring with audible beeps** when the user leaves a target range – during any workout, screen locked, music playing.

The owner is not a developer. Explain steps plainly, keep instructions short, and do the technical work yourself (commit, push, read CI logs, fix).

**Owner rules:**
- After every change, always send the **web preview link** (https://dankarmazin-a11y.github.io/HRzones/ – updates ~5 min after the PR is merged) and the IPA link.
- In conversation, **"workout" means any training** – strength or running.

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
- **Phase 1 – Flutter skeleton + strength log (feature-complete, owner testing):** 4 tabs (Home, Workouts, Progress, Profile); local DB; HR source interface with simulated + BLE sources; beep engine (native iOS module); exercise DB with muscle filters; templates; live workout logging (sets, weight, reps, RPE, set types, previous values, rest timer, supersets); post-workout summary and PRs; web preview + IPA in CI.
- **Phase 2 – running:** GPS route + map, pace, km splits, voice announcements, HR zones on route, PRs (1k/5k/10k/HM).
- **Phase 3 – body & progress:** ~~weight, body fat, circumferences, charts~~ (done early in Profile), muscle heat map, weekly stats, export (JSON/CSV).
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
- Done (owner feedback round 2, 2026-11-02):
  - Stretching session: stretches added to a workout/template are grouped into one "Stretching" card (container exercise `hz_stretching`, hidden from the list); each row is a different stretch (`workout_sets.sub_exercise_id`, `template_exercises.sub_exercise_ids`, schema v3) with optional +KG (assisted) and seconds; ▶ chains through the rows. Records/muscles use the row's stretch.
  - Timed exercises show +KG and SECONDS.
  - Timer bar: tap a stretch timer → full-screen sideways timer (`FullScreenTimer`, RotatedBox because the app is portrait-only) that follows the chain and shows "Next: …"; tap other timers → bar grows. Workout time in the header is larger.
  - Exercise pictures: `ExerciseAvatar` (first free-exercise-db photo, letter fallback; off in tests).
  - `TrackingToggle` chip on each card: tap cycles kg×reps → reps → time.
  - Hold an exercise name → compact reorder sheet (`reorder_sheet.dart`).
  - `RunningWorkoutBar` above the tabs while a workout runs (name, time, % done, current timer); replaces the Home resume banner.
- Done (Phase 1 continued, 2026-11-02):
  - **BLE heart-rate source** (`lib/hr/ble_hr_source.dart`) with **flutter_reactive_ble** (BSD-3). Decided *against* flutter_blue_plus: since v2 it needs a paid commercial license for for-profit use and sends a build-time license ping (conflicts with the App Store plan and "no analytics"). Scan → pick strap in Profile; auto-reconnect; choice saved (`hrSource` setting). iOS: `NSBluetoothAlwaysUsageDescription`, `UIBackgroundModes` += `bluetooth-central`. Not available on web. **Untested on a real strap yet.**
  - Exercise page: personal records, progress chart (fl_chart; est. 1RM / max reps / longest hold per workout) and history.
  - Plate calculator + 1RM table (⋮ on a weight exercise); swap exercise (⋮).
  - `formatKg` shows up to 2 decimals (1.25 kg plates).
- Done (Phase 1 features complete, 2026-11-04):
  - Edit past workouts and log a past workout: an edit-mode `WorkoutSession(editMode: true)` (no timers, no auto-save; `saveEdits()` writes, sets with values count as done; Cancel never deletes). `ActiveWorkoutScreen(session: …)` + `SessionScope` give the workout widgets the right session. Entry: ✎ on a past workout's summary; History → "Log past workout" (date, time, minutes).
  - Template folders (optional folder field with existing-folder chips; Workouts tab groups by folder) and duplicate/delete from the template ⋮ menu.
  - Body map (`lib/ui/body_map.dart`, CustomPainter front/back, tappable regions → muscle filter in the exercise list). Takes a `heat` map for the Phase 3 muscle heat map.
- Done (owner feedback round 3, 2026-11-04):
  - **Navigation: 5 tabs** – Home (dashboard: streak, Start tiles Strength/Run/HR Zones, goals preview, this week, last workout), Strength (old Workouts tab), Run (Phase 2 placeholder), Zones (HR monitor card, strap, zones, alerts – moved from Home/Profile), Profile (streak with weekly target, goals, body measurements, settings). `AppShell.of(context).goTo(AppTab.x)` switches tabs. Progress tab removed.
  - **Templates are edited in the workout view** (`WorkoutSession(templateMode: true)`, `openTemplateEditor`): per-set targets saved in `template_exercises.sets_json` (`TemplateSet`) and prefilled (not ticked) when a workout starts from the template. Old `TemplateEditorScreen` removed.
  - **Duplicates**: `HIDDEN` map in `tool/build_exercises.py` → `exercises.hidden` (kept for old workouts, excluded from search). Labels: abductors → "Outer thighs", adductors → "Inner thighs" etc. (`titleCase`).
  - **Body measurements** (`body_measurements` table, `BodyRepository`, `measurementKinds`), **goals** (`goals` table, `GoalRepository`: lift weight = heaviest working set, measurement = latest value, progress from start value), **weekly streak** (`lib/workout/streak.dart`, setting `weeklyTarget`).
  - Finish guard: a workout open > 4 h offers to end at the last set's time.
  - Schema **v4** (exercises.hidden, template_exercises.sets_json, body_measurements, goals); `_addMissingColumns` now also creates missing tables.
- Done (owner feedback round 4, 2026-11-04):
  - **Tabs**: Home, Strength, Run, **Timers**, Profile. HR zones is its own screen (`ZonesScreen`) opened from a card at the top of Profile and the Run tab; no longer a Home start tile.
  - **HR zone presets** (`hr_presets` table, `HrPresetRepository`, `lib/ui/hr_presets.dart`): name, min/max, use (strength/run/both). Empty workout start asks for a preset (only if presets exist); templates store `hrPresetId` and apply it on start; `PresetRow` in workouts/templates; `WorkoutSession.applyPreset` sets the range and starts monitoring (not in template/edit mode). Saved on workouts (`workouts.hr_preset_id`).
  - **Training level** (`lib/workout/training_level.dart`, setting `level`, default intermediate): exercise list filtered by free-exercise-db level (popular + custom always shown, "All levels" chip); beginners get simple muscle groups (`simpleMuscleGroups`: chest/back/shoulders/arms/core/legs/glutes) and no RPE/set types in workouts.
  - **Spreadsheet export** (`lib/export/`): own minimal .xlsx writer on `archive` (sheets Workouts / Sets / Measurements, real dates, frozen header) shared with `share_plus` (download on web). Profile → "Export to spreadsheet".
  - **Light theme** (default) / dark / auto (setting `theme`); colours that were tuned for dark fixed (`timedColor`).
  - **Timers tab**: interval presets (`interval_presets` table, `IntervalPresetRepository` with built-ins Tabata/EMOM/run intervals/plank seeded once), editor, `IntervalRunner` (get ready 3 s, beeps: 2 high = work, 1 low = rest, 3-2-1 ticks, 3 high = done; catches up after background), full-screen `IntervalRunScreen`; quick countdowns.
  - **Measurements** as 5 compact boxes (weight, body fat, waist, chest, arm) + "More".
  - Schema **v5** (exercises.level, templates/workouts.hr_preset_id, hr_presets, interval_presets).
- Performance/caching fixes (2026-11-04):
  - Timer ticks no longer call `WorkoutSession.notifyListeners()` (that rebuilt the whole workout screen 4×/s and made scrolling jerky). Clock widgets listen to `session.ticks` (changes once per second); `notifyListeners()` only on real state changes. Test in `timers_test.dart`.
  - `WorkoutRepository.watchFinished()` is one shared, linear query that only emits when finished workouts change (auto-saving the running workout used to re-run it for every Home widget).
  - Web preview cache-busting: custom `web/flutter_bootstrap.js` + CI `sed` stamp the commit id on `main.dart.js?v=` and `flutter_bootstrap.js?v=`; `APP_BUILD` dart-define shows "version <commit> <date>" at the bottom of Profile (web + IPA).
- Review/hardening (2026-11-04):
  - `Beeper.start(owner)` / `stop(owner)` are **holds** (`hr`, `workout`, `intervals`): the audio only stops when the last one is released (finishing an interval timer used to silence a running workout's HR beeps when locked).
  - A live workout holds the audio for its whole duration, so rest/set timers keep running and beeping with the screen locked even without HR alerts. Released 2 s after finish/discard.
  - Reopening the app mid-workout re-applies the workout's HR preset (monitoring + beeps back on).
  - `BeeperPlugin.swift` restarts the engine after a phone call/Siri, an output change (AirPods in/out) or a media-services reset.
  - Running workout is saved immediately when the app goes to the background (`AppLifecycleListener` in `main.dart`). Double-tapping Finish saves once.
  - BLE status says "Bluetooth is off" / "not allowed" instead of just "Reconnecting…".
  - Tests: `test/background_audio_test.dart`.
- **Phase 1 is feature-complete.** Next: owner uses it for real workouts (incl. a real BLE strap and locked-screen beeps) → fix feedback → Phase 2 (running).
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
