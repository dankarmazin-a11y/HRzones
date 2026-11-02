import 'package:flutter/material.dart';

import '../../workout/calculators.dart';
import '../../workout/stats.dart';
import '../number_input.dart';

/// Plate calculator + 1RM calculator, prefilled from the current set.
Future<void> showCalculators(BuildContext context, {double? weightKg, int? reps}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CalculatorsSheet(weightKg: weightKg ?? 60, reps: reps ?? 5),
  );
}

class _CalculatorsSheet extends StatefulWidget {
  const _CalculatorsSheet({required this.weightKg, required this.reps});

  final double weightKg;
  final int reps;

  @override
  State<_CalculatorsSheet> createState() => _CalculatorsSheetState();
}

class _CalculatorsSheetState extends State<_CalculatorsSheet> {
  late double _target = widget.weightKg;
  double _bar = 20;
  late double _weight = widget.weightKg;
  late int _reps = widget.reps;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final plates = platesPerSide(_target, bar: _bar);
    final oneRm = oneRepMax(_weight, _reps);
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Plates'),
                  Tab(text: '1RM'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Text('Target ', style: text.titleMedium),
                            EditableNumber(
                              value: _target,
                              title: 'Target weight (kg)',
                              decimal: true,
                              max: 1000,
                              suffix: 'kg',
                              display: '${formatKg(_target)} kg',
                              style: text.titleMedium,
                              onChanged: (v) => setState(() => _target = v.toDouble()),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => setState(() => _target = (_target - 2.5).clamp(0, 1000)),
                              icon: const Icon(Icons.remove),
                            ),
                            IconButton(onPressed: () => setState(() => _target += 2.5), icon: const Icon(Icons.add)),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final b in [20.0, 15.0, 10.0, 0.0])
                              ChoiceChip(
                                label: Text(b == 0 ? 'No bar' : '${formatKg(b)} kg bar'),
                                selected: _bar == b,
                                onSelected: (_) => setState(() => _bar = b),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Each side', style: text.titleSmall),
                        const SizedBox(height: 8),
                        if (plates.perSide.isEmpty)
                          const Text('Just the bar')
                        else
                          Wrap(spacing: 6, runSpacing: 6, children: [for (final p in plates.perSide) _Plate(kg: p)]),
                        if (plates.remainder > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('${formatKg(plates.remainder)} kg can\'t be made with standard plates'),
                          ),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            EditableNumber(
                              value: _weight,
                              title: 'Weight (kg)',
                              decimal: true,
                              max: 1000,
                              display: '${formatKg(_weight)} kg',
                              style: text.titleMedium,
                              onChanged: (v) => setState(() => _weight = v.toDouble()),
                            ),
                            Text(' × ', style: text.titleMedium),
                            EditableNumber(
                              value: _reps,
                              title: 'Reps',
                              min: 1,
                              max: 30,
                              display: '$_reps reps',
                              style: text.titleMedium,
                              onChanged: (v) => setState(() => _reps = v.round()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estimated 1RM: ${formatKg(double.parse(oneRm.toStringAsFixed(1)))} kg',
                          style: text.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text('Epley formula – most accurate up to ~10 reps.', style: text.bodySmall),
                        const SizedBox(height: 12),
                        for (final (pct, kg, r) in percentTable(oneRm))
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Text('$pct%', style: text.titleSmall),
                            title: Text('${formatKg(kg)} kg'),
                            trailing: Text('≈ $r rep${r == 1 ? '' : 's'}'),
                          ),
                      ],
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
}

class _Plate extends StatelessWidget {
  const _Plate({required this.kg});

  final double kg;

  static final _colors = <double, Color>{
    25.0: Colors.red,
    20.0: Colors.blue,
    15.0: Colors.amber,
    10.0: Colors.green,
    5.0: Colors.white,
    2.5: Colors.black,
    1.25: Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[kg] ?? Colors.grey;
    final h = 36.0 + kg * 1.6;
    return Container(
      width: 34,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          kg.toString().replaceFirst(RegExp(r'\.0$'), ''),
          style: TextStyle(
            color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
