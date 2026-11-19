import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../platform/phone_system.dart';

/// Wraps every screen (MaterialApp.builder):
///
/// - **Text size cap.** The phone's "font size" setting is followed up to [maxTextScale].
///   Above that, labels like "Overview", "Threshold" or "kg lifted" broke in the middle of
///   the word (Samsung phones often have a bigger font set). Found on the owner's Galaxy,
///   2026-11-19.
/// - **Android navigation bar.** Android apps are drawn under the system navigation bar
///   (edge-to-edge). With the 3-button bar, the end of long pages ("No strength sets in
///   this period yet.", the run summary) stayed hidden behind it. On Android the app now
///   stops above the bar, the way the iPhone app stops above the home bar; the strip
///   behind the bar gets the page colour.
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child, this.keepAboveNavBar = false});

  /// Android app: true (see [AppFrame.forPlatform]).
  final bool keepAboveNavBar;
  final Widget child;

  static const maxTextScale = 1.15;

  factory AppFrame.forPlatform({required Widget child}) => AppFrame(keepAboveNavBar: isAndroidApp, child: child);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scaled = mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: maxTextScale));
    final bar = keepAboveNavBar ? mq.viewPadding.bottom : 0.0;
    if (bar <= 0) return MediaQuery(data: scaled, child: child);
    // The app ends above the bar: nothing below it is under the bar any more, and the
    // keyboard (measured from the bottom of the screen) covers that much less of the app.
    final inner = scaled.copyWith(
      padding: scaled.padding.copyWith(bottom: 0),
      viewPadding: scaled.viewPadding.copyWith(bottom: 0),
      viewInsets: scaled.viewInsets.copyWith(bottom: math.max(0, scaled.viewInsets.bottom - bar)),
      size: Size(scaled.size.width, scaled.size.height - bar),
    );
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.only(bottom: bar),
        child: MediaQuery(data: inner, child: child),
      ),
    );
  }
}
