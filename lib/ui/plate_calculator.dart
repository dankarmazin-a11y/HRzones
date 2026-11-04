import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/exercise_repository.dart';
import '../workout/calculators.dart';
import '../workout/stats.dart';
import 'number_input.dart';

/// A bar the user can load.
class BarOption {
  const BarOption(this.label, this.kg);

  final String label;
  final double kg;
}

const barOptions = [
  BarOption('Olympic', 20),
  BarOption("Women's", 15),
  BarOption('Technique', 10),
  BarOption('EZ bar', 10),
  BarOption('Trap bar', 25),
  BarOption('Smith', 15),
  BarOption('No bar', 0),
];

/// Plates that exist in gyms (kg); the user switches off the ones their gym
/// doesn't have (setting `plates`).
const allPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 2.0, 1.25, 1.0, 0.5];

/// Plates per side for a target weight. Remembers the plates your gym has
/// and the bar (per exercise when [exerciseId] is given, settings
/// `bar.<exercise id>`, else setting `bar`).
class PlateCalculator extends StatefulWidget {
  const PlateCalculator({super.key, this.initialKg = 60, this.exerciseId});

  final double initialKg;
  final String? exerciseId;

  @override
  State<PlateCalculator> createState() => _PlateCalculatorState();
}

class _PlateCalculatorState extends State<PlateCalculator> {
  late double _target = widget.initialKg;
  double _bar = 20;
  String _barLabel = 'Olympic';
  List<double> _plates = standardPlates;
  bool _loaded = false;

  String get _barKey => widget.exerciseId == null ? 'bar' : 'bar.${widget.exerciseId}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  Future<void> _load() async {
    final db = Services.of(context).db;
    final plates = await db.getSetting('plates');
    // Per-exercise bar, else the last one used anywhere.
    final bar = await db.getSetting(_barKey) ?? await db.getSetting('bar');
    if (!mounted) return;
    setState(() {
      if (plates != null && plates.isNotEmpty) {
        _plates = [for (final p in plates.split(',')) ?double.tryParse(p)]..sort((a, b) => b.compareTo(a));
      }
      final parts = bar?.split('|');
      if (parts != null && parts.length == 2) {
        _barLabel = parts[0];
        _bar = double.tryParse(parts[1]) ?? 20;
      }
    });
  }

  Future<void> _setBar(String label, double kg) async {
    setState(() {
      _barLabel = label;
      _bar = kg;
    });
    final db = Services.of(context).db;
    await db.setSetting(_barKey, '$label|$kg');
    await db.setSetting('bar', '$label|$kg');
  }

  Future<void> _togglePlate(double p) async {
    final next = _plates.contains(p) ? (_plates.toList()..remove(p)) : [..._plates, p];
    next.sort((a, b) => b.compareTo(a));
    setState(() => _plates = next);
    await Services.of(context).db.setSetting('plates', next.join(','));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final result = platesPerSide(_target, bar: _bar, plates: _plates);
    final custom = !barOptions.any((b) => b.label == _barLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Target ', style: text.titleMedium),
            EditableNumber(
              key: const Key('plateTarget'),
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
        const SizedBox(height: 8),
        Text('Bar', style: text.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final b in barOptions)
              ChoiceChip(
                label: Text(b.kg == 0 ? b.label : '${b.label} ${formatKg(b.kg)}'),
                selected: _barLabel == b.label,
                onSelected: (_) => _setBar(b.label, b.kg),
              ),
            ChoiceChip(
              avatar: const Icon(Icons.edit, size: 16),
              label: Text(custom ? 'Custom ${formatKg(_bar)}' : 'Custom'),
              selected: custom,
              onSelected: (_) async {
                final v = await promptNumber(context, title: 'Bar weight (kg)', initial: _bar, decimal: true, max: 100);
                if (v != null) await _setBar('Custom', v.toDouble());
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Each side', style: text.titleSmall),
        const SizedBox(height: 8),
        if (result.perSide.isEmpty)
          Text(_target <= _bar ? 'Just the bar' : 'No plates fit', style: text.bodyLarge)
        else
          Wrap(spacing: 6, runSpacing: 6, children: [for (final p in result.perSide) PlateView(kg: p)]),
        if (result.remainder > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${formatKg(result.remainder)} kg can\'t be made with your plates – '
              'closest: ${formatKg(_target - result.remainder)} kg',
            ),
          ),
        const SizedBox(height: 16),
        Text('Plates in your gym', style: text.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in allPlates)
              FilterChip(label: Text(formatKg(p)), selected: _plates.contains(p), onSelected: (_) => _togglePlate(p)),
          ],
        ),
      ],
    );
  }
}

/// A plate drawn to scale-ish, coloured like competition plates.
class PlateView extends StatelessWidget {
  const PlateView({super.key, required this.kg});

  final double kg;

  static final _colors = <double, Color>{
    25.0: Colors.red,
    20.0: Colors.blue,
    15.0: Colors.amber,
    10.0: Colors.green,
    5.0: Colors.white,
    2.5: Colors.black,
    2.0: Colors.blueGrey,
    1.25: Colors.grey,
    1.0: Colors.grey,
    0.5: Colors.grey,
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
        border: Border.all(color: Colors.black26),
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          formatKg(kg),
          style: TextStyle(
            color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Tools › Plate calculator.
class PlateCalculatorScreen extends StatelessWidget {
  const PlateCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Plate calculator')),
    body: ListView(padding: const EdgeInsets.all(16), children: const [PlateCalculator()]),
  );
}
