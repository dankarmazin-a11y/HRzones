import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Tells the user that rest is over while the phone is locked or another app
/// is open: a notification scheduled for the end of the rest (it vibrates
/// and shows on the lock screen). In the app itself nothing is shown – the
/// ding and a light vibration are enough.
abstract class RestNotifier {
  /// Asks iOS for permission (once). True if notifications are allowed.
  Future<bool> requestPermission();

  /// Shows "Rest is over" in [after] (replaces an earlier one).
  Future<void> scheduleRestOver(Duration after, {String? next});

  Future<void> cancel();

  /// "Still working out?" in [after], for a workout left open (replaces an
  /// earlier one).
  Future<void> scheduleIdle(Duration after, {required String workout});

  Future<void> cancelIdle();

  /// "Still running?" in [after] – a run still recording without movement,
  /// or paused for a long time (replaces an earlier one).
  Future<void> scheduleRunIdle(Duration after, {required bool paused});

  Future<void> cancelRunIdle();

  static RestNotifier create() => kIsWeb ? SilentRestNotifier() : LocalRestNotifier();
}

class LocalRestNotifier extends RestNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const _id = 1;
  static const _idleId = 2;
  static const _runIdleId = 3;

  // Android notification channels (the user can switch each one off in the phone's settings).
  static const _restChannel = AndroidNotificationDetails(
    'rest',
    'Rest timer',
    channelDescription: 'Tells you when your rest is over',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
  );
  static const _reminderChannel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Asks when a workout has been open for a long time',
  );

  /// Android shows a notification even while the app is open (iPhone hides them with
  /// `presentAlert: false`), so the owner kept getting "Rest is over" / "Still working
  /// out?" on top of the app (2026-11-19). On Android a notification is only handed to the
  /// phone while the app is in the background: kept here while the app is open, scheduled
  /// when it goes to the background, taken back when it comes to the front again.
  final _waiting = <int, ({DateTime at, String title, String body, NotificationDetails details})>{};
  bool _inFront = true;
  AppLifecycleListener? _life;

  static bool get _onlyInBackground => defaultTargetPlatform == TargetPlatform.android;

  void _watchApp() {
    if (!_onlyInBackground || _life != null) return;
    _inFront =
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.hidden;
    _life = AppLifecycleListener(
      onStateChange: (state) {
        final front = state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
        if (front == _inFront) return;
        _inFront = front;
        front ? _takeBack() : _handOver();
      },
    );
  }

  Future<void> _handOver() async {
    final now = DateTime.now();
    for (final MapEntry(key: id, value: n) in [..._waiting.entries]) {
      if (!n.at.isAfter(now)) {
        _waiting.remove(id);
        continue;
      }
      await _zoned(id, n.title, n.body, n.at.difference(now), n.details);
    }
  }

  Future<void> _takeBack() async {
    for (final id in _waiting.keys) {
      try {
        await _plugin.cancel(id: id);
      } catch (_) {}
    }
  }

  Future<void> _schedule(int id, String title, String body, Duration after, NotificationDetails details) async {
    if (_onlyInBackground) {
      _waiting[id] = (at: DateTime.now().add(after), title: title, body: body, details: details);
      if (_inFront) return;
    }
    await _zoned(id, title, body, after, details);
  }

  Future<void> _zoned(int id, String title, String body, Duration after, NotificationDetails details) =>
      _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.now(tz.UTC).add(after),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

  Future<void> _cancel(int id) async {
    _waiting.remove(id);
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<bool> _init() async {
    if (_ready) return true;
    _watchApp();
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          // Android: small white heart in the status bar (res/drawable/ic_notification.xml).
          android: AndroidInitializationSettings('ic_notification'),
          // Don't ask at start-up; only when the user turns it on.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
    return _ready;
  }

  @override
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> scheduleRestOver(Duration after, {String? next}) async {
    if (!await _init()) return;
    try {
      await _schedule(
        _id,
        'Rest is over',
        next == null ? 'Time for your next set' : 'Next: $next',
        after,
        const NotificationDetails(
          android: _restChannel,
          // Inside the app (foreground) stay quiet: the app dings itself.
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentBanner: false,
            presentList: false,
            presentSound: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Could not schedule the rest notification: $e');
    }
  }

  @override
  Future<void> cancel() => _cancel(_id);

  @override
  Future<void> scheduleIdle(Duration after, {required String workout}) async {
    if (!await _init()) return;
    try {
      await _schedule(
        _idleId,
        'Still working out?',
        '"$workout" is still open. Tap to finish it or keep going.',
        after,
        const NotificationDetails(
          android: _reminderChannel,
          // In the app the same question is asked on screen instead.
          iOS: DarwinNotificationDetails(presentAlert: false, presentBanner: false, presentList: false),
        ),
      );
    } catch (e) {
      debugPrint('Could not schedule the reminder: $e');
    }
  }

  @override
  Future<void> cancelIdle() => _cancel(_idleId);

  @override
  Future<void> scheduleRunIdle(Duration after, {required bool paused}) async {
    if (!await _init()) return;
    try {
      await _schedule(
        _runIdleId,
        'Still running?',
        paused
            ? 'Your run has been paused for a long time. Tap to finish it.'
            : 'Your run is still recording but you haven\'t moved for 20 minutes. Tap to finish it.',
        after,
        const NotificationDetails(
          android: _reminderChannel,
          iOS: DarwinNotificationDetails(presentAlert: false, presentBanner: false, presentList: false),
        ),
      );
    } catch (e) {
      debugPrint('Could not schedule the run reminder: $e');
    }
  }

  @override
  Future<void> cancelRunIdle() => _cancel(_runIdleId);
}

/// Web preview and tests: records what would happen.
class SilentRestNotifier extends RestNotifier {
  final scheduled = <Duration>[];
  int cancelled = 0;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleRestOver(Duration after, {String? next}) async => scheduled.add(after);

  @override
  Future<void> cancel() async => cancelled++;

  final idleScheduled = <Duration>[];
  int idleCancelled = 0;

  @override
  Future<void> scheduleIdle(Duration after, {required String workout}) async => idleScheduled.add(after);

  @override
  Future<void> cancelIdle() async => idleCancelled++;

  final runIdleScheduled = <(Duration, bool)>[];
  int runIdleCancelled = 0;

  @override
  Future<void> scheduleRunIdle(Duration after, {required bool paused}) async => runIdleScheduled.add((after, paused));

  @override
  Future<void> cancelRunIdle() async => runIdleCancelled++;
}
