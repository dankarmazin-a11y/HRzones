import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// One error the app noticed by itself (a crash in a screen, a failed save…).
class ProblemEntry {
  const ProblemEntry({required this.at, required this.message, this.where});

  final DateTime at;
  final String message;

  /// The first lines of the stack trace (where in the code it happened).
  final String? where;

  Map<String, Object?> toJson() => {'at': at.toIso8601String(), 'm': message, if (where != null) 'w': where};

  static ProblemEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final at = DateTime.tryParse(j['at'] as String? ?? '');
    final m = j['m'];
    if (at == null || m is! String) return null;
    return ProblemEntry(at: at, message: m, where: j['w'] as String?);
  }
}

/// The app's own error log for "Report a problem" (owner, 2026-11-13).
/// Stays on the phone: nothing is sent anywhere unless the user shares a
/// report. Keeps the last [maxEntries] errors (setting `problemLog`).
class ProblemLog extends ChangeNotifier {
  ProblemLog._();

  /// One log for the whole app; errors can happen before the database opens.
  static final instance = ProblemLog._();

  static const maxEntries = 30;

  /// Lines of the stack trace kept per error.
  static const stackLines = 6;

  final _entries = <ProblemEntry>[];
  List<ProblemEntry> get entries => List.unmodifiable(_entries.reversed); // newest first

  Future<void> Function(String json)? _save;

  /// Connects the log to the database: loads the saved errors and saves new
  /// ones (set by AppServices once the database is open).
  void attach({required String? saved, required Future<void> Function(String json) save}) {
    final before = List.of(_entries); // errors from before the database opened
    _entries.clear();
    try {
      final list = jsonDecode(saved ?? '[]');
      if (list is List) _entries.addAll(list.map(ProblemEntry.fromJson).whereType<ProblemEntry>());
    } catch (_) {}
    _entries.addAll(before);
    _trim();
    _save = save;
    if (before.isNotEmpty) _scheduleSave();
    notifyListeners();
  }

  void record(Object error, [StackTrace? stack]) {
    final where = stack?.toString().split('\n').where((l) => l.trim().isNotEmpty).take(stackLines).join('\n');
    var message = error.toString();
    if (message.length > 500) message = '${message.substring(0, 500)}…';
    // The same error over and over (e.g. every frame) counts once a minute.
    final last = _entries.lastOrNull;
    final now = DateTime.now();
    if (last != null && last.message == message && now.difference(last.at) < const Duration(minutes: 1)) return;
    _entries.add(ProblemEntry(at: now, message: message, where: where));
    _trim();
    _scheduleSave();
    // Called from error handlers, possibly in the middle of a build.
    scheduleMicrotask(notifyListeners);
  }

  void clear() {
    _entries.clear();
    _scheduleSave();
    notifyListeners();
  }

  void _trim() {
    if (_entries.length > maxEntries) _entries.removeRange(0, _entries.length - maxEntries);
  }

  /// Saves right away, one save after the other (no timer: errors are rare
  /// and repeats are already counted once a minute).
  Future<void> _saving = Future.value();

  void _scheduleSave() {
    final save = _save;
    if (save == null) return;
    final json = jsonEncode([for (final e in _entries) e.toJson()]);
    _saving = _saving.then((_) => save(json)).catchError((Object _) {});
  }

  /// Forgets everything (tests).
  @visibleForTesting
  void reset() {
    _entries.clear();
    _save = null;
  }
}
