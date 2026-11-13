import 'package:flutter/material.dart';

/// The three colour themes the user can pick (Settings › Theme). See docs/DESIGN.md.
enum AppPalette {
  mint(
    'Mint',
    ink: Color(0xFF1E2528),
    bright: Color(0xFF19E3B4),
    second: Color(0xFF8B6AD8),
    background: Color(0xFFF6F7F7),
  ),
  orange(
    'Orange',
    ink: Color(0xFF141B2B),
    bright: Color(0xFFFF7A2D),
    second: Color(0xFFFFC63E),
    background: Color(0xFFF1F2F4),
  ),
  pink(
    'Pink',
    ink: Color(0xFF1F1418),
    bright: Color(0xFFFF4F93),
    second: Color(0xFFFF8FB8),
    background: Color(0xFFF7F4F5),
  );

  const AppPalette(
    this.label, {
    required this.ink,
    required this.bright,
    required this.second,
    required this.background,
  });

  final String label;

  /// Text, buttons, chips, the Start button, timer bars.
  final Color ink;

  /// Play buttons, ticks, timer progress, the active tab.
  final Color bright;

  /// Progress lines, the Run tile, charts.
  final Color second;

  /// Light-mode page background (cards are white on it).
  final Color background;

  /// New users start with Orange.
  static const fallback = AppPalette.orange;

  static AppPalette byName(String? name) => values.where((p) => p.name == name).firstOrNull ?? fallback;
}

/// Colours every theme shares.
abstract final class AppColors {
  /// Heart-rate hearts are always this red, in every theme.
  static const heart = Color(0xFFFF3B4A);
}

/// Theme colours that ColorScheme has no slot for. `AppTheme.of(context)`.
@immutable
class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme({
    required this.ink,
    required this.bright,
    required this.onBright,
    required this.second,
    required this.onSecond,
    required this.card,
    required this.field,
    required this.track,
    required this.muted,
    required this.emblem,
    required this.cardShadow,
  });

  final Color ink;
  final Color bright;
  final Color onBright;
  final Color second;
  final Color onSecond;
  final Color card;

  /// Input fields, chip backgrounds, empty calendar days.
  final Color field;

  /// Empty part of progress bars, chart grid lines.
  final Color track;

  /// Secondary text.
  final Color muted;

  /// Soft tinted box behind emblems.
  final Color emblem;

  /// Soft shadow under cards (light mode) / faint edge (dark mode).
  final List<BoxShadow> cardShadow;

  static AppTheme of(BuildContext context) => Theme.of(context).extension<AppTheme>()!;

  @override
  AppTheme copyWith() => this;

  @override
  AppTheme lerp(AppTheme? other, double t) => t < 0.5 || other == null ? this : other;
}

/// Readable text colour on [c].
Color onColor(Color c) => c.computeLuminance() > 0.45 ? const Color(0xFF141417) : Colors.white;

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// Builds the app's ThemeData for a palette and brightness.
ThemeData buildAppTheme(AppPalette p, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? _mix(p.ink, Colors.black, 0.35) : p.background;
  final card = dark ? _mix(p.ink, Colors.white, 0.06) : Colors.white;
  final ink = dark ? _mix(p.background, Colors.white, 0.6) : p.ink;
  final muted = _mix(ink, bg, 0.45);
  final field = dark ? _mix(card, Colors.white, 0.06) : _mix(bg, p.ink, 0.05);
  final track = dark ? _mix(card, Colors.white, 0.10) : _mix(bg, p.ink, 0.09);
  // Buttons: ink in light mode, the bright colour in dark mode.
  final primary = dark ? p.bright : p.ink;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onColor(primary),
    primaryContainer: _mix(card, p.bright, dark ? 0.25 : 0.16),
    onPrimaryContainer: ink,
    secondary: p.bright,
    onSecondary: onColor(p.bright),
    secondaryContainer: _mix(card, p.bright, dark ? 0.22 : 0.14),
    onSecondaryContainer: ink,
    tertiary: p.second,
    onTertiary: onColor(p.second),
    tertiaryContainer: _mix(card, p.second, dark ? 0.25 : 0.18),
    onTertiaryContainer: ink,
    error: const Color(0xFFE5484D),
    onError: Colors.white,
    errorContainer: _mix(card, const Color(0xFFE5484D), 0.15),
    onErrorContainer: ink,
    surface: bg,
    onSurface: ink,
    onSurfaceVariant: muted,
    surfaceContainerLowest: card,
    surfaceContainerLow: card,
    surfaceContainer: dark ? _mix(card, Colors.white, 0.03) : _mix(bg, Colors.white, 0.5),
    surfaceContainerHigh: field,
    surfaceContainerHighest: track,
    outline: _mix(bg, ink, 0.3),
    outlineVariant: _mix(bg, ink, 0.12),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: dark ? Colors.white : p.ink,
    onInverseSurface: dark ? p.ink : Colors.white,
    inversePrimary: p.bright,
    surfaceTint: Colors.transparent,
  );

  const r7 = BorderRadius.all(Radius.circular(7));
  const r9 = BorderRadius.all(Radius.circular(9));
  const r10 = BorderRadius.all(Radius.circular(10));
  const r16 = BorderRadius.all(Radius.circular(16));

  final base = ThemeData(useMaterial3: true, brightness: brightness, fontFamily: 'Inter', colorScheme: scheme);
  final t = base.textTheme;
  TextStyle? w(TextStyle? s, FontWeight weight, {double? size, double? spacing}) =>
      s?.copyWith(fontWeight: weight, fontSize: size, letterSpacing: spacing, color: ink);
  final text = t.copyWith(
    displayLarge: w(t.displayLarge, FontWeight.w900, spacing: -2),
    displayMedium: w(t.displayMedium, FontWeight.w900, spacing: -1.5),
    displaySmall: w(t.displaySmall, FontWeight.w900, size: 34, spacing: -1.2),
    headlineLarge: w(t.headlineLarge, FontWeight.w800, size: 30, spacing: -1),
    headlineMedium: w(t.headlineMedium, FontWeight.w800, size: 28, spacing: -1),
    headlineSmall: w(t.headlineSmall, FontWeight.w800, size: 22, spacing: -0.6),
    titleLarge: w(t.titleLarge, FontWeight.w800, size: 20, spacing: -0.4),
    titleMedium: w(t.titleMedium, FontWeight.w700, size: 16.5, spacing: -0.2),
    titleSmall: w(t.titleSmall, FontWeight.w700, size: 14),
    bodyLarge: w(t.bodyLarge, FontWeight.w400, size: 15.5),
    bodyMedium: w(t.bodyMedium, FontWeight.w400, size: 14),
    bodySmall: t.bodySmall?.copyWith(fontSize: 12.5, color: muted),
    labelLarge: w(t.labelLarge, FontWeight.w700, size: 14),
    labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: muted),
    labelSmall: t.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: muted),
  );

  final shadow = dark
      ? const [BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 6))]
      : [
          BoxShadow(color: p.ink.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
          BoxShadow(color: p.ink.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 6)),
        ];

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    textTheme: text,
    extensions: [
      AppTheme(
        ink: ink,
        bright: p.bright,
        onBright: onColor(p.bright),
        second: p.second,
        onSecond: onColor(p.second),
        card: card,
        field: field,
        track: track,
        muted: muted,
        emblem: _mix(card, p.bright, dark ? 0.22 : 0.15),
        cardShadow: shadow,
      ),
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: card,
      surfaceTintColor: Colors.transparent,
      elevation: dark ? 0 : 1.5,
      shadowColor: p.ink.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: r10,
        side: dark ? BorderSide(color: Colors.white.withValues(alpha: 0.06)) : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: r9),
        minimumSize: const Size(48, 46),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: r9),
        backgroundColor: card,
        foregroundColor: ink,
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: r9),
        foregroundColor: ink,
        side: BorderSide(color: ink, width: 1.4),
        minimumSize: const Size(48, 44),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        shape: const RoundedRectangleBorder(borderRadius: r9),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: ink)),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: r9),
        selectedBackgroundColor: primary,
        selectedForegroundColor: onColor(primary),
        foregroundColor: ink,
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const RoundedRectangleBorder(borderRadius: r7),
      side: BorderSide.none,
      backgroundColor: field,
      selectedColor: primary,
      secondarySelectedColor: primary,
      checkmarkColor: onColor(primary),
      // Selected chips are filled with the primary colour, so their text must
      // switch to the matching "on" colour (it was invisible before).
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        color: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? onColor(primary) : ink),
      ),
      secondaryLabelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: onColor(primary)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.bright : track),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.bright : null),
      checkColor: WidgetStateProperty.all(onColor(p.bright)),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? ink : muted),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.second,
      linearTrackColor: track,
      circularTrackColor: track,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    ),
    sliderTheme: SliderThemeData(activeTrackColor: p.bright, thumbColor: p.bright, inactiveTrackColor: track),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: onColor(primary),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.bright : muted),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected) ? p.bright : muted,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: r16),
      titleTextStyle: text.titleLarge,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: r10),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: field,
      border: const OutlineInputBorder(borderRadius: r9, borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(borderRadius: r9, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: r9,
        borderSide: BorderSide(color: ink, width: 1.5),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: ink,
      titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? card : p.ink,
      contentTextStyle: const TextStyle(fontFamily: 'Inter', color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: r10),
    ),
  );
}
