import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../run/geo.dart';
import '../../run/run_plan.dart';
import '../../workout/stats.dart';
import '../number_input.dart';
import 'run_start.dart';
import '../theme/emblems.dart';

/// Run tab: your planned runs; ▶ starts one, tap to edit.
class RunPlansSection extends StatelessWidget {
  const RunPlansSection({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<RunPlan>>(
      stream: s.runPlans.watchAll(),
      builder: (context, snap) {
        final plans = snap.data ?? const <RunPlan>[];
        return Card(
          key: const Key('runPlans'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Planned runs', style: text.titleMedium)),
                    TextButton.icon(
                      key: const Key('newPlan'),
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanEditorScreen())),
                    ),
                  ],
                ),
                for (final p in plans)
                  ListTile(
                    key: Key('plan_${p.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Emblem(PlanSpec.fromJson(p.specJson).isIntervals ? EmblemKind.interval : EmblemKind.flag),
                    title: Text(p.name),
                    subtitle: Text(PlanSpec.fromJson(p.specJson).description),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlanEditorScreen(plan: p))),
                    trailing: IconButton.filledTonal(
                      key: Key('startPlan_${p.id}'),
                      tooltip: 'Start',
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => startRun(context, plan: p),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Create or edit a planned run: a goal (distance or time) or intervals
/// (warm-up, N × run + recover, cool-down).
class PlanEditorScreen extends StatefulWidget {
  const PlanEditorScreen({super.key, this.plan});

  final RunPlan? plan;

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  late final _name = TextEditingController(text: widget.plan?.name ?? '');
  late bool _intervals;
  // Goal
  late bool _goalByDistance;
  late int _goalValue;
  // Intervals
  late int _warmupMin, _cooldownMin, _repeats;
  late bool _workByDistance, _recoverByDistance;
  late int _work, _recover; // metres or seconds; recover 0 = none

  @override
  void initState() {
    super.initState();
    final spec = widget.plan == null ? null : PlanSpec.fromJson(widget.plan!.specJson);
    _intervals = spec?.isIntervals ?? false;
    _goalByDistance = spec?.goal?.byDistance ?? true;
    _goalValue = spec?.goal?.value ?? 5000;
    _warmupMin = (spec?.warmup?.value ?? 600) ~/ 60;
    _cooldownMin = (spec?.cooldown?.value ?? 300) ~/ 60;
    _repeats = spec?.repeats ?? 6;
    _workByDistance = spec?.work?.byDistance ?? true;
    _work = spec?.work?.value ?? 400;
    _recoverByDistance = spec?.recover?.byDistance ?? true;
    _recover = spec?.recover?.value ?? (spec?.isIntervals == true ? 0 : 200);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  PlanSpec get _spec => _intervals
      ? PlanSpec(
          warmup: _warmupMin > 0 ? PlanStep(StepKind.warmup, byDistance: false, value: _warmupMin * 60) : null,
          repeats: _repeats,
          work: PlanStep(StepKind.work, byDistance: _workByDistance, value: _work),
          recover: _recover > 0 ? PlanStep(StepKind.recover, byDistance: _recoverByDistance, value: _recover) : null,
          cooldown: _cooldownMin > 0 ? PlanStep(StepKind.cooldown, byDistance: false, value: _cooldownMin * 60) : null,
        )
      : PlanSpec(
          goal: PlanStep(StepKind.goal, byDistance: _goalByDistance, value: _goalValue),
        );

  Future<void> _save() async {
    final s = Services.of(context);
    final spec = _spec;
    final name = _name.text.trim().isEmpty ? spec.description : _name.text.trim();
    await s.runPlans.save(id: widget.plan?.id, name: name, spec: spec);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this planned run?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await Services.of(context).runPlans.delete(widget.plan!.id);
    if (mounted) Navigator.pop(context);
  }

  /// "400 m" / "2 min" value with a distance/time switch.
  Widget _amount({
    required Key key,
    required bool byDistance,
    required int value,
    required ValueChanged<bool> onKind,
    required ValueChanged<int> onValue,
    bool allowNone = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EditableNumber(
          key: key,
          value: byDistance ? value : value / 60,
          title: byDistance ? 'Metres' : 'Minutes',
          decimal: !byDistance,
          min: allowNone ? 0 : (byDistance ? 50 : 0.25),
          max: byDistance ? 50000 : 300,
          suffix: byDistance ? 'm' : 'min',
          display: value == 0 && allowNone ? 'none' : (byDistance ? metresText(value) : secondsText(value)),
          onChanged: (v) => onValue(byDistance ? v.round() : (v * 60).round()),
        ),
        const SizedBox(width: 4),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment(value: true, label: Text('m')),
            ButtonSegment(value: false, label: Text('min')),
          ],
          selected: {byDistance},
          onSelectionChanged: (v) => onKind(v.first),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(String label, Widget control) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyLarge)),
          control,
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan == null ? 'New planned run' : 'Edit planned run'),
        actions: [
          if (widget.plan != null)
            IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: _delete),
          TextButton(key: const Key('savePlan'), onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('planName'),
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: 'Name', hintText: _spec.description),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            key: const Key('planType'),
            segments: const [
              ButtonSegment(value: false, label: Text('Goal'), icon: Icon(Icons.flag_outlined)),
              ButtonSegment(value: true, label: Text('Intervals'), icon: Icon(Icons.timer_outlined)),
            ],
            selected: {_intervals},
            onSelectionChanged: (v) => setState(() {
              _intervals = v.first;
              if (_intervals && _recover == 0) _recover = 200;
            }),
          ),
          const SizedBox(height: 12),
          if (!_intervals) ...[
            row(
              'Run',
              _amount(
                key: const Key('goalValue'),
                byDistance: _goalByDistance,
                value: _goalValue,
                onKind: (d) => setState(() {
                  _goalByDistance = d;
                  _goalValue = d ? 5000 : 1800;
                }),
                onValue: (v) => setState(() => _goalValue = v),
              ),
            ),
            Text('You hear "Halfway" and when you reach the goal; keep running or finish.', style: text.bodySmall),
          ] else ...[
            row(
              'Warm-up',
              EditableNumber(
                key: const Key('warmupMin'),
                value: _warmupMin,
                title: 'Warm-up (minutes, 0 = none)',
                max: 60,
                suffix: 'min',
                display: _warmupMin == 0 ? 'none' : '$_warmupMin min',
                onChanged: (v) => setState(() => _warmupMin = v.toInt()),
              ),
            ),
            row(
              'Repeats',
              EditableNumber(
                key: const Key('repeats'),
                value: _repeats,
                title: 'Repeats',
                min: 1,
                max: 50,
                display: '$_repeats ×',
                onChanged: (v) => setState(() => _repeats = v.toInt()),
              ),
            ),
            row(
              'Run fast',
              _amount(
                key: const Key('workValue'),
                byDistance: _workByDistance,
                value: _work,
                onKind: (d) => setState(() {
                  _workByDistance = d;
                  _work = d ? 400 : 60;
                }),
                onValue: (v) => setState(() => _work = v),
              ),
            ),
            row(
              'Recover',
              _amount(
                key: const Key('recoverValue'),
                byDistance: _recoverByDistance,
                value: _recover,
                allowNone: true,
                onKind: (d) => setState(() {
                  _recoverByDistance = d;
                  _recover = d ? 200 : 60;
                }),
                onValue: (v) => setState(() => _recover = v),
              ),
            ),
            row(
              'Cool-down',
              EditableNumber(
                key: const Key('cooldownMin'),
                value: _cooldownMin,
                title: 'Cool-down (minutes, 0 = none)',
                max: 60,
                suffix: 'min',
                display: _cooldownMin == 0 ? 'none' : '$_cooldownMin min',
                onChanged: (v) => setState(() => _cooldownMin = v.toInt()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Each step ends by distance or time. You hear 2 high beeps when a fast part starts, 1 low beep for '
              'recovery, and the voice says what\'s next.',
              style: text.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text(_spec.description, key: const Key('planDescription'), style: text.titleSmall),
        ],
      ),
    );
  }
}

/// Live run: the current step of the plan with a progress bar.
class PlanBanner extends StatelessWidget {
  const PlanBanner({super.key, required this.plan, required this.metres, required this.seconds});

  final PlanRunner plan;
  final double metres;
  final double seconds;

  @override
  Widget build(BuildContext context) {
    final step = plan.current;
    const style = TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800);
    if (step == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text('Workout complete ✓', key: Key('planBanner'), style: style),
      );
    }
    final left = plan.left(metres, seconds);
    final hard = step.kind == StepKind.work || step.kind == StepKind.goal;
    final r = plan.repeat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        key: const Key('planBanner'),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${step.label}${r != null && step.kind == StepKind.work ? ' $r/${plan.spec.repeats}' : ''} · ${step.amount}',
                  style: style,
                ),
              ),
              Text(
                step.byDistance ? '${left.round()} m left' : '${formatDuration(Duration(seconds: left.round()))} left',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: plan.progress(metres, seconds),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: hard ? const Color(0xFF69F0AE) : const Color(0xFF80D8FF),
            backgroundColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}

/// Run summary: every step of the planned run with its distance, time and
/// pace.
class LapsCard extends StatelessWidget {
  const LapsCard({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context) {
    final laps = decodeLaps(run.lapsJson);
    if (laps.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    var work = 0;
    return Card(
      key: const Key('lapsCard'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<RunPlan?>(
              future: Services.of(context).runPlans.byId(run.planId),
              builder: (context, snap) =>
                  Text(snap.data == null ? 'Laps' : 'Laps · ${snap.data!.name}', style: text.titleMedium),
            ),
            const SizedBox(height: 8),
            for (final l in laps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.step.kind == StepKind.work ? '${l.step.label} ${++work}' : l.step.label,
                        style: TextStyle(fontWeight: l.step.kind == StepKind.work ? FontWeight.w700 : null),
                      ),
                    ),
                    SizedBox(width: 70, child: Text('${formatKm(l.distanceM)} km', textAlign: TextAlign.end)),
                    SizedBox(
                      width: 64,
                      child: Text(formatDuration(Duration(seconds: l.seconds.round())), textAlign: TextAlign.end),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(formatPace(paceSecPerKm(l.distanceM, l.seconds)), textAlign: TextAlign.end),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
