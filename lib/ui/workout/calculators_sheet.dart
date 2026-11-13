import 'package:flutter/material.dart';

import '../../workout/calculators.dart';
import '../../workout/stats.dart';
import '../number_input.dart';
import '../plate_calculator.dart';
import '../../units/units.dart';

/// Plate calculator + 1RM calculator, prefilled from the current set.
/// [exerciseId] remembers the bar per exercise.
Future<void> showCalculators(BuildContext context, {double? weightKg, int? reps, String? exerciseId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CalculatorsSheet(weightKg: weightKg ?? 60, reps: reps ?? 5, exerciseId: exerciseId),
  );
}

class _CalculatorsSheet extends StatefulWidget {
  const _CalculatorsSheet({required this.weightKg, required this.reps, this.exerciseId});

  final double weightKg;
  final int reps;
  final String? exerciseId;

  @override
  State<_CalculatorsSheet> createState() => _CalculatorsSheetState();
}

class _CalculatorsSheetState extends State<_CalculatorsSheet> {
  late double _weight = widget.weightKg;
  late int _reps = widget.reps;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                      children: [PlateCalculator(initialKg: widget.weightKg, exerciseId: widget.exerciseId)],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            EditableNumber(
                              value: double.parse(formatW(_weight)),
                              title: 'Weight (${Units.w})',
                              decimal: true,
                              max: 2000,
                              display: formatWeight(_weight),
                              style: text.titleMedium,
                              onChanged: (v) => setState(() => _weight = Units.fromW(v.toDouble())),
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
                        Text('Estimated 1RM: ${formatWeight(oneRm)}', style: text.headlineSmall),
                        const SizedBox(height: 4),
                        Text('Epley formula – most accurate up to ~10 reps.', style: text.bodySmall),
                        const SizedBox(height: 12),
                        for (final (pct, kg, r) in percentTable(oneRm))
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Text('$pct%', style: text.titleSmall),
                            title: Text(formatWeight(kg)),
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
