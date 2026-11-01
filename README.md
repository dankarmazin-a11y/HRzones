# HR Zones – Phase 0

Proof of concept: live heart rate from AirPods Pro 3 on iPhone, with beeps when you leave your target range.

## Build (no Mac needed)
1. Upload this folder's contents to a new GitHub repository (keep the `.github` folder).
2. Go to **Actions → Build IPA → Run workflow** (it also runs on every push to `main`).
3. When it finishes (~5–10 min), open the run and download **HRZones-ipa** (a zip containing `HRZones.ipa`).

## Install (Windows)
1. Install iTunes and iCloud from apple.com (not the Microsoft Store versions), then Sideloadly.
2. Connect the iPhone by USB, tap "Trust" on the phone.
3. Drag `HRZones.ipa` into Sideloadly, enter your Apple ID, click Start.
4. On the iPhone: Settings → Privacy & Security → Developer Mode → On (restart), then
   Settings → General → VPN & Device Management → trust your Apple ID.
5. Free Apple ID: the app expires after 7 days – re-run Sideloadly to refresh.

## Test checklist
- [ ] App opens, "Test HIGH/LOW beep" plays sound.
- [ ] Start workout → Health permission screen appears → allow all.
- [ ] Heart rate appears within ~30 s (log shows "First heart rate received").
- [ ] Set Max below your current HR → beeps after ~5 s.
- [ ] Lock the screen with music playing → beeps still come.
- [ ] Finish & save → workout appears in the Fitness/Health app.

If something fails, the **Diagnostics log** at the bottom of the screen shows why.
