# App Review notes (draft for TestFlight external testing and the App Store)

Paste the "Notes for the reviewer" part into App Store Connect › App Review Information.
Keep it up to date when background features change. Why: Apple rejects apps that declare
background modes they don't visibly use (guideline 2.5.4) – see `docs/REVIEW.md` §2.

## Notes for the reviewer

HR Zones is a workout log for strength training and running. Its main feature is **audible
heart-rate zone alerts during a workout, with the screen locked and music playing**.
No account or login is needed; all data stays on the device.

**Background modes and how to see them:**

1. **Audio** – audible beeps, bells and spoken updates while the phone is locked:
   - Open the app › tap **Train** (round button in the tab bar) › **Strength** › **Empty workout**.
   - Tap **Add exercise**, pick "Barbell Bench Press", type 60 kg and 8 reps, tap ✓.
   - A 90-second rest timer starts. Lock the phone. When it ends, a **bell sound** plays
     (it mixes with music from another app).
   - Heart-rate zone beeps: Home › Tools › **Heart-rate zones** › switch monitoring on. With the
     built-in simulated heart rate, move the slider above the zone and lock the phone: **three
     high beeps** play every ~10 s while the heart rate stays above the zone.
   - Runs: spoken updates every kilometre ("1 kilometre. Time 5 minutes…") while locked.
2. **Location** – outdoor run recording (GPS route, distance, pace) with the screen locked:
   Train › **Run** › Start. The blue location indicator shows while recording. GPS stops when the
   run is paused or finished.
3. **Bluetooth (central)** – live heart rate from a Bluetooth chest strap (Heart Rate Profile)
   during a workout: Home › Tools › Heart-rate zones › Heart-rate source › Bluetooth strap.
   The strap keeps sending heart rate while the screen is locked so the beeps keep working.
4. **Live Activity** – the lock-screen card shows the current set / run while a workout runs.

**Motion & Fitness:** step counter and barometer for running cadence and climb.
**HealthKit** (when added): reads live heart rate during a workout session from AirPods Pro /
Apple Watch for the zone alerts; saves finished workouts to Health if the user allows it.

## Before submitting – check
- [ ] Every background mode in Info.plist is used by a feature above (remove any that isn't).
- [ ] Silent audio holds are as short as possible (the engine stops a few seconds after the
      last sound; only a running workout timer or treadmill run keeps it on).
- [ ] Privacy texts (NSLocation…, NSBluetooth…, NSMotion…, NSHealth…) say why, in plain words.
- [ ] Privacy "nutrition label": Data Not Collected (no analytics, no accounts). Report a problem
      only shares what the user sends themselves.
- [ ] A short screen recording of steps 1–2 attached in App Review if asked.
