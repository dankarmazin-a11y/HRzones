import 'dart:convert';

/// "How do you like HR Zones?" 1–5 stars (owner, 2026-11-13): first a week
/// after the app was first opened, then once a month.
class RatingSchedule {
  static const firstAfter = Duration(days: 7);
  static const every = Duration(days: 30);

  /// True when it is time to ask. [lastAsked] = the last time the question
  /// was shown (answered or "Not now").
  static bool due({required DateTime now, required DateTime firstOpen, DateTime? lastAsked}) {
    if (now.difference(firstOpen) < firstAfter) return false;
    return lastAsked == null || now.difference(lastAsked) >= every;
  }
}

/// One answer (setting `ratings`, a JSON list kept on the phone).
class Rating {
  const Rating(this.at, this.stars);

  final DateTime at;
  final int stars;

  static List<Rating> decode(String? json) {
    try {
      final list = jsonDecode(json ?? '[]');
      if (list is! List) return const [];
      return [
        for (final r in list)
          if (r is Map && DateTime.tryParse(r['at'] as String? ?? '') != null && r['s'] is int)
            Rating(DateTime.parse(r['at'] as String), r['s'] as int),
      ];
    } catch (_) {
      return const [];
    }
  }

  static String encode(List<Rating> list) => jsonEncode([
    for (final r in list) {'at': r.at.toIso8601String(), 's': r.stars},
  ]);
}
