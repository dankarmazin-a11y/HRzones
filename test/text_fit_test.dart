import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/ui/app_frame.dart';
import 'package:hrzones/ui/run/run_summary_screen.dart';
import 'package:hrzones/ui/screens/settings_screen.dart';
import 'package:hrzones/ui/screens/tools_screen.dart';
import 'package:hrzones/ui/screens/zones_screen.dart';
import 'package:hrzones/ui/stats/stats_screen.dart';
import 'package:hrzones/ui/workout/workout_summary_screen.dart';
import 'package:hrzones/workout/workout_session.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

/// Words split over two lines ("Overvie / w", "Threshol / d") in every paragraph on screen.
List<String> brokenWords(WidgetTester tester) {
  final out = <String>[];
  bool letter(int c) => (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || c > 0xBF;
  final screen = Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
  // Kept-alive tabs next to the one shown are laid out too: only check what is visible.
  bool onScreen(RenderBox o) =>
      screen.overlaps(MatrixUtils.transformRect(o.getTransformTo(null), Offset.zero & o.size));
  void visit(RenderObject o) {
    // Pages under the one shown are kept but not drawn.
    if (o is RenderOffstage && o.offstage) return;
    final text = o is RenderParagraph && o.hasSize ? o.text.toPlainText(includeSemanticsLabels: false) : '';
    if (o is RenderParagraph &&
        text.length > 1 &&
        onScreen(o) &&
        o
                .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.length))
                .map((b) => b.top)
                .toSet()
                .length >
            1) {
      double? lineOf(int i) {
        final boxes = o.getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1));
        return boxes.isEmpty ? null : boxes.first.top;
      }

      for (var i = 1; i < text.length; i++) {
        if (!letter(text.codeUnitAt(i - 1)) || !letter(text.codeUnitAt(i))) continue;
        final a = lineOf(i - 1), b = lineOf(i);
        if (a != null && b != null && (b - a) > 1) {
          out.add('"${text.replaceAll('\n', ' ')}" broken at ${text.substring(0, i)}|');
          break;
        }
      }
    }
    o.visitChildren(visit);
  }

  visit(tester.binding.renderViews.first);
  return out;
}

/// The owner's Galaxy S10e has a big font set: labels broke in the middle of words
/// (2026-11-19). The phone's text size is capped at [AppFrame.maxTextScale]; every main
/// screen has to fit a small (360 pt wide) phone at that size without broken words or
/// overflow stripes.
void main() {
  // The real font: the test font has square letters, much wider than Inter.
  setUpAll(() async {
    final inter = FontLoader('Inter');
    for (final f in Directory('assets/fonts').listSync().whereType<File>().where((f) => f.path.endsWith('.ttf'))) {
      inter.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await inter.load();
  });

  testWidgets('main screens fit a small phone with a big font', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    // Bigger than the cap: the cap must apply.
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final s = (await tester.runAsync(testServices))!;
    // Something in every card: a strength workout and a run.
    final edit = WorkoutSession(workouts: s.workouts, exercises: s.exercises, hr: s.hr, editMode: true)
      ..startManual(DateTime.now().subtract(const Duration(hours: 3)), const Duration(minutes: 45));
    await tester.runAsync(() async => edit.addExercises([(await s.exercises.byId('Barbell_Bench_Press'))!]));
    final set = edit.active!.exercises.single.sets.single;
    edit.setWeight(set, 60);
    edit.setReps(set, 8);
    final summary = (await tester.runAsync(edit.saveEdits))!;
    final runId = (await tester.runAsync(
      () => s.runs.logRun(
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        durationS: 1800,
        distanceM: 5200,
        avgHr: 150,
      ),
    ))!;

    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    expect(
      MediaQuery.of(tester.element(find.byType(HomeShell))).textScaler.scale(10),
      closeTo(10 * AppFrame.maxTextScale, 0.01),
    );

    final problems = <String>[];
    // Overflow stripes etc.: collect them all instead of stopping at the first.
    final errors = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      final where = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(d.toString())?.group(0) ?? '';
      errors.add('${d.exceptionAsString().split('\n').first} $where');
    };
    Future<void> check(String screen) async {
      await settle(tester);
      // Down the whole page, a screen at a time.
      for (var page = 0; page < 12; page++) {
        for (final w in brokenWords(tester)) {
          problems.add('$screen: $w');
        }
        final scrollables = find.byType(Scrollable).hitTestable();
        if (scrollables.evaluate().isEmpty) break;
        final pos = tester.state<ScrollableState>(scrollables.first).position;
        if (pos.axis != Axis.vertical || pos.pixels >= pos.maxScrollExtent) break;
        pos.jumpTo((pos.pixels + 500).clamp(0, pos.maxScrollExtent));
        await settle(tester);
      }
      for (final e in errors.toSet()) {
        problems.add('$screen: $e');
      }
      errors.clear();
    }

    final shell = find.byType(HomeShell);
    for (final tab in ['Home', 'Strength', 'Cardio']) {
      await tester.tap(find.text(tab).last);
      await check(tab);
    }
    await tester.tap(find.text('Profile').last);
    await settle(tester);
    for (final t in ['overview', 'records', 'body']) {
      await tester.tap(find.byKey(Key('profileTab_$t')));
      await check('Profile $t');
    }

    final nav = Navigator.of(tester.element(shell));
    final pages = <String, Widget>{
      'Stats': const StatsScreen(),
      'Settings': const SettingsScreen(),
      'Tools': const ToolsScreen(),
      'Zones': const ZonesScreen(),
      'Run summary': RunSummaryScreen(runId: runId),
      'Workout summary': WorkoutSummaryScreen(summary: summary),
    };
    for (final MapEntry(key: name, value: page) in pages.entries) {
      nav.push(MaterialPageRoute<void>(builder: (_) => page));
      await check(name);
      nav.pop();
      await settle(tester);
    }

    FlutterError.onError = original;
    expect(problems, isEmpty, reason: problems.join('\n'));
    await tearDownApp(tester, s);
    edit.dispose();
  });

  testWidgets('Android: the app stops above the 3-button navigation bar', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.viewPadding = const FakeViewPadding(bottom: 48 * 3);
    tester.view.padding = const FakeViewPadding(bottom: 48 * 3);
    addTearDown(tester.view.reset);

    late MediaQueryData inside;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppFrame(keepAboveNavBar: true, child: child!),
        home: Builder(
          builder: (context) {
            inside = MediaQuery.of(context);
            return const Scaffold(body: SizedBox.expand(key: Key('page')));
          },
        ),
      ),
    );
    expect(inside.padding.bottom, 0);
    expect(tester.getBottomLeft(find.byKey(const Key('page'))).dy, 740 - 48);
  });
}
