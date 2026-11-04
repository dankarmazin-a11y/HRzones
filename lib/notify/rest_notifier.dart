import 'package:flutter/foundation.dart';
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

  static RestNotifier create() => kIsWeb ? SilentRestNotifier() : LocalRestNotifier();
}

class LocalRestNotifier extends RestNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const _id = 1;

  Future<bool> _init() async {
    if (_ready) return true;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
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
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> scheduleRestOver(Duration after, {String? next}) async {
    if (!await _init()) return;
    try {
      await _plugin.zonedSchedule(
        id: _id,
        title: 'Rest is over',
        body: next == null ? 'Time for your next set' : 'Next: $next',
        scheduledDate: tz.TZDateTime.now(tz.UTC).add(after),
        notificationDetails: const NotificationDetails(
          // Inside the app (foreground) stay quiet: the app dings itself.
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentBanner: false,
            presentList: false,
            presentSound: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Could not schedule the rest notification: $e');
    }
  }

  @override
  Future<void> cancel() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
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
}
