import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../hr/zones.dart';
import '../../workout/training_level.dart';
import '../../workout/training_place.dart';
import '../number_input.dart';
import '../theme/app_theme.dart';
import '../theme/emblems.dart';
import '../theme/heart_logo.dart';
import '../../units/units.dart';

/// First launch: setup slides (owner, 19 Nov – was a chat) – what you
/// train, your level, where you train, age (heart-rate zones), workouts per
/// week and body weight / a goal. The coach asks on the left, your answers
/// appear on the right; every answer is saved right away; "Skip" keeps the
/// defaults. Settings › "Run the setup again" shows it again.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Focus {
  strength('Strength'),
  running('Cardio'),
  both('Both – hybrid');

  const _Focus(this.label);
  final String label;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// The question being asked (0 = welcome … 7 = all set).
  int _step = 0;
  _Focus? _focus;
  late TrainingLevel _level;
  late TrainingPlace _place;
  late int _age;
  late int _weekly;
  // Typed in the chosen weight unit (kg or lb); stored in kg.
  double? _weight;
  double? _goalWeight;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final s = Services.of(context);
    _level = s.level.value;
    _place = s.place.value;
    _age = s.hr.age;
    _weekly = s.weeklyTarget.value;
  }

  void _next() {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = true;
      _step++;
    });
  }

  Future<void> _finish() async {
    final s = Services.of(context);
    if (_weight != null) await s.body.add('weight', Units.fromW(_weight!));
    if (_goalWeight != null && _weight != null && _goalWeight != _weight) {
      await s.goals.addMeasurement('weight', Units.fromW(_goalWeight!));
    }
    await s.finishOnboarding();
  }

  String _kg(double v) => '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)} ${Units.w}';

  /// The text under each slide's headline.
  String _body(int step) {
    final zones = HrZones.fromAge(_age);
    return switch (step) {
      0 =>
        'Strength log, runs, walks and rides – and a beep when your heart rate leaves your zone, even with the '
            'screen locked and music playing. A few quick questions?',
      1 => 'We\'ll put the right things first.',
      2 => 'It decides which exercises and options you see.',
      3 => 'The exercise list shows what you can do there.',
      4 =>
        'For your heart-rate zones: max heart rate about ${zones.maxHr} bpm, easy zone 2 is '
            '${zones.zones[1].minBpm}–${zones.zones[1].maxBpm} bpm.',
      5 => 'Strength and cardio both count toward your weekly streak.',
      6 => 'Optional – for calories and progress. Add a goal weight to see it on Home.',
      _ => '',
    };
  }

  void _back() {
    if (_step == 0 || _step >= 7) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = false;
      _step--;
    });
  }

  /// Slides move left going on, right going back.
  bool _forward = true;

  /// The big headline on each slide.
  String _title(int step) => switch (step) {
    0 => 'Train in your zone.',
    1 => 'What do you train?',
    2 => 'Your training level',
    3 => 'Where do you train?',
    4 => 'How old are you?',
    5 => 'Workouts a week?',
    6 => 'Your body weight',
    _ => 'You\'re all set',
  };

  /// The picture box at the top of each slide.
  Widget _art(BuildContext context, int step) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    Widget box(Color bg, Widget child) => Container(
      key: Key('slideArt_$step'),
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
      alignment: Alignment.center,
      child: child,
    );
    Widget icons(List<EmblemKind> kinds, Color color) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final k in kinds)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: EmblemIcon(k, size: 56, color: color),
          ),
      ],
    );
    final soft = t.bright.withValues(alpha: 0.14);
    return switch (step) {
      0 => box(t.ink, const HeartLogo(size: 110)),
      1 => box(soft, icons([EmblemKind.dumbbell, EmblemKind.run, EmblemKind.bike], t.ink)),
      2 => box(soft, icons([EmblemKind.kettlebell, EmblemKind.plates], t.ink)),
      3 => box(soft, Icon(_place.icon, size: 72, color: t.ink)),
      4 => box(
        AppColors.heart.withValues(alpha: 0.12),
        Text('$_age', style: text.displayLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -2)),
      ),
      5 => box(soft, icons([EmblemKind.calendar], t.ink)),
      6 => box(soft, Icon(Icons.monitor_weight_outlined, size: 72, color: t.ink)),
      _ => box(t.ink, icons([EmblemKind.flag], t.bright)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    final step = _step.clamp(0, 7);
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          // swipe right = back a slide (answers are already saved)
          onHorizontalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 300) _back();
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    if (step > 0 && step < 7)
                      IconButton(
                        key: const Key('onboardingBack'),
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _back,
                      )
                    else
                      const SizedBox(width: 48, height: 48),
                    const Spacer(),
                    if (step < 7)
                      TextButton(key: const Key('skipOnboarding'), onPressed: _finish, child: const Text('Skip')),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, anim) {
                    final incoming = child.key == ValueKey(step);
                    final dir = (_forward == incoming) ? 1.0 : -1.0;
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: Offset(0.25 * dir, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(step),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        _art(context, step),
                        const SizedBox(height: 22),
                        Text(
                          _title(step),
                          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.6),
                        ),
                        const SizedBox(height: 8),
                        if (step < 7)
                          Text(_body(step), style: text.bodyLarge?.copyWith(color: t.muted))
                        else
                          _done(context),
                        const SizedBox(height: 18),
                        _input(context),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  key: const Key('slideDots'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i <= 7; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == step ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == step ? t.bright : t.muted.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// What you can answer with at the current step.
  Widget _input(BuildContext context) {
    final s = Services.of(context);
    return switch (_step) {
      0 => _NextButton(label: 'Let\'s go', onTap: _next),
      1 => _chips<_Focus>(_Focus.values, _focus, (f) => f.label, (f) {
        setState(() => _focus = f);
        s.setFocus(f.name);
        _next();
      }),
      2 => _chips<TrainingLevel>(TrainingLevel.values, null, (l) => l.label, (l) {
        setState(() => _level = l);
        s.setLevel(l);
        _next();
      }),
      3 => _chips<TrainingPlace>(TrainingPlace.values, null, (p) => p.label, (p) {
        setState(() => _place = p);
        s.setPlace(p);
        _next();
      }),
      4 => _ageInput(context),
      5 => Wrap(
        alignment: WrapAlignment.start,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var n = 1; n <= 7; n++)
            ChoiceChip(
              key: Key('weekly_$n'),
              label: Text('$n', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              selected: false,
              onSelected: (_) {
                setState(() => _weekly = n);
                s.setWeeklyTarget(n);
                _next();
              },
            ),
        ],
      ),
      6 => _weightInput(context),
      _ => _NextButton(label: 'Start training', onTap: _finish),
    };
  }

  Widget _chips<T>(List<T> values, T? selected, String Function(T) label, ValueChanged<T> onSelect) => Wrap(
    alignment: WrapAlignment.start,
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        ActionChip(
          key: Key('choice_$v'),
          label: Text(label(v), style: const TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () => onSelect(v),
        ),
    ],
  );

  Widget _ageInput(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    void set(int a) {
      final v = a.clamp(10, 99);
      setState(() => _age = v);
      s.hr.setAge(v);
    }

    final zones = HrZones.fromAge(_age);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(icon: const Icon(Icons.remove), onPressed: () => set(_age - 1)),
            InkWell(
              key: const Key('ageValue'),
              borderRadius: BorderRadius.circular(9),
              onTap: () async {
                final v = await promptNumber(context, title: 'Your age', initial: _age, min: 10, max: 99);
                if (v != null) set(v.round());
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Text('$_age', style: text.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
              ),
            ),
            IconButton.filledTonal(icon: const Icon(Icons.add), onPressed: () => set(_age + 1)),
          ],
        ),
        Center(child: Text('Max heart rate about ${zones.maxHr}', style: text.labelMedium)),
        const SizedBox(height: 8),
        _NextButton(label: 'That\'s me', onTap: _next),
      ],
    );
  }

  Widget _weightInput(BuildContext context) {
    Future<double?> ask(String title, double? initial) async {
      final v = await promptNumber(
        context,
        title: title,
        initial: initial,
        min: Units.lb ? 66 : 30,
        max: Units.lb ? 660 : 300,
        decimal: true,
      );
      return v?.toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              key: const Key('enterWeight'),
              avatar: const Icon(Icons.monitor_weight_outlined, size: 18),
              label: Text(_weight == null ? 'My weight' : _kg(_weight!)),
              onPressed: () async {
                final v = await ask('Weight (${Units.w})', _weight);
                if (v != null) setState(() => _weight = v);
              },
            ),
            ActionChip(
              key: const Key('enterGoalWeight'),
              avatar: const Icon(Icons.flag_outlined, size: 18),
              label: Text(_goalWeight == null ? 'Goal weight' : 'Goal ${_kg(_goalWeight!)}'),
              onPressed: _weight == null
                  ? null
                  : () async {
                      final v = await ask('Goal weight (${Units.w})', _goalWeight ?? _weight);
                      if (v != null) setState(() => _goalWeight = v);
                    },
            ),
          ],
        ),
        const SizedBox(height: 8),
        _NextButton(label: _weight == null ? 'Skip for now' : 'Next', onTap: _next),
      ],
    );
  }

  Widget _done(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tips = [
      if (_focus != _Focus.running) 'Strength tab: pick a ready-made program or start an empty workout.',
      if (_focus != _Focus.strength) 'Cardio tab: tap Start for a run, walk, hike or ride, or plan your weeks.',
      'Tools › Heart-rate zones: get beeps when you leave your zone.',
      'Tools › Ab workouts: 5–20 minute follow-along workouts.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_focus?.label ?? 'Hybrid'} · ${_level.label} · ${_place.label} · $_weekly× a week · age $_age',
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('•  $tip', style: text.bodyMedium),
          ),
      ],
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      key: const Key('onboardingNext'),
      style: FilledButton.styleFrom(minimumSize: const Size(150, 54)),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    ),
  );
}
