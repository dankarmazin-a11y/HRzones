import 'geo.dart';

/// Spoken updates during a run: every km (or ½ / 2 km) the distance, time,
/// average pace, the last km's pace and the heart rate; plus start, pause,
/// resume and finish. Speaks through the beeper (music is turned down).
class RunVoice {
  RunVoice(this._speak);

  final Future<void> Function(String text) _speak;

  /// Setting `runVoice` (default on).
  bool enabled = true;

  /// Setting `runVoiceEvery`: metres between updates (500, 1000, 2000).
  int everyM = 1000;

  double _next = 1000;
  Duration _lastMarkTime = Duration.zero;

  /// Everything said (for tests / debugging).
  final said = <String>[];

  void _say(String text) {
    if (!enabled) return;
    said.add(text);
    _speak(text);
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

  void finished(double distanceM, Duration moving) {
    final pace = paceSecPerKm(distanceM, moving.inMilliseconds / 1000);
    _say(
      [
        'Run complete.',
        '${spokenKm(distanceM)} in ${spokenDuration(moving)}.',
        if (pace != null && distanceM >= 200) 'Average pace ${spokenPace(pace)}.',
      ].join(' '),
    );
  }

  /// Called on every GPS fix.
  void progress(double distanceM, Duration moving, {int? bpm}) {
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
        'Time ${spokenDuration(moving)}.',
        if (avg != null) 'Average pace ${spokenPace(avg)}.',
        if (lastPart != null && mark > everyM)
          'Last ${switch (everyM) {
            500 => 'half kilometre',
            1000 => 'kilometre',
            _ => spokenKm(everyM.toDouble()),
          }} ${spokenPace(lastPart)}.',
        if (bpm != null) 'Heart rate $bpm.',
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
