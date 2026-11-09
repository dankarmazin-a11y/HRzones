# HR Zones – task list (written 2026-11-09 while GitHub was suspended)

First thing when GitHub is back: merge PR #37 (scroll-jump fix, one row per one-sided
set with ✓L ✓R, pinned progress line, "Run" button at the bottom, bigger lock-screen card),
then work through this list. Run ONE iOS build at a time (no parallel macOS runs).

## A. Bugs (from the owner's strength workouts, 9 Nov)
1. **Workout clock freezes.** The big clock in the workout header only ticks while a
   rest/set timer runs (`session.ticks` changes only then); after "Rest 00:01" ended it
   stayed at 18:55. Give the header its own 1 s ticker while a workout is open.
2. **Permanent (sticky) notes don't stick.** The note is saved, but the exercise page is
   opened with the workout card's old copy of the exercise (`widget.exercise`) and the
   card keeps that copy too – so the note looks erased and never shows in the workout.
   Re-read the exercise from the DB when the page opens and refresh the card's exercise
   after editing (also for tracking type / each-side changes).
3. **Strength moves filed as "stretching"** in free-exercise-db land in the Stretching
   card: Superman, Scissor Kick, Split Squats, Sit Squats, Crossover Reverse Lunge,
   Pelvic Tilt Into Bridge, Front / Rear / Side Leg Raises, One Handed Hang, Shoulder
   Raise, Windmills. Re-categorise them in `tool/build_exercises.py` (strength, timed
   where it fits) and bump `exerciseSeedVersion`. Foam-roll exercises → their own
   "Mobility" group instead of stretches.
4. **Two "Stretching" cards** in one workout: one is an interval timer preset named
   "Stretching" (Timers type). Show interval-timer exercises with a timer icon and a
   "Timer ·" label so they can't be mistaken for the stretching card.

## B. Strength workout improvements
5. **Home › Strength (quick workout) offers templates**: a sheet with "Empty workout" plus
   the templates (folders), like the Strength tab.
6. **Tick sets from the lock screen**: a ✓ button on the lock-screen card / Dynamic Island
   for the current set (interactive Live Activity, App Intents, iOS 17+). Also "Skip rest".
7. **One-sided sets (on top of PR #37):** the left side is the full row; the right side is
   a collapsed line under it that copies the left values. Tap its weight/reps to give the
   right side a different number.
8. **Small yellow label next to the exercise name** when it has a permanent note.
9. **Repeat cycles for timed exercises / stretches**: set the number of rounds (e.g. run
   the whole stretch list 3×, or a timed hold 3 × 30 s) and ▶ chains through all of them.
10. **Reorder like the owner's video (Hevy-style):** hold an exercise name → all cards
   collapse in place to a compact list → drag → release → cards expand again (no
   separate sheet).
11. **Full-screen timer end:** keep the big ✓, then close by itself after ~1.5 s and go
   back to the workout. **Remove the confetti 🎉** everywhere (interval "Done" screen too).

## C. Running (done already – for the record)
Red "Discard workout" button, stacked Save / Keep going / Discard, 10 new sounds,
lock-screen card (works on the phone), barometer climb, calories, nicer splits,
cleaner height chart, small map credit – all merged. Splits chart may still get more
polish later.

## D. New features (later)
12. **Custom running plan by weeks**: build a plan of N weeks, choose the run for each day
   (easy / long / intervals / rest, distance or time, can use the planned runs), see
   "today's run", tick days off as runs are recorded. Owner's own plan – the app doesn't
   coach.
13. **Closest goal on Home**: the goal nearest to completion (or the next date-bound one)
   shown at the top of Home and updated live.
14. **Onboarding walk-through for new users**: level, where you train, goals, heart-rate
   zones (age / max HR), weekly target, units – sets everything up on first launch.
15. **Ready-made ab workouts with a follow-along timer** (like YouTube ab videos):
   exercise + countdown + "next up", pictures, rest between.

## Suggested order
A1–A4 (bugs) → B11, B8, B5 (quick wins) → B7, B9, B10 → B6 (lock-screen buttons) →
D13 → D12 → D14 → D15.
