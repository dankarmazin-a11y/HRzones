import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../run/training_plan.dart';
import '../../workout/streak.dart';
import '../number_input.dart';
import 'run_start.dart';
import '../../workout/stats.dart';
import '../../units/units.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The active plan with the dates you ran on (live).
Widget _withPlan(BuildContext context, Widget Function(TrainingPlan? row, WeeklyPlan? plan) builder) {
  final s = Services.of(context);
  return StreamBuilder<TrainingPlan?>(
    stream: s.trainingPlans.watchActive(),
    builder: (context, p) => StreamBuilder<List<Run>>(
      stream: s.runs.watchFinished(),
      builder: (context, r) {
        final row = p.data;
        if (row == null) return builder(null, null);
        return builder(
          row,
          WeeklyPlan(
            start: row.startDate,
            weeks: row.weeks,
            days: decodePlanDays(row.daysJson),
            runDates: [for (final run in r.data ?? const <Run>[]) run.startedAt],
          ),
        );
      },
    ),
  );
}

Color _statusColor(BuildContext context, DayStatus s) => switch (s) {
  DayStatus.done => Colors.green,
  DayStatus.missed => Colors.red.shade300,
  DayStatus.today => Theme.of(context).colorScheme.primary,
  DayStatus.upcoming => Theme.of(context).colorScheme.outline,
};

/// Starts the run for a plan day: its saved planned run, or a goal of the
/// day's distance / time.
Future<void> startPlanDay(BuildContext context, PlanDay d) async {
  final s = Services.of(context);
  RunPlan? plan;
  if (d.runPlanId != null) plan = await s.runPlans.byId(d.runPlanId);
  final goal = goalSpecFor(d);
  if (plan == null && goal != null) {
    plan = RunPlan(id: '', name: d.describe, specJson: goal.toJson(), position: 0, updatedAt: DateTime.now());
  }
  if (context.mounted) await startRun(context, plan: plan);
}

/// Run tab: this week of your plan, today's run with Start – or "make a
/// plan".
class WeeklyPlanCard extends StatelessWidget {
  const WeeklyPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _withPlan(context, (row, plan) {
      final text = Theme.of(context).textTheme;
      if (row == null || plan == null) {
        return Card(
          child: ListTile(
            key: const Key('weeklyPlanCard'),
            leading: const Icon(Icons.calendar_month),
            title: const Text('Weekly running plan'),
            subtitle: const Text('Plan your runs day by day, week by week'),
            trailing: const Icon(Icons.add),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeeklyPlanEditor())),
          ),
        );
      }
      final now = DateTime.now();
      final w = plan.weekIndex(now);
      final today = plan.today(now);
      final next = plan.next(now);
      final (done, total) = plan.weekProgress(w.clamp(0, plan.weeks - 1), now);
      final todayDone = today != null && plan.status(today, now) == DayStatus.done;
      return Card(
        key: const Key('weeklyPlanCard'),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeeklyPlanScreen())),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(row.name, style: text.titleMedium, overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      w < 0
                          ? 'Starts ${_short(plan.start)}'
                          : (plan.finishedBy(now) ? 'Finished' : 'Week ${w + 1} of ${plan.weeks}'),
                      style: text.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (w >= 0 && w < plan.weeks) _WeekStrip(plan: plan, week: w),
                const SizedBox(height: 10),
                if (today != null && !todayDone)
                  Row(
                    children: [
                      Expanded(
                        child: Text('Today: ${today.describe}', style: text.titleSmall, key: const Key('todayRun')),
                      ),
                      FilledButton.icon(
                        key: const Key('startPlanRun'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        onPressed: () => startPlanDay(context, today),
                      ),
                    ],
                  )
                else
                  Text(
                    todayDone
                        ? 'Today\'s run done ✓${next != null && next != today ? ' · next: ${_dayNames[next.weekday - 1]} ${next.describe}' : ''}'
                        : (next == null
                              ? 'No more runs planned'
                              : 'Rest day · next: ${_dayNames[next.weekday - 1]} ${next.describe}'),
                    style: text.bodyMedium,
                  ),
                if (w >= 0 && w < plan.weeks)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('$done of $total runs this week', style: text.bodySmall),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Home: "Today's run" from the plan (only when there is one to do).
class TodayRunCard extends StatelessWidget {
  const TodayRunCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _withPlan(context, (row, plan) {
      final now = DateTime.now();
      final today = plan?.today(now);
      if (plan == null || today == null || plan.status(today, now) == DayStatus.done) {
        return const SizedBox.shrink();
      }
      return Card(
        key: const Key('todayRunHome'),
        child: ListTile(
          leading: const Icon(Icons.directions_run),
          title: Text('Today\'s run: ${today.describe}'),
          subtitle: Text(row!.name),
          trailing: FilledButton(onPressed: () => startPlanDay(context, today), child: const Text('Start')),
        ),
      );
    });
  }
}

/// M T W T F S S with a dot per planned run, coloured by status.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.plan, required this.week});

  final WeeklyPlan plan;
  final int week;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = plan.week(week);
    return Row(
      children: [
        for (final wd in weekdayOrder)
          Expanded(
            child: Builder(
              builder: (context) {
                final d = days.where((x) => x.weekday == wd).firstOrNull;
                final isToday = plan.weekIndex(now) == week && now.weekday == wd;
                return Column(
                  children: [
                    Text(
                      _dayLetters[wd - 1],
                      style: TextStyle(fontWeight: isToday ? FontWeight.w900 : FontWeight.w400),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      d == null
                          ? Icons.remove
                          : (plan.status(d, now) == DayStatus.done ? Icons.check_circle : Icons.circle),
                      size: d == null ? 14 : 18,
                      color: d == null
                          ? Theme.of(context).colorScheme.outlineVariant
                          : _statusColor(context, plan.status(d, now)),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

String _short(DateTime d) => '${d.day}.${d.month}';

/// The whole plan, week by week.
class WeeklyPlanScreen extends StatelessWidget {
  const WeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _withPlan(context, (row, plan) {
      if (row == null || plan == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Running plan')),
          body: const Center(child: Text('No plan')),
        );
      }
      final now = DateTime.now();
      final (done, total) = plan.totalProgress(now);
      final text = Theme.of(context).textTheme;
      return Scaffold(
        appBar: AppBar(
          title: Text(row.name),
          actions: [
            IconButton(
              tooltip: 'Edit plan',
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => WeeklyPlanEditor(existing: row))),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v != 'delete') return;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete this plan?'),
                    content: const Text('Your runs stay in the history.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                await Services.of(context).trainingPlans.delete(row.id);
                if (context.mounted) Navigator.of(context).pop();
              },
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete plan'))],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('$done of $total planned runs done', style: text.titleMedium),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            for (var w = 0; w < plan.weeks; w++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week ${w + 1} · ${_short(plan.start.add(Duration(days: w * 7)))}'
                        '${plan.weekIndex(now) == w ? ' · this week' : ''}',
                        style: text.titleSmall,
                      ),
                      if (plan.week(w).isEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Rest week')),
                      for (final d in plan.week(w))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            plan.status(d, now) == DayStatus.done ? Icons.check_circle : Icons.circle_outlined,
                            color: _statusColor(context, plan.status(d, now)),
                          ),
                          title: Text('${_dayNames[d.weekday - 1]} · ${d.describe}'),
                          trailing: plan.status(d, now) == DayStatus.today
                              ? FilledButton(onPressed: () => startPlanDay(context, d), child: const Text('Start'))
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

/// Build or edit the plan: name, start week, number of weeks, and each day.
class WeeklyPlanEditor extends StatefulWidget {
  const WeeklyPlanEditor({super.key, this.existing});

  final TrainingPlan? existing;

  @override
  State<WeeklyPlanEditor> createState() => _WeeklyPlanEditorState();
}

class _WeeklyPlanEditorState extends State<WeeklyPlanEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? 'My running plan');
  late DateTime _start = widget.existing?.startDate ?? weekStart(DateTime.now());
  late int _weeks = widget.existing?.weeks ?? 4;
  late List<PlanDay> _days = decodePlanDays(widget.existing?.daysJson);
  int _week = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  PlanDay? _dayAt(int weekday) => _days.where((d) => d.week == _week && d.weekday == weekday).firstOrNull;

  void _set(int weekday, PlanDay? d) => setState(() {
    _days = [
      for (final x in _days)
        if (!(x.week == _week && x.weekday == weekday)) x,
      ?d,
    ];
  });

  Future<void> _editDay(int weekday) async {
    final result = await showModalBottomSheet<_DayChoice>(
      context: context,
      isScrollControlled: true,
      builder: (c) => _DayEditor(week: _week, weekday: weekday, current: _dayAt(weekday)),
    );
    if (result != null) _set(weekday, result.day);
  }

  void _copyToLaterWeeks() {
    final src = _days.where((d) => d.week == _week).toList();
    setState(() {
      _days = [
        for (final d in _days)
          if (d.week <= _week) d,
        for (var w = _week + 1; w < _weeks; w++)
          for (final d in src) d.copyWith(week: w),
      ];
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Week ${_week + 1} copied to weeks ${_week + 2}–$_weeks')));
  }

  Future<void> _save() async {
    await Services.of(context).trainingPlans.save(
      id: widget.existing?.id,
      name: _name.text.trim().isEmpty ? 'My running plan' : _name.text.trim(),
      start: _start,
      weeks: _weeks,
      days: _days,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (_week >= _weeks) _week = _weeks - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New running plan' : 'Edit running plan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(key: const Key('savePlan'), onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('planName'),
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text('Starts Sun ${_short(_start)}'),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _start,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _start = weekStart(d));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('planWeeks'),
                  icon: const Icon(Icons.date_range),
                  label: Text('$_weeks weeks'),
                  onPressed: () async {
                    final v = await promptNumber(context, title: 'How many weeks?', initial: _weeks, min: 1, max: 52);
                    if (v != null) setState(() => _weeks = v.round());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var w = 0; w < _weeks; w++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      key: Key('planWeek_$w'),
                      label: Text('Week ${w + 1}'),
                      selected: _week == w,
                      onSelected: (_) => setState(() => _week = w),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final wd in weekdayOrder)
            Card(
              child: ListTile(
                key: Key('planDay_$wd'),
                leading: SizedBox(width: 40, child: Text(_dayNames[wd - 1], style: text.titleSmall)),
                title: Text(_dayAt(wd)?.describe ?? 'Rest'),
                textColor: _dayAt(wd) == null ? Theme.of(context).colorScheme.outline : null,
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _editDay(wd),
              ),
            ),
          if (_week < _weeks - 1)
            TextButton.icon(
              key: const Key('copyWeek'),
              icon: const Icon(Icons.copy_all),
              label: Text('Copy week ${_week + 1} to all later weeks'),
              onPressed: _copyToLaterWeeks,
            ),
          const SizedBox(height: 8),
          Text('Tip: plan week 1, copy it to the rest, then change the long run in each week.', style: text.bodySmall),
        ],
      ),
    );
  }
}

/// Result of the day sheet (day null = rest day).
class _DayChoice {
  const _DayChoice(this.day);
  final PlanDay? day;
}

class _DayEditor extends StatefulWidget {
  const _DayEditor({required this.week, required this.weekday, required this.current});

  final int week;
  final int weekday;
  final PlanDay? current;

  @override
  State<_DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<_DayEditor> {
  late PlanDayKind? _kind = widget.current?.kind;
  late bool _byKm = widget.current?.durationS == null;
  // Distance in the shown unit (km or miles), time in minutes.
  late double? _amount = widget.current?.distanceM != null
      ? double.parse(Units.toD(widget.current!.distanceM!.toDouble()).toStringAsFixed(2))
      : (widget.current?.durationS != null ? widget.current!.durationS! / 60 : null);
  late String? _runPlanId = widget.current?.runPlanId;
  String? _runPlanName;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_dayNames[widget.weekday - 1]} · week ${widget.week + 1}', style: text.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('kind_rest'),
                  label: const Text('Rest'),
                  selected: _kind == null,
                  onSelected: (_) => setState(() => _kind = null),
                ),
                for (final k in PlanDayKind.values)
                  ChoiceChip(
                    key: Key('kind_${k.name}'),
                    label: Text(k.label),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
              ],
            ),
            if (_kind != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: true, label: Text(Units.d)),
                      const ButtonSegment(value: false, label: Text('min')),
                    ],
                    selected: {_byKm},
                    onSelectionChanged: (v) => setState(() => _byKm = v.first),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('dayAmount'),
                      onPressed: () async {
                        final v = await promptNumber(
                          context,
                          title: _byKm ? 'Distance (${Units.d})' : 'Time (minutes)',
                          initial: _amount,
                          decimal: _byKm,
                          max: _byKm ? 100 : 600,
                        );
                        if (v != null) setState(() => _amount = v.toDouble());
                      },
                      child: Text(
                        _amount == null
                            ? 'Set amount'
                            : '${_byKm ? formatKg(_amount) : _amount!.round()} ${_byKm ? Units.d : 'min'}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<RunPlan>>(
                stream: s.runPlans.watchAll(),
                builder: (context, snap) {
                  final plans = snap.data ?? const <RunPlan>[];
                  if (plans.isEmpty) return const SizedBox.shrink();
                  return DropdownButtonFormField<String?>(
                    initialValue: plans.any((p) => p.id == _runPlanId) ? _runPlanId : null,
                    decoration: const InputDecoration(
                      labelText: 'Or one of your planned runs',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None')),
                      for (final p in plans) DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
                    ],
                    onChanged: (v) => setState(() {
                      _runPlanId = v;
                      _runPlanName = plans.where((p) => p.id == v).firstOrNull?.name;
                    }),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('saveDay'),
                onPressed: () {
                  final k = _kind;
                  final a = _amount;
                  Navigator.pop(
                    context,
                    _DayChoice(
                      k == null
                          ? null
                          : PlanDay(
                              week: widget.week,
                              weekday: widget.weekday,
                              kind: k,
                              distanceM: _runPlanId == null && a != null && _byKm ? Units.fromD(a).round() : null,
                              durationS: _runPlanId == null && a != null && !_byKm ? (a * 60).round() : null,
                              runPlanId: _runPlanId,
                              runPlanName: _runPlanId == null ? null : (_runPlanName ?? widget.current?.runPlanName),
                            ),
                    ),
                  );
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
