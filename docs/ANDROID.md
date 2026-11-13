# Android – rules for Phase 5 (written 2026-11-13, start only when the owner says "go")

Owner decision (2026-11-13): **Android comes before the beta**, and the closed beta runs on
iPhone and Android together. Until the owner says go, nothing here is built. Background and
sources: `docs/REVIEW.md` §3–4.

## A. General rules
1. **Same app, same code.** Everything is shared Flutter/Dart; only the small native parts get an
   Android twin in Kotlin (`android/app/src/main/kotlin/...`), on the **same channel names and
   methods** as the Swift ones (`hrzones/beeper`, `hrzones/motion`, `hrzones/live`), so Dart
   code doesn't change.
2. **The iPhone must not get worse.** Every Android change keeps all iPhone tests green and the
   iPhone build green. One theme per PR.
3. **No crash when a native part is missing.** Every channel call already catches
   `MissingPluginException` (beeper, motion, live card) – keep that for new channels.
4. **Package check before use** (pub.dev publisher, licence, Android support, recent releases).
   No paid or "phone-home" packages (same rule as flutter_blue_plus).
5. **Android builds run in CI on free Linux runners** (`ubuntu-latest`) – they don't use the
   scarce Mac minutes. Debug APK for the owner, signed App Bundle (AAB) later for Google Play.
   The signing key is a GitHub secret, never in the repo; keep a backup of it (losing it means
   a new app on Google Play).
6. **Target the newest Android** Google Play asks for (targetSdk 36 since Aug 2026); minimum
   Android 8 (API 26) unless a package needs more.
7. **Test on a real Android phone** (owner or a friend) with the `docs/PHONE_CHECK.md` list –
   one Samsung if at all possible (the strictest about background apps).

## B. Sounds, beeps and voice (BeeperPlugin → Kotlin)
8. Short generated sounds with low delay (`AudioTrack`), same `SoundEvent` / `SoundChoice` list.
9. **Play over music**: request *transient audio focus with ducking*
   (`AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`), give it back right after the sound.
10. Voice = Android **TextToSpeech** (English voice, female/male choice like iOS), ducking music
    while talking.
11. Sounds keep working with the screen off → only inside the foreground service (rule 13).

## C. Staying alive in the background
12. Android kills apps far more than iOS. **Every live workout and run runs a foreground
    service** with an ongoing notification ("Run · 3.2 km · 18:40").
13. Service types must match the work (Android 14+ checks): **location** for outdoor runs and
    GPS Run sets; **health** (or the type Google accepts for fitness) for strength workouts,
    treadmill runs and interval timers. Never `dataSync` (stopped after 6 h on Android 15).
14. GPS updates come from the service, not the screen.
15. **Battery-saver guide** in Settings for Samsung / Xiaomi / OnePlus / Huawei
    ("Don't optimise", "Autostart") – link dontkillmyapp.com steps per brand. Ask once at the
    first workout, like the notification permission.
16. Restore after the app was killed works the same as on iPhone (already in Dart).

## D. Lock screen / notification card
17. iPhone's lock-screen card → Android **ongoing notification**, promoted as a **Live Update**
    on Android 16 (progress-centric notification) – same `LiveCard` data (title, detail, clock,
    countdown, metrics). Buttons (Set done / Skip rest / Start) as notification actions → the
    same `handleCardAction`.

## E. Heart rate
18. **No AirPods heart rate on Android.** Live sources: Bluetooth straps (flutter_reactive_ble
    supports Android) – later perhaps a Wear OS app. Say this plainly in the app on Android.
19. Health Connect = a store, not a live feed: only for **saving** finished workouts/runs
    (Phase 6+, optional).

## F. Sensors
20. Steps / cadence: Android step-counter sensor + **Physical activity** permission.
21. Climb: pressure sensor (barometer) when the phone has one; otherwise GPS height (as now).

## G. Permissions (ask only when needed, explain in plain words)
22. Location (while using) for runs; background location only if really needed.
23. Notifications (Android 13+) – at the first workout, like iOS.
24. Bluetooth scan/connect (Android 12+) when picking a strap; older Android also needs location.
25. Exact alarms for the "rest is over" notification are restricted (Android 14+): use the
    foreground service's own timer instead of exact alarms where possible.

## H. Screens and layout
26. **Edge-to-edge** is forced on new Android: check every screen for content under the status
    bar and the system navigation bar (SafeArea / view padding), especially the bottom bar with
    the Train button, full-screen timers and the live run screen.
27. **Back gesture**: never lose a workout or run by swiping back – the workout and run screens
    ask or go back to the app, never discard.
28. Fonts, colours and Material look are shared – no iOS-only widgets. Check the keyboard bar
    (Next / Done) with Android keyboards.
29. Vibration differs per phone: keep haptics short and optional.

## I. Files, backup and sharing
30. Backup save / restore through the Android share sheet and file picker; the `.hrzbackup`
    file may need "any file" in the picker. Backups are the same format on both phones (a
    backup from iPhone restores on Android and back).

## J. Store and beta
31. Google Play developer account (one-time $25), privacy page (data stays on the phone),
    Data safety form, content rating, screenshots.
32. Closed beta on both platforms at the same time: TestFlight (iPhone) + Google Play closed
    testing (Android). Google Play needs a minimum number of testers for a set time before a
    public release on new personal accounts – check the current rule at that time.
33. Map tiles must come from a provider that allows apps before the beta (see REVIEW.md §2). Now: Stadia Maps (key from the `STADIA_KEY` secret). Owner's later plan: **Google Maps on Android**, Apple Maps on iPhone.
