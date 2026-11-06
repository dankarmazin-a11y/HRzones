/// Everything in the app that makes a sound. Each one can use its own sound
/// (Settings › Sounds); "classic" is the sound it always had.
enum SoundEvent {
  zoneHigh('Above your zone', 'Heart rate too high', count: 3, frequency: 1200),
  zoneLow('Below your zone', 'Heart rate too low', count: 2, frequency: 500),
  restOver('Rest is over', 'End of the rest timer', count: 1, classicDing: true),
  switchSides('Switch sides', 'Between left and right of a timed hold', count: 1, frequency: 1100),
  setTimerOver('Timed set done', 'End of a plank, stretch…', count: 2, frequency: 880),
  countdownOver('Countdown done', 'Quick timers', count: 3, frequency: 880),
  intervalWork('Interval: work', 'A work period starts', count: 2, frequency: 1100),
  intervalRest('Interval: rest', 'A rest period starts', count: 1, frequency: 550),
  intervalTick('Interval: 3-2-1', 'Last seconds before the next period', count: 1, frequency: 880),
  intervalDone('Interval: finished', 'The whole interval timer is done', count: 3, frequency: 1200),
  paceFast('Run: too fast', 'Faster than your target pace', count: 2, frequency: 1500),
  paceSlow('Run: too slow', 'Slower than your target pace', count: 1, frequency: 400);

  const SoundEvent(this.label, this.description, {required this.count, this.frequency = 880, this.classicDing = false});

  final String label;
  final String description;

  /// How many times the sound plays (3 high beeps, 2 low…).
  final int count;

  /// Pitch of the classic beep.
  final double frequency;

  /// The classic sound is the bell "ding" (end of rest).
  final bool classicDing;
}

/// Sounds the user can pick. All are generated on the phone (no files).
enum SoundChoice {
  classic('Classic'),
  high('High beep'),
  low('Low beep'),
  ding('Bell'),
  chime('Chime'),
  click('Wood click'),
  buzz('Buzzer'),
  whistle('Whistle'),
  // Added 2026-11-06 (stored by name – order doesn't matter).
  marimba('Marimba'),
  sonar('Sonar ping'),
  rising('Rising'),
  falling('Falling'),
  digital('Digital watch'),
  gong('Gong'),
  fanfare('Fanfare'),
  drop('Water drop'),
  triangle('Triangle'),
  horn('Horn');

  const SoundChoice(this.label);

  final String label;
}
