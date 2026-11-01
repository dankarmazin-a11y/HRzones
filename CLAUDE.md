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
- **Phase 1 – Flutter skeleton + strength log (next):** 4 tabs (Home, Workouts, Progress, Profile); local DB; HR source interface with simulated + BLE sources; beep engine (native iOS module); exercise DB with muscle filters; templates; live workout logging (sets, weight, reps, RPE, set types, previous values, rest timer, supersets); post-workout summary and PRs; web preview + IPA in CI.
- **Phase 2 – running:** GPS route + map, pace, km splits, voice announcements, HR zones on route, PRs (1k/5k/10k/HM).
- **Phase 3 – body & progress:** weight, body fat, circumferences, charts, muscle heat map, weekly stats, export (JSON/CSV).
- **Gate:** owner uses it for a full month instead of Hevy/NRC → buy Developer account.
- **Phase 4 – closed beta:** HealthKit + AirPods HR, TestFlight to 20–50 testers, Live Activity.
- **Phase 5 – public:** cloud sync, Android, design polish, App Store.

## Working conventions
- Small, working increments; every push to `main` should build green.
- Prefer well-maintained packages (e.g. sqflite/drift, flutter_blue_plus, fl_chart); avoid anything that needs a paid entitlement until Phase 4.
- Keep this file updated when a decision changes or a phase completes.
