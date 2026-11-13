import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/exercise_repository.dart';
import '../workout/calculators.dart';
import '../workout/stats.dart';
import 'number_input.dart';
import '../units/units.dart';
import 'theme/app_theme.dart';

/// A bar the user can load (weight in the unit of its list: kg or lb).
class BarOption {
  const BarOption(this.label, this.kg);

  final String label;

  /// kg in [barOptions], lb in [barOptionsLb].
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

/// The same bars as US gyms sell them, in pounds.
const barOptionsLb = [
  BarOption('Olympic', 45),
  BarOption("Women's", 35),
  BarOption('Technique', 15),
  BarOption('EZ bar', 25),
  BarOption('Trap bar', 55),
  BarOption('Smith', 25),
  BarOption('No bar', 0),
];

/// Plates that exist in gyms (kg); the user switches off the ones their gym
/// doesn't have (setting `plates`).
const allPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 2.0, 1.25, 1.0, 0.5];

/// Pound plates (setting `platesLb`).
const allPlatesLb = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5, 1.25];

/// Plates per side for a target weight, in kg or – with pounds chosen in
/// Settings › Units – in pounds with pound plates and bars. Remembers the
/// plates your gym has and the bar (per exercise when [exerciseId] is given,
/// settings `bar.<exercise id>`, else setting `bar`; pounds use `platesLb`,
/// `barLb…`).
class PlateCalculator extends StatefulWidget {
  const PlateCalculator({super.key, this.initialKg = 60, this.exerciseId});

  final double initialKg;
  final String? exerciseId;

  @override
  State<PlateCalculator> createState() => _PlateCalculatorState();
}

class _PlateCalculatorState extends State<PlateCalculator> {
  /// Everything in this state is in the shown unit (kg or lb).
  final bool _lb = Units.lb;
  late double _target = _round(Units.toW(widget.initialKg));
  late double _bar = _lb ? 45 : 20;
  String _barLabel = 'Olympic';
  late List<double> _plates = _lb ? allPlatesLb : standardPlates;
  bool _loaded = false;

  List<BarOption> get _bars => _lb ? barOptionsLb : barOptions;
  List<double> get _all => _lb ? allPlatesLb : allPlates;
  double get _step => _lb ? 5 : 2.5;
  String get _u => _lb ? 'lb' : 'kg';
  String get _barKey => '${_lb ? 'barLb' : 'bar'}${widget.exerciseId == null ? '' : '.${widget.exerciseId}'}';

  /// Pounds round to the nearest 0.5 lb (60 kg → 132.5 lb), kg stay as given.
  double _round(double v) => _lb ? (v * 2).roundToDouble() / 2 : v;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  Future<void> _load() async {
    final db = Services.of(context).db;
    final plates = await db.getSetting(_lb ? 'platesLb' : 'plates');
    // Per-exercise bar, else the last one used anywhere.
    final bar = await db.getSetting(_barKey) ?? await db.getSetting(_lb ? 'barLb' : 'bar');
    if (!mounted) return;
    setState(() {
      if (plates != null && plates.isNotEmpty) {
        _plates = [for (final p in plates.split(',')) ?double.tryParse(p)]..sort((a, b) => b.compareTo(a));
      }
      final parts = bar?.split('|');
      if (parts != null && parts.length == 2) {
        _barLabel = parts[0];
        _bar = double.tryParse(parts[1]) ?? _bar;
      }
    });
  }

  Future<void> _setBar(String label, double w) async {
    setState(() {
      _barLabel = label;
      _bar = w;
    });
    final db = Services.of(context).db;
    await db.setSetting(_barKey, '$label|$w');
    await db.setSetting(_lb ? 'barLb' : 'bar', '$label|$w');
  }

  Future<void> _togglePlate(double p) async {
    final next = _plates.contains(p) ? (_plates.toList()..remove(p)) : [..._plates, p];
    next.sort((a, b) => b.compareTo(a));
    setState(() => _plates = next);
    await Services.of(context).db.setSetting(_lb ? 'platesLb' : 'plates', next.join(','));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final result = platesPerSide(_target, bar: _bar, plates: _plates);
    final custom = !_bars.any((b) => b.label == _barLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Target ', style: text.titleMedium),
            EditableNumber(
              key: const Key('plateTarget'),
              value: _target,
              title: 'Target weight ($_u)',
              decimal: true,
              max: 2000,
              suffix: _u,
              display: '${formatKg(_target)} $_u',
              style: text.titleMedium,
              onChanged: (v) => setState(() => _target = v.toDouble()),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _target = (_target - _step).clamp(0, 2000)),
              icon: const Icon(Icons.remove),
            ),
            IconButton(onPressed: () => setState(() => _target += _step), icon: const Icon(Icons.add)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Bar', style: text.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final b in _bars)
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
                final v = await promptNumber(
                  context,
                  title: 'Bar weight ($_u)',
                  initial: _bar,
                  decimal: true,
                  max: 200,
                );
                if (v != null) await _setBar('Custom', v.toDouble());
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // The bar seen from the side, loaded like in the mockups: colourful
        // plates by size, then the bar's sleeve.
        LoadedBar(
          key: const Key('loadedBar'),
          plates: result.perSide,
          lb: _lb,
          emptyText: _target <= _bar ? 'Just the bar' : 'No plates fit',
        ),
        const SizedBox(height: 8),
        Text(
          result.perSide.isEmpty
              ? 'Bar ${formatKg(_bar)} $_u'
              : 'Each side: ${formatKg(result.perSide.fold<double>(0, (a, b) => a + b))} $_u  ·  '
                    '${result.perSide.map(formatKg).join(' + ')}',
          key: const Key('perSideText'),
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (result.remainder > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${formatKg(result.remainder)} $_u can\'t be made with your plates – '
              'closest: ${formatKg(_target - result.remainder)} $_u',
            ),
          ),
        const SizedBox(height: 16),
        Text('Plates in your gym', style: text.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in _all)
              FilterChip(
                // Every plate keeps its colour; the fill shows which you have.
                showCheckmark: false,
                avatar: PlateDot(kg: p, lb: _lb),
                label: Text(formatKg(p)),
                selected: _plates.contains(p),
                onSelected: (_) => _togglePlate(p),
              ),
          ],
        ),
      ],
    );
  }
}

/// Plate colours (competition colours, a touch softer – docs/DESIGN.md):
/// 25 red, 20 blue, 15 yellow, 10 green, 5 white, small change in the same
/// order. Pound plates take the colour of the kilo plate they are closest to.
Color plateColor(double w, {bool lb = false}) {
  const red = Color(0xFFE5484D), blue = Color(0xFF3E63DD), yellow = Color(0xFFFFC53D);
  const green = Color(0xFF30A46C), white = Color(0xFFF4F4F5), black = Color(0xFF2B2E33), steel = Color(0xFFA9B1BA);
  if (lb) {
    return switch (w) {
      45 => blue,
      35 => yellow,
      25 => green,
      10 => white,
      5 => red,
      2.5 => black,
      _ => steel,
    };
  }
  return switch (w) {
    25 => red,
    20 => blue,
    15 => yellow,
    10 => green,
    5 => white,
    2.5 => red,
    2 => blue,
    1.5 => yellow,
    1 => green,
    0.5 => white,
    _ => steel,
  };
}

/// One plate seen from the side: taller and thicker the heavier it is, with
/// a soft shine so it looks round.
class PlateView extends StatelessWidget {
  const PlateView({super.key, required this.kg, this.lb = false});

  /// The plate's number (kg, or pounds when [lb]).
  final double kg;
  final bool lb;

  @override
  Widget build(BuildContext context) {
    final c = plateColor(kg, lb: lb);
    final w = lb ? kg * Units.kgPerLb : kg; // size by real weight
    final h = 30.0 + (w.clamp(0, 25)) * 2.6;
    final thick = 13.0 + (w.clamp(0, 25)) * 0.42;
    final light = c.computeLuminance() > 0.5;
    return Container(
      width: thick,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color.lerp(c, Colors.white, 0.28)!, c, Color.lerp(c, Colors.black, 0.18)!],
          stops: const [0, 0.45, 1],
        ),
        border: light ? Border.all(color: const Color(0x33000000)) : null,
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 3, offset: Offset(1, 2))],
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          formatKg(kg),
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Inter',
            color: light ? const Color(0xFF2B2E33) : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: w >= 5 ? 11 : 9,
          ),
        ),
      ),
    );
  }
}

/// The bar from the side: collar, the plates of one side (heaviest next to
/// the collar), then the sleeve and the bar running on.
class LoadedBar extends StatelessWidget {
  const LoadedBar({super.key, required this.plates, this.lb = false, this.emptyText = ''});

  final List<double> plates;
  final bool lb;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    // Works without the app theme too (calculator sheets in tests).
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppTheme>();
    final field = ext?.field ?? scheme.surfaceContainerHighest;
    final muted = ext?.muted ?? scheme.onSurfaceVariant;
    const steel = Color(0xFFB4BBC3);
    final bar = Container(
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(steel, Colors.white, 0.5)!, steel, Color.lerp(steel, Colors.black, 0.25)!],
        ),
      ),
    );
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: field, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          // The bar coming from the middle, and the collar.
          SizedBox(width: 22, child: bar),
          Container(
            width: 8,
            height: 30,
            decoration: BoxDecoration(color: const Color(0xFF8A939D), borderRadius: BorderRadius.circular(2)),
          ),
          if (plates.isEmpty)
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  bar,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: field, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      emptyText,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [for (final p in plates) PlateView(kg: p, lb: lb)],
                ),
              ),
            ),
            Expanded(child: bar),
          ],
        ],
      ),
    );
  }
}

/// A small coloured dot for a plate in the "plates in your gym" chips.
class PlateDot extends StatelessWidget {
  const PlateDot({super.key, required this.kg, this.lb = false});

  final double kg;
  final bool lb;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: plateColor(kg, lb: lb),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0x33000000)),
    ),
  );
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
