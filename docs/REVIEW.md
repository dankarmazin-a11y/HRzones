# HR Zones – Phase 4 review (2026-11-13)

Phase 4 is now **a full check of the app** (owner, 2026-11-13). HealthKit / TestFlight
(the old Phase 4) moves to Phase 5 and still waits for the paid Apple account.

## 1. Fixed in the first round (PR "Phase 4 fixes")
| # | Problem | Fix |
|---|---------|-----|
| 1 | Zone beeps / monitoring kept running after a strength workout ended (battery, beeps at home) | Monitoring started by the workout's zone stops at Finish / Discard (`_hrStartedByWorkout`). Monitoring you started yourself stays on. |
| 2 | App closed by iOS mid-run → run restored without zone beeps | `RunSession.restore` re-applies the run's zone (`presetFor`), and switches it off again at the end. Respects "zones off". |
| 3 | Finishing / discarding a workout during a GPS "Run" set left GPS on | `stopSetRun(save: false)` in finish and discard. |
| 4 | Editing a past workout dropped sets that only had metres | `saveEdits` keeps sets with metres. |
| 5 | Rare: an automatic save landing after Save could make a finished run reopen as "still running" | `_saveRun` without an end is skipped while finishing. |
| 6 | Add set didn't copy metres (8 × 1 km) | `addSet` copies `distanceM`. |
| 7 | Backups loaded every GPS point with every column name repeated; restore did one INSERT per point | Backup **format 2**: columns once + rows as lists, read in pages of 5000, packed on a background isolate; restore writes 100 rows per INSERT. Format-1 backups still restore. |

Tests: `test/phase4_fixes_test.dart` (incl. a 12,000-point backup round trip). 253 tests green.

## 2. Core problems (today, iPhone)
1. **The main promise isn't live yet.** Real heart rate today = Bluetooth strap only, and that was never tried with a real strap. AirPods / Apple Watch heart rate needs HealthKit = paid account.
2. **App Store risk – background audio (guideline 2.5.4).** We keep the audio session on so timers and a treadmill run keep working with the screen locked. Apple rejects apps that declare background audio without *audible* background audio. Our beeps, dings and voice are audible, but the review notes must show this step by step, and silent holds should stay as short as possible.
3. **Map tiles.** We use `tile.openstreetmap.org`. Its policy doesn't allow heavy use by distributed apps (they can block us without notice). Fine for one person; **before testers / the store we need a tile provider that allows apps** (free tiers exist; the key is visible in the app, so restrict it).
4. **Data lives only on the phone.** Deleting the app, or a Sideloadly install that fails, loses everything except the manual backup. Automatic iCloud backup needs the paid account.
5. **Native iPhone code has no automatic tests.** Beeps, voice, lock-screen card, step counter, barometer: CI compiles them but can't run them. Only the owner's phone checks them.
6. **Two very large files.** `active_workout_screen.dart` (~2000 lines) and `workout_session.dart` (~1460 lines). Every change there is risky and harder to review.
7. **Builds depend on scarce Mac runners** (often no machine; the account was suspended once after many parallel builds).

## 3. Problems to expect on Android
| Area | What breaks / is missing | What we'll need |
|------|-------------------------|-----------------|
| Sounds, beeps, voice | Today they're iPhone code (`BeeperPlugin.swift`): on Android the app stays **silent** (no crash – checked) | Android version: short sounds + "duck" over music (audio focus), Text-to-Speech for voice |
| Staying alive in the background | Android kills background apps much harder than iOS; Samsung and Xiaomi are known for stopping workout apps | A **foreground service** with a running notification (type *location* for runs; Android 14+ checks the type), plus an in-app "don't optimise battery" guide per brand |
| Lock-screen card | ActivityKit is iPhone-only | Android 16 **Live Updates** (an ongoing notification promoted to the lock screen / status chip) |
| Heart rate | No AirPods heart rate on Android. Health Connect is a store, not a live feed | Bluetooth straps (our BLE package supports Android); later maybe a Wear OS app |
| Step counter / barometer | iPhone code (`MotionPlugin.swift`) | Android step-counter and pressure sensors + "Physical activity" permission |
| Permissions | Different set: notifications (13+), Bluetooth scan/connect (12+), exact alarms for the rest notification (restricted on 14+), background location | New permission flow and texts |
| Screen layout | New Android versions force edge-to-edge: the bottom bar with the Train button and full-screen timers can slide under the system bar; the back gesture can close a workout screen | Safe-area check on every screen; back-gesture guard on the workout / run screens |
| Store | Google Play needs targetSdk 36 for new apps; a $25 developer account; many phone models | An Android build in CI (free Linux runners) and testing on a real Android phone |

## 4. What the web says about apps like ours and code written with an AI – and what we do about it
| Known problem | Our case | What we do |
|---------------|----------|-----------|
| AI-written changes come as big PRs that are hard to review | Some rounds touched 20+ files | One theme per PR; big files split (move 4) |
| AI tools invent package names (attackers register them – "slopsquatting") | 15 packages | Rule: every new package is checked on pub.dev (publisher, licence, activity) and listed in CLAUDE.md before use; `pubspec.lock` stays committed |
| Security holes (leaked keys, unsafe input) | No server, no accounts; but the repo is **public** | No key ever in the repo; Apple / map keys only as GitHub secrets or restricted keys |
| Hand-written database migrations lose data | 15 schema versions | `migration_test.dart` opens every old version; backups keep both formats; rule stays: new columns nullable/defaulted |
| Tests that are green but check nothing | 253 tests | Each bug fix gets a test that failed before the fix |
| Fitness apps killed in the background (Android brands) | Android later | Foreground service + battery guide (section 3) |
| App Store background-audio rejections | We hold audio for timers | Review notes + audible-only holds (section 2) |

## 5. Five new moves (proposed)
1. **Phone check list** (`docs/PHONE_CHECK.md`): a 10-minute test the owner runs on each new IPA for what CI can't test – locked-screen beeps over music, voice, lock card, rest ding, GPS run, backup/restore.
2. **Problem log on the phone** (no analytics, nothing leaves the phone): the app keeps its last errors; Settings › "Report a problem" shares them with me in one tap.
3. **Android build in CI now** (free Linux runners, no Mac minutes): add the Android project and a build job, so Android problems show up early – sounds etc. come later.
4. **Split the two giant workout files** into smaller parts with no change in behaviour, guarded by the 253 tests.
5. **Clear the two store blockers early**: switch map tiles to a provider that allows apps, and write the App Store review notes for background audio.

Sources: OSM tile policy (operations.osmfoundation.org/policies/tiles), Apple developer forums on guideline 2.5.4,
dontkillmyapp.com, developer.android.com (Health Connect, Android 16 behaviour changes), Flutter breaking change
"default SystemUiMode edge-to-edge", drift migration docs, Trend Micro / CSA on slopsquatting, 2026 studies on
AI-generated code (Veracode, Secure Code Warrior).
