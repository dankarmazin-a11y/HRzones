# HR Zones – design (Phase 3 "UI & looks")

Decided with the owner through mockup rounds on 2026-11-12. This is the source of truth for the new look;
build screens to match it. Mockup pages (claude.ai artifacts, private to the owner): mood board, run/icons/charts,
round 2–3, profile, remaining screens, emblems.

## Themes
Three themes the user picks in Settings › Theme (a small row that opens a sheet); light / dark / follow the phone
sits inside the same sheet. New users start with **Orange**, mode **follows the phone**.

| Role | Mint | Orange | Pink |
|---|---|---|---|
| Ink (text, buttons, chips, Start button, timer bars) | `#1E2528` | `#141B2B` | `#1F1418` |
| Bright (play buttons, ticks, timer progress, active tab) | `#19E3B4` | `#FF7A2D` | `#FF4F93` |
| Second (progress lines, Run tile, charts) | `#8B6AD8` | `#FFC63E` | `#FF8FB8` |
| Background (light) | `#F6F7F7` | `#F1F2F4` | `#F7F4F5` |

- Cards are white (light) / ink lightened (dark); text on the bright colour is ink or white by contrast.
- Dark mode: background = ink darkened, cards = ink + 6 % white, buttons take the bright colour.
- **Heart-rate ♥ is always red** (`#FF3B4A`) everywhere in the app.
- Heart-rate zone colours stay the same in every theme: Z1 `#9AA6B2`, Z2 `#4A9FE8`, Z3 `#3FBF7F`, Z4 `#F5A524`, Z5 `#EF4F4F`.
- Full-screen timers and the live run stay dark with bold white digits in every theme.

## Type, shape, depth
- Font **Inter** (bundled, SIL OFL). Big tight titles: screen title 28 extra-bold (−3.5 % letter spacing),
  big numbers 34–90 black with tabular figures, card title 17 bold, text 15, details 13, labels 11 caps-free.
- Corners **medium**: cards 10, buttons 9, chips 7. Only the Start button and play buttons are fully round.
- **Soft shadows** on cards, the Start button and sheets (light mode); in dark mode a faint light top edge instead.
- One soft style for every card, chart and calendar across the app.

## Navigation
Tabs: Home · Strength · **Start** · Run · Profile. Start is a big round button (66 pt, half above the bar, ink with
a white border); it opens a sheet of big tiles: next workout, today's run, empty workout, timer. While a workout or
run is going it becomes the way back to it. Tools leave the tab bar: a row of tool boxes on Home and a Tools list in
Profile. Settings is a gear button at the top right of Profile.

## Icons and emblems
- Tab icons: outline, **filled when active**. New runner icon (leaning forward, knee up).
- Emblems: one line family (1.8 stroke, round ends) in a **soft tinted box** (bright colour ~15 % over the card),
  emblem centred. Strength workouts use the **dumbbell**. The heart emblem is red on a pale red box.

## Screens
- **Workout:** rest timer is a slim bar at the bottom (time, progress, Skip); tap opens it big (big digits, next set,
  −15 / +15 / Skip).
- **Run:** Run tab (week km bars, today's planned run, records, recent runs with route thumbnails), Ready-to-run sheet,
  live run **centred** with huge distance, map view, summary with zone-coloured route, splits, time in zones.
- **Charts:** soft (rounded bars, smooth line with soft fill, second colour); weekly training time as **side-by-side**
  bars (strength / running) with hours axis, week labels, legend and this week's total.
- **Empty screens:** guided steps – Strength: level & gym ✓, pick a program or **Create a template**, **Set a goal**,
  first workout; Run: age ✓, easy-run zone, **Set a goal**, first run.
- **Profile:** tabs Overview (all-time numbers, month calendar with day numbers in the soft style, monthly recap,
  goals with rings, tools, your data) · Records (strength + running records with dates, milestones) ·
  Body & gear (measurements, shoes with km bars).
- **Lock screen card:** glass (frosted) with the bright colour for the countdown and button.
- **Setup:** chat style (app bubbles, answer chips).
- **App icon:** heart pulse for now (name and icon will change later).
- **Later:** realistic body figures / muscle map need real artwork (buy or commission) – keep photos until then.

## Build status
Every rule above is in the app as of 2026-11-12 (steps 1–6, see CLAUDE.md › Phase 3 – UI & looks). Still open: realistic body figures (needs artwork), app name, and whether the app icon follows the theme.
