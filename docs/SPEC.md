# HR Zones – Product Spec (v0.1, 2026-11-01)

Living copy of the spec. The original (Hebrew) doc with diagrams: https://claude.ai/artifact/Gsd5SEisYsqUoYhzcE3uxs

## 1. Vision
One app for the hybrid athlete: a strength log on par with Hevy, run tracking on par with Nike Run Club, and live heart-rate zone monitoring with audible alerts – no watch required (AirPods Pro 3).

- **Problem:** people who mix lifting and running juggle 2–3 apps. None of them beeps when heart rate leaves a self-set range, and strength apps ignore heart rate.
- **Solution:** one place for all workouts, metrics and progress, with live HR (AirPods Pro 3, watch or chest strap) on every workout and beep alerts.
- **Positioning:** "The only log that understands both sets and kilometres – and keeps you in the right HR zone without looking at the screen."
- **Name:** TBD (working name: HR Zones).

## 2. Audience
Primary: hybrid athletes with an iPhone training 3–6×/week. First user: the owner.

| Persona | Who | Needs | Pain today |
| --- | --- | --- | --- |
| The hybrid (primary) | Strength 2–4×/wk + running 2–3×/wk, iPhone + AirPods Pro 3 | One log, HR zones on easy runs, body-weight tracking | Two apps, no HR alerts, no full picture |
| Zone 2 trainee | Runs by heart rate, builds aerobic base | Beep the moment HR leaves range, no screen glancing | Alert apps are paid and separate from the log |
| Lifter starting to run | Coming from Hevy/Strong | Add runs without switching apps | Strength apps track runs poorly |

Out of scope for now: personal trainers and their clients, pro athletes, cyclists with dedicated sensors.

## 3. Product principles
1. **Hands-free during a workout** – everything works by voice or a single tap, big readable buttons in sunlight.
2. **Log a set in 3 seconds** – previous values prefilled; completing a set starts the rest timer.
3. **Offline first** – full function without network; sync in the background later.
4. **The user owns the data** – full export anytime, Apple Health / Health Connect sync, zero data sales.
5. **HR on every workout, not just runs** – shared layer for strength and running, incl. recovery between sets.
6. **Simple surface, depth one tap away.**

## 4. MVP scope
iPhone only, single user, all three pillars. Goal: replace Hevy + NRC for a full month.

| Area | In MVP | Later |
| --- | --- | --- |
| Heart rate | AirPods Pro 3 via HealthKit*, BLE straps, simulated HR, personal range, 5 zones, beeps | Watches, resting HR, HRV |
| Strength | ~800-exercise DB, templates, sets/weight/reps, rest timer, PRs | Advanced supersets, animations, ready-made programs |
| Running | GPS, map, pace, splits, voice every km | Structured intervals, saved routes, treadmill |
| Body | Weight, circumferences, body fat, charts | Progress photos, goals |
| Data | Local storage, Health export, file export | Accounts, cloud sync |
| Platform | iPhone, English (Hebrew later) | Android, Apple Watch, widgets |

\* HealthKit requires the paid Apple Developer account (see CLAUDE.md).

Fully out of scope now: social feed, AI coach, nutrition, payments.

## 5. Requirements – heart rate & zones
Live HR is shown and monitored in every workout type; beeps work with the screen locked and music playing.

**Sources:** HealthKit live workout (AirPods Pro 3 / Powerbeats Pro 2 / Apple Watch – iOS picks the best source); BLE Heart Rate Profile (0x180D) straps/armbands; simulated HR for development.

**Zones & ranges:** 5 zones from max HR (default 220 − age) or manual; per-workout target range (preset zone e.g. "Zone 2" or free min/max); saved range profiles ("Easy run", "Tempo", "Strength").

**Alerts:**
- Above range: 3 sharp beeps. Below: 2 deep beeps.
- Optional voice ("Heart rate 162, slow down") or haptic instead.
- Flood control: alert only after 5 s continuously out of range, hysteresis of 2 bpm to return, minimum gap between alerts (default 10 s).
- Plays over music without stopping it; volume control.
- Strength workouts: optional "recovery" alert – beep when HR drops to a set value (ready for next set).

**Display & summary:** big number in zone colour, live chart of last 5 min; summary with avg/max HR, time per zone, % time in range; weak-signal state: no reliable reading for 15 s → show "--" and pause alerts (optional warning tone).

## 6. Requirements – strength & exercise DB
**Exercise DB:** free-exercise-db (~800 exercises: primary muscle, secondary muscles, equipment, instructions, images); search + filter by muscle and equipment with a tappable body map (front/back); custom exercises; tracking type per exercise: weight × reps, bodyweight (+/− added), time, distance.

**Templates:** create ("Push A"), reorder exercises, target sets/reps; folders, duplicate, start empty workout.

**During a workout:** per set weight, reps, optional RPE, set type (warm-up / normal / drop / failure); previous values shown and tap-to-fill; automatic rest timer with sound, default per exercise; supersets, exercise notes, swap exercise mid-workout; plate calculator and 1RM calculator; live HR in the header and max HR stored per set.

**After:** summary (duration, volume kg×reps, sets, new PRs, muscles worked, HR); PRs per exercise (max weight, est. 1RM, best set volume, max reps); saved to Health as Traditional Strength Training.

## 7. Requirements – running & cardio
NRC-level tracking, no coach, no guided plans. MVP activities: run, walk, outdoor cycling; treadmill / indoor cardio as HR + time only.

**During:** main screen time, distance, current & average pace, HR + zone – readable at arm's length; live map on a second screen; manual + auto pause; voice every km (distance, time, km pace, avg HR) – interval and content configurable; works with screen locked, Live Activity on lock screen / Dynamic Island (needs paid account).

**After:** route map coloured by pace or HR zone; km split table (pace, avg HR, elevation); pace/HR/elevation charts; PRs: 1 km, 5 km, 10 km, half marathon, longest run; saved to Health with route.

## 8. Body metrics, history & stats
- **Body:** weight, body fat %, circumferences (editable list); read/write weight & body fat from Health; chart per metric with 7-day moving average.
- **History:** combined feed (strength + runs), year calendar heat map; edit/delete past workouts, add manually.
- **Stats:** weekly workouts, strength volume, km, time per HR zone; sets per muscle group per week with coloured body map; progress chart per exercise (max weight, est. 1RM); pace-at-same-HR trend (simple aerobic fitness metric).

## 9. Screens & flows
| Tab | Contents |
| --- | --- |
| Home | Weekly summary, last workout, quick start (strength / run / template) |
| Workouts | Templates, exercise DB, history |
| Progress | Stats, PRs, muscle map, body metrics |
| Profile | HR zones & range profiles, alert settings, units, permissions, export |

Key flows:
1. **First launch (≤2 min):** age & weight → Health permission → headphones check + sample beep → pick first template.
2. **Strength:** template → HR profile (optional) → log sets + rest → finish → summary & PRs.
3. **Run:** HR profile → 3 s countdown → run with beeps + km announcements → long-press stop → summary with map.
4. **Weigh-in:** from Home, two taps.

## 10. Data model
All workout types share one Workout entity. Every record: UUID + updatedAt (for future sync). PRs and stats are computed from sets, not stored, so editing old workouts updates them.

| Entity | Main fields |
| --- | --- |
| Exercise | name, primaryMuscle, secondaryMuscles, equipment, trackingType, images, isCustom |
| Template | name, folder, TemplateExercise[] (exercise, order, targetSets, rest, supersetGroup) |
| Workout | type (strength/run/walk/cycle/other), start, end, templateId, hrProfileId, notes, healthKitId |
| WorkoutSet | workoutId, exerciseId, index, setType, weightKg, reps, durationS, distanceM, rpe, maxHr, completedAt |
| RouteSample | workoutId, time, lat, lon, altitude, speed |
| Split | workoutId, km, durationS, avgHr, elevationDelta |
| HeartRateSample | workoutId, time, bpm, source (airpods/watch/strap/simulated) |
| HRProfile | name, min, max, alertType, cooldownS |
| BodyMeasurement | date, kind, value, unit, source (manual/health) |
| UserSettings | age, maxHr, zones, units, language, voicePrefs |

## 11. Architecture
Flutter from day one (shared ~most of the code), with thin native modules per platform via Platform Channels:
- **Shared (Flutter):** UI, workout engine (sets, timers, zones), stats & PRs, local DB (SQLite, offline).
- **iOS module (Swift, MVP):** HealthKit (HR + saving workouts), CoreLocation (background GPS), AVAudioSession (beeps over music).
- **Android module (Kotlin, later):** Health Connect, Location, Foreground Service for background beeps.
- **Devices:** AirPods Pro 3 / Apple Watch (iOS); smartwatch / BLE chest strap (both).
- **Cloud (later):** accounts, sync, backup.
- **Build without a Mac:** GitHub Actions builds the IPA on a cloud Mac; Sideloadly on Windows installs it. UI also iterated via a Flutter web preview.

## 12. Privacy & security
- Minimal permissions: read HR, weight, workouts; write workouts, routes, weight. Location only during an active workout.
- Each permission asked in context with an explanation; the app works (minus that part) if declined.
- No ads, no third-party analytics touching health data (also an Apple rule for HealthKit apps).
- Full export (JSON/CSV) and delete-all inside the app.
- When cloud is added: encryption in transit and at rest, EU servers (GDPR), written privacy policy before App Store.
- Not a medical device: disclaimer on first launch, no diagnoses or medical advice.

## 13. Success metrics
| Stage | Metric | Target |
| --- | --- | --- |
| Personal use | Workouts logged in the app vs all workouts | 100% over 4 weeks |
| Personal use | Runs where HR + beeps worked start to finish, incl. locked screen | > 95% |
| Personal use | Time to log a set | ≤ 3 s |
| Closed beta (20–50) | Testers still training with the app after 4 weeks | > 40% |
| Closed beta | Workouts per active user per week | > 3 |
| Closed beta | Testers using HR alerts | > 50% |

## 14. Roadmap
Phase 0 feasibility (done) → **gate:** HealthKit with free signing? (No → paid account later) → Phase 1 strength log → Phase 2 running → Phase 3 body & progress → **gate:** a full month without Hevy/NRC → Phase 4 closed beta (Developer account, TestFlight, Live Activity) → **gate:** > 40% testers still training after 4 weeks → Phase 5 public product (cloud, Android, design, App Store). No dates – pace depends on the owner's testing time.

## 15. Risks & open questions
| Risk | Impact | Response |
| --- | --- | --- |
| Free signing strips HealthKit entitlement (**confirmed in Phase 0**) | No AirPods HR | Simulated + BLE HR now; paid account at the gate |
| Beeps stop when screen locks | Core feature broken | Background audio mode + active workout; test with a 30-min run |
| Live Activity / widgets don't work with free signing | Less convenient locked-screen UX | Deferred to Phase 4 |
| No simulator | Slow fixes | Web preview + CI logs; Android emulator possible later |
| HR accuracy drops in cold / poor fit | False beeps | Weak-signal state + flood control |
| Scope creep | MVP never ships | Every new idea goes to the "Later" column |

Open questions:
- [ ] App name
- [x] Flutter vs React Native → **Flutter**
- [x] MVP UI language → **English** (Hebrew later)
- [ ] Ready-made strength programs (PPL, Upper/Lower) in MVP?
- [ ] Structured run intervals in MVP or later?
- [ ] Future business model: free, subscription, or one-time purchase?
