import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../hr/zones.dart';
import '../../workout/training_level.dart';
import '../../workout/training_place.dart';
import '../number_input.dart';

/// First launch: a short walk-through that sets the app up – what you train,
/// your level, where you train, age (heart-rate zones), workouts per week and
/// body weight / a goal. Every answer is saved right away; "Skip" keeps the
/// defaults. Settings › "Run the setup again" shows it again.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Focus {
  strength('Strength', 'Lifting, machines, bodyweight', Icons.fitness_center),
  running('Running', 'Outdoor and treadmill runs', Icons.directions_run),
  both('Both – hybrid', 'Strength and running', Icons.sync_alt);

  const _Focus(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  _Focus? _focus;
  late TrainingLevel _level;
  late TrainingPlace _place;
  late int _age;
  late int _weekly;
  double? _weight;
  double? _goalWeight;
  bool _loaded = false;

  static const _steps = 8;

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
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    FocusScope.of(context).unfocus();
    _pages.animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _finish() async {
    final s = Services.of(context);
    if (_weight != null) await s.body.add('weight', _weight!);
    if (_goalWeight != null && _weight != null && _goalWeight != _weight) {
      await s.goals.addMeasurement('weight', _goalWeight!);
    }
    await s.finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final scheme = Theme.of(context).colorScheme;
    final last = _page == _steps - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots + Skip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  for (var i = 0; i < _steps; i++)
                    Container(
                      width: i == _page ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i <= _page ? scheme.primary : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  if (!last)
                    TextButton(key: const Key('skipOnboarding'), onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _welcome(context),
                  _choice<_Focus>(
                    title: 'What do you train?',
                    subtitle: 'You can do both any time – this just sets your start.',
                    values: _Focus.values,
                    selected: _focus,
                    label: (f) => f.label,
                    description: (f) => f.description,
                    icon: (f) => f.icon,
                    onSelect: (f) {
                      setState(() => _focus = f);
                      s.setFocus(f.name);
                    },
                  ),
                  _choice<TrainingLevel>(
                    title: 'Your training level',
                    subtitle: 'Decides which exercises and options you see. Change it any time in Settings.',
                    values: TrainingLevel.values,
                    selected: _level,
                    label: (l) => l.label,
                    description: (l) => l.description,
                    icon: (l) => switch (l) {
                      TrainingLevel.beginner => Icons.looks_one_outlined,
                      TrainingLevel.intermediate => Icons.looks_two_outlined,
                      TrainingLevel.advanced => Icons.looks_3_outlined,
                    },
                    onSelect: (l) {
                      setState(() => _level = l);
                      s.setLevel(l);
                    },
                  ),
                  _choice<TrainingPlace>(
                    title: 'Where do you train?',
                    subtitle: 'The exercise list shows what you can do there.',
                    values: TrainingPlace.values,
                    selected: _place,
                    label: (p) => p.label,
                    description: (p) => switch (p) {
                      TrainingPlace.gym => 'All equipment',
                      TrainingPlace.home => 'Dumbbells, kettlebells, bands, bodyweight',
                      TrainingPlace.outdoors => 'Bodyweight and bands',
                      TrainingPlace.hybrid => 'Different places – the app asks at each workout',
                    },
                    icon: (p) => p.icon,
                    onSelect: (p) {
                      setState(() => _place = p);
                      s.setPlace(p);
                    },
                  ),
                  _ageStep(context),
                  _weeklyStep(context),
                  _weightStep(context),
                  _doneStep(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      onPressed: () => _go(_page - 1),
                    ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('onboardingNext'),
                    style: FilledButton.styleFrom(minimumSize: const Size(160, 52)),
                    onPressed: last ? _finish : () => _go(_page + 1),
                    child: Text(
                      _page == 0 ? 'Let\'s go' : (last ? 'Start training' : 'Next'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, String? subtitle, required List<Widget> children}) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        Text(title, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle, style: text.bodyLarge)],
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }

  Widget _welcome(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _section(
      context,
      title: 'Welcome to HR Zones',
      subtitle:
          'Log your strength workouts, track your runs, and hear a beep when your heart rate leaves your zone – '
          'even with the screen locked and music playing.\n\nA few quick questions to set things up for you.',
      children: [
        const SizedBox(height: 24),
        Center(child: Icon(Icons.monitor_heart, size: 120, color: scheme.primary)),
      ],
    );
  }

  Widget _choice<T>({
    required String title,
    required String subtitle,
    required List<T> values,
    required T? selected,
    required String Function(T) label,
    required String Function(T) description,
    required IconData Function(T) icon,
    required ValueChanged<T> onSelect,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return _section(
      context,
      title: title,
      subtitle: subtitle,
      children: [
        for (final v in values)
          Card(
            color: v == selected ? scheme.primaryContainer : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: v == selected ? scheme.primary : scheme.outlineVariant,
                width: v == selected ? 2 : 1,
              ),
            ),
            child: ListTile(
              key: Key('choice_$v'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Icon(icon(v), size: 32),
              title: Text(label(v), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              subtitle: Text(description(v)),
              trailing: v == selected ? Icon(Icons.check_circle, color: scheme.primary) : null,
              onTap: () => onSelect(v),
            ),
          ),
      ],
    );
  }

  Widget _stepper({
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    VoidCallback? onTap,
    Key? key,
  }) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(iconSize: 32, icon: const Icon(Icons.remove), onPressed: onMinus),
        const SizedBox(width: 16),
        InkWell(
          key: key,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(value, style: text.displayMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 16),
        IconButton.filledTonal(iconSize: 32, icon: const Icon(Icons.add), onPressed: onPlus),
      ],
    );
  }

  Widget _ageStep(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    final zones = HrZones.fromAge(_age);
    void set(int a) {
      final v = a.clamp(10, 99);
      setState(() => _age = v);
      s.hr.setAge(v);
    }

    final z2 = zones.zones[1];
    return _section(
      context,
      title: 'Your age',
      subtitle: 'Used for your heart-rate zones (max heart rate ≈ 220 − age). You can fine-tune zones later.',
      children: [
        _stepper(
          key: const Key('ageValue'),
          value: '$_age',
          onMinus: () => set(_age - 1),
          onPlus: () => set(_age + 1),
          onTap: () async {
            final v = await promptNumber(context, title: 'Your age', initial: _age, min: 10, max: 99);
            if (v != null) set(v.round());
          },
        ),
        const SizedBox(height: 16),
        Center(child: Text('Max heart rate about ${zones.maxHr} bpm', style: text.titleMedium)),
        Center(child: Text('Easy zone 2: ${z2.minBpm}–${z2.maxBpm} bpm', style: text.bodyMedium)),
      ],
    );
  }

  Widget _weeklyStep(BuildContext context) {
    final s = Services.of(context);
    return _section(
      context,
      title: 'Workouts per week',
      subtitle: 'Your weekly target for the streak on Home. Runs count too.',
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var n = 1; n <= 7; n++)
              ChoiceChip(
                key: Key('weekly_$n'),
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('$n', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                selected: _weekly == n,
                onSelected: (_) {
                  setState(() => _weekly = n);
                  s.setWeeklyTarget(n);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _weightStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    String kg(double? v) => v == null ? 'Tap to enter' : '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)} kg';
    return _section(
      context,
      title: 'Body weight (optional)',
      subtitle: 'For calories on runs and your progress. Add a goal weight to see it at the top of Home.',
      children: [
        ListTile(
          key: const Key('enterWeight'),
          leading: const Icon(Icons.monitor_weight_outlined),
          title: const Text('Your weight now'),
          trailing: Text(kg(_weight), style: text.titleMedium),
          onTap: () async {
            final v = await promptNumber(
              context,
              title: 'Weight (kg)',
              initial: _weight,
              min: 30,
              max: 300,
              decimal: true,
            );
            if (v != null) setState(() => _weight = v.toDouble());
          },
        ),
        ListTile(
          key: const Key('enterGoalWeight'),
          enabled: _weight != null,
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Goal weight'),
          trailing: Text(_goalWeight == null ? 'Optional' : kg(_goalWeight), style: text.titleMedium),
          onTap: () async {
            final v = await promptNumber(
              context,
              title: 'Goal weight (kg)',
              initial: _goalWeight ?? _weight,
              min: 30,
              max: 300,
              decimal: true,
            );
            if (v != null) setState(() => _goalWeight = v.toDouble());
          },
        ),
      ],
    );
  }

  Widget _doneStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tips = [
      if (_focus != _Focus.running)
        ('Strength', 'Pick a ready-made program in the Strength tab, or start an empty workout.'),
      if (_focus != _Focus.strength) ('Running', 'Tap Run to go, or plan your weeks with "Weekly running plan".'),
      ('Heart-rate zones', 'Tools › Heart-rate zones: make a zone and get beeps when you leave it.'),
      ('Abs', 'Tools › Ab workouts: 5–20 minute follow-along workouts.'),
    ];
    return _section(
      context,
      title: 'You\'re all set',
      subtitle: '${_level.label} · ${_place.label} · $_weekly× a week · age $_age',
      children: [
        for (final (title, body) in tips)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(title, style: text.titleSmall),
            subtitle: Text(body),
          ),
      ],
    );
  }
}
