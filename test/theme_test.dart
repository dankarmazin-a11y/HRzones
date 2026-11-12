import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/app.dart';
import 'package:hrzones/data/exercise_repository.dart';
import 'package:hrzones/ui/screens/settings_screen.dart';
import 'package:hrzones/ui/theme/app_theme.dart';

import 'app_test.dart' show settle, tearDownApp;
import 'test_helpers.dart';

void main() {
  test('every palette builds a light and a dark theme with the shared colours', () {
    for (final p in AppPalette.values) {
      for (final b in Brightness.values) {
        final t = buildAppTheme(p, b);
        final x = t.extension<AppTheme>()!;
        expect(x.bright, p.bright);
        expect(x.second, p.second);
        expect(t.colorScheme.brightness, b);
        // Light: ink buttons; dark: bright buttons.
        expect(t.colorScheme.primary, b == Brightness.light ? p.ink : p.bright);
        expect(t.textTheme.headlineMedium!.fontWeight, FontWeight.w800);
      }
    }
    expect(AppPalette.byName('nope'), AppPalette.orange);
    expect(AppPalette.byName('pink'), AppPalette.pink);
    expect(onColor(const Color(0xFFFFC63E)), isNot(Colors.white));
    expect(onColor(const Color(0xFF141B2B)), Colors.white);
  });

  test('new users start with Orange and follow the phone', () async {
    final s = await testServices();
    expect(s.palette.value, AppPalette.orange);
    expect(s.themeMode.value, ThemeMode.system);
  });

  testWidgets('Settings › Theme: pick a palette and light/dark, both saved', (tester) async {
    final s = (await tester.runAsync(testServices))!;
    await tester.pumpWidget(HrZonesApp(services: s));
    await settle(tester);
    final nav = Navigator.of(tester.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    await settle(tester);
    expect(find.text('Orange · follows the phone'), findsOneWidget);
    await tester.tap(find.byKey(const Key('themeRow')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('palette_mint')));
    await settle(tester);
    await tester.tap(find.text('Dark'));
    await settle(tester);
    expect(s.palette.value, AppPalette.mint);
    expect(s.themeMode.value, ThemeMode.dark);
    expect(await tester.runAsync(() => s.db.getSetting('palette')), 'mint');
    expect(await tester.runAsync(() => s.db.getSetting('theme')), 'dark');
    // The whole app re-themes.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
    expect(app.darkTheme!.extension<AppTheme>()!.bright, AppPalette.mint.bright);
    await tearDownApp(tester, s);
  });
}
