# Smartwatch apps – plan (owner, 2026-11-16)

Owner's wish: HR Zones on every smartwatch that takes apps – **Galaxy Watch first**, then **Apple Watch**.
Order (owner said yes, 2026-11-16): finish the Android phone app (Phase 5 steps 8–9) → Galaxy Watch app →
Apple Watch app together with the paid Apple account (Phase 6 beta).

## A. Galaxy Watch (Wear OS) – Phase 5b
- Works on **Galaxy Watch 4 and newer** (Wear OS). Older Tizen watches (Watch 3, Active 2) are not supported.
  Owner has a Galaxy Watch – exact model still to come. Galaxy Watches pair only with Android phones.
- Separate small **native Kotlin** app (Compose for Wear OS) in `wear/` with the same app id family
  (`com.hrzones.app`), shipped inside the same Google Play listing. Flutter is not used on the watch.
- Heart rate from the watch sensor: **Health Services** (`ExerciseClient` for workouts, `MeasureClient` otherwise).
- Talks to the phone with the **Wearable Data Layer** (MessageClient / DataClient): watch → phone heart rate
  (a new `HeartRateSource` on the phone: "Galaxy Watch"), phone → watch zone range, workout state, timers.
- Plan, one PR per step:
  1. `wear/` module + CI builds a watch APK artifact (Linux, no Mac).
  2. Watch shows live heart rate (Health Services) and the zone colour.
  3. Data Layer link: heart rate to the phone app as a heart-rate source; zone range from the phone.
  4. Zone alerts on the wrist: vibration patterns (3 = above, 2 = below) + optional beep; same 5 s grace / cooldown.
  5. Start / pause / finish a run or strength workout from the watch; workout card on the watch (time, HR, zone,
     rest countdown, Set done / Skip rest).
  6. Screen-off / always-on display, battery check, ongoing activity (Wear OS) so it keeps running.
  7. Owner test on the watch (install via ADB over Wi-Fi from Windows until Google Play testing; steps from Claude).
  8. Ship in the Google Play closed test with the phone app.
- Effort: about the size of the Android phone port (Phase 5 steps 1–7) plus the owner's test rounds.

## B. Apple Watch (watchOS) – Phase 6
- **Needs the paid Apple Developer account** ($99/year): watch heart rate requires the HealthKit entitlement, and
  Sideloadly with a free Apple ID can't install watch apps properly. Same purchase unlocks AirPods heart rate.
- **Needs someone with an Apple Watch to test** (owner has none – borrow, buy, or a beta tester). Claude can write
  and build it in CI without one, but it is not shipped untested.
- SwiftUI watchOS app inside the iOS project (`ios/`), `HKWorkoutSession` + `HKLiveWorkoutBuilder` on the watch,
  WatchConnectivity to the phone. Same feature list as the Galaxy Watch app (steps 2–6). Distributed with TestFlight.
- Effort: similar to the Galaxy Watch app.
