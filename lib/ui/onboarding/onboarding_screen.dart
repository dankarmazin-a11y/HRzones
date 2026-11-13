import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../hr/zones.dart';
import '../../workout/training_level.dart';
import '../../workout/training_place.dart';
import '../number_input.dart';
import '../theme/app_theme.dart';
import '../theme/emblems.dart';
import '../../units/units.dart';

/// First launch: a short chat (docs/DESIGN.md "Setup: chat style") – what you
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
  running('Running'),
  both('Both – hybrid');

  const _Focus(this.label);
  final String label;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _scroll = ScrollController();

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

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    setState(() => _step++);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

  /// The coach's message for each step.
  String _question(int step) {
    final zones = HrZones.fromAge(_age);
    return switch (step) {
      0 =>
        'Hi! I\'m your HR Zones coach. I log your strength workouts, track your runs, and beep when your heart '
            'rate leaves your zone – even with the screen locked and music playing.\n\nA few quick questions?',
      1 => 'What do you train?',
      2 => 'What\'s your training level? It decides which exercises and options you see.',
      3 => 'Where do you train? The exercise list shows what you can do there.',
      4 => 'How old are you? I use it for your heart-rate zones.',
      5 =>
        'Max heart rate about ${zones.maxHr} bpm – your easy zone 2 is ${zones.zones[1].minBpm}–'
            '${zones.zones[1].maxBpm} bpm.\n\nHow many workouts a week? Runs count too.',
      6 => 'Your body weight? Optional – for run calories and progress. Add a goal weight to see it on Home.',
      _ => 'You\'re all set',
    };
  }

  /// Your answer bubble for a finished step (null = no bubble).
  String? _answer(int step) => switch (step) {
    0 => 'Let\'s go',
    1 => _focus?.label ?? 'Skip',
    2 => _level.label,
    3 => _place.label,
    4 => '$_age',
    5 => '$_weekly× a week',
    6 =>
      _weight == null
          ? 'Skip for now'
          : '${_kg(_weight!)}${_goalWeight == null || _goalWeight == _weight ? '' : ' → goal ${_kg(_goalWeight!)}'}',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  const Emblem(EmblemKind.heart, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HR Zones', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        Text('Setup · ${_step.clamp(0, 7)} of 7', style: text.labelSmall?.copyWith(color: t.muted)),
                      ],
                    ),
                  ),
                  if (_step < 7)
                    TextButton(key: const Key('skipOnboarding'), onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  for (var i = 0; i <= _step; i++) ...[
                    i == 7 ? _doneBubble(context) : _CoachBubble(_question(i)),
                    if (i < _step && _answer(i) != null) _YouBubble(_answer(i)!),
                  ],
                  const SizedBox(height: 8),
                  _input(context),
                ],
              ),
            ),
          ],
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
        alignment: WrapAlignment.end,
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
    alignment: WrapAlignment.end,
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
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
        Text('Max heart rate about ${zones.maxHr}', style: text.labelMedium),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
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

  Widget _doneBubble(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tips = [
      if (_focus != _Focus.running) 'Strength tab: pick a ready-made program or start an empty workout.',
      if (_focus != _Focus.strength) 'Run tab: tap Run to go, or plan your weeks.',
      'Tools › Heart-rate zones: get beeps when you leave your zone.',
      'Tools › Ab workouts: 5–20 minute follow-along workouts.',
    ];
    return _CoachBubble.rich(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You\'re all set', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text('${_level.label} · ${_place.label} · $_weekly× a week · age $_age', style: text.bodySmall),
          const SizedBox(height: 8),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('•  $tip', style: text.bodyMedium),
            ),
        ],
      ),
    );
  }
}

/// The coach's bubble on the left.
class _CoachBubble extends StatelessWidget {
  const _CoachBubble(String this.message) : child = null;
  const _CoachBubble.rich(Widget this.child) : message = null;

  final String? message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: t.card,
            boxShadow: t.cardShadow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: child ?? Text(message!, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}

/// Your answer on the right, in the dark ink colour.
class _YouBubble extends StatelessWidget {
  const _YouBubble(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? t.bright : t.ink;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(color: onColor(bg), fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: FilledButton(
      key: const Key('onboardingNext'),
      style: FilledButton.styleFrom(minimumSize: const Size(150, 48)),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    ),
  );
}
