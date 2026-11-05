import 'geo.dart';

/// Spoken updates during a run: every km (or ½ / 2 km) the distance, time,
/// average pace, the last km's pace and the heart rate; plus start, pause,
/// resume and finish. Speaks through the beeper (music is turned down).
/// What the regular updates say (besides the distance).
enum VoiceItem {
  time('Time'),
  avgPace('Average pace'),
  lastSplit('Last km pace'),
  currentPace('Current pace'),
  heartRate('Heart rate'),
  cadence('Cadence');

  const VoiceItem(this.label);
  final String label;
}

class RunVoice {
  RunVoice(this._speak);

  final Future<void> Function(String text, {String voice}) _speak;

  /// Setting `runVoiceItems` (names, comma-separated).
  Set<VoiceItem> items = {VoiceItem.time, VoiceItem.avgPace, VoiceItem.lastSplit, VoiceItem.heartRate};

  /// Setting `runVoiceKind`: "default", "female" or "male".
  String kind = 'default';

  /// Setting `spokenAlerts` (default on): heart-rate and pace alerts are
  /// also said ("Heart rate 168. Slow down.").
  bool spokenAlerts = true;

  /// Setting `runVoice` (default on).
  bool enabled = true;

  /// Setting `runVoiceEvery`: metres between updates (500, 1000, 2000).
  int everyM = 1000;

  double _next = 1000;
  Duration _lastMarkTime = Duration.zero;

  /// Everything said (for tests / debugging).
  final said = <String>[];

  void _say(String text, {bool force = false}) {
    if (!enabled && !force) return;
    said.add(text);
    _speak(text, voice: kind);
  }

  /// "Test voice" in Settings (also when updates are off).
  void test() =>
      _say('2 kilometres. Time 11 minutes 40 seconds. Average pace 5 minutes 50 per kilometre.', force: true);

  /// Heart rate out of the zone during a run.
  void heartRateAlert({required bool high, required int bpm}) {
    if (spokenAlerts) _say('Heart rate $bpm. ${high ? 'Slow down' : 'Speed up'}.', force: true);
  }

  /// Pace out of the target range ([tooFast] = faster than the range).
  void paceAlert({required bool tooFast, required double pace}) {
    if (spokenAlerts) _say('Pace ${spokenPace(pace)}. ${tooFast ? 'Slow down' : 'Speed up'}.', force: true);
  }

  void started() {
    _next = everyM.toDouble();
    _lastMarkTime = Duration.zero;
    _say('Run started.');
  }

  /// The app was reopened during a run: continue from where it is.
  void restored(double distanceM, Duration moving) {
    _next = ((distanceM ~/ everyM) + 1) * everyM.toDouble();
    _lastMarkTime = moving;
  }

  void paused() => _say('Run paused.');
  void resumed() => _say('Run resumed.');

  /// [newRecords]: record distance (m) → new fastest time (s).
  void finished(double distanceM, Duration moving, {Map<int, double> newRecords = const {}}) {
    final pace = paceSecPerKm(distanceM, moving.inMilliseconds / 1000);
    _say(
      [
        'Run complete.',
        '${spokenKm(distanceM)} in ${spokenDuration(moving)}.',
        if (pace != null && distanceM >= 200) 'Average pace ${spokenPace(pace)}.',
        for (final e in newRecords.entries)
          'New record! Fastest ${e.key == 21097 ? 'half marathon' : spokenKm(e.key.toDouble())}, '
              '${spokenDuration(Duration(seconds: e.value.round()))}.',
      ].join(' '),
    );
  }

  /// Called on every GPS fix.
  void progress(double distanceM, Duration moving, {int? bpm, double? currentPace, double? cadence}) {
    if (distanceM < _next) return;
    // Interpolating isn't worth it: a fix comes every second.
    final mark = _next;
    while (_next <= distanceM) {
      _next += everyM;
    }
    final avg = paceSecPerKm(distanceM, moving.inMilliseconds / 1000);
    final lastPart = paceSecPerKm(everyM.toDouble(), (moving - _lastMarkTime).inMilliseconds / 1000);
    _lastMarkTime = moving;
    _say(
      [
        '${spokenKm(mark)}.',
        if (items.contains(VoiceItem.time)) 'Time ${spokenDuration(moving)}.',
        if (avg != null && items.contains(VoiceItem.avgPace)) 'Average pace ${spokenPace(avg)}.',
        if (currentPace != null && items.contains(VoiceItem.currentPace)) 'Current pace ${spokenPace(currentPace)}.',
        if (lastPart != null && mark > everyM && items.contains(VoiceItem.lastSplit))
          'Last ${switch (everyM) {
            500 => 'half kilometre',
            1000 => 'kilometre',
            _ => spokenKm(everyM.toDouble()),
          }} ${spokenPace(lastPart)}.',
        if (bpm != null && items.contains(VoiceItem.heartRate)) 'Heart rate $bpm.',
        if (cadence != null && items.contains(VoiceItem.cadence)) 'Cadence ${cadence.round()}.',
      ].join(' '),
    );
  }
}

/// "1 kilometre", "2.5 kilometres", "5.24 kilometres".
String spokenKm(double metres) {
  final km = metres / 1000;
  final whole = (km - km.roundToDouble()).abs() < 0.005;
  final text = whole ? '${km.round()}' : km.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  return '$text ${text == '1' ? 'kilometre' : 'kilometres'}';
}

/// "1 hour 5 minutes", "28 minutes 10 seconds", "45 seconds".
String spokenDuration(Duration d) {
  String unit(int n, String one) => '$n ${n == 1 ? one : '${one}s'}';
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  if (h > 0) return [unit(h, 'hour'), if (m > 0) unit(m, 'minute')].join(' ');
  if (m > 0) return [unit(m, 'minute'), if (s > 0) unit(s, 'second')].join(' ');
  return unit(s, 'second');
}

/// "5 minutes 32 per kilometre".
String spokenPace(double secPerKm) {
  final s = secPerKm.round();
  final m = s ~/ 60, rest = s % 60;
  return '$m ${m == 1 ? 'minute' : 'minutes'}${rest == 0 ? '' : ' $rest'} per kilometre';
}
