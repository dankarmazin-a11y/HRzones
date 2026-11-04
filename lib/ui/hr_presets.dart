import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/database.dart';
import '../hr/hr_monitor.dart';
import '../hr/zones.dart';
import 'number_input.dart';
import 'zone_colors.dart';

String useLabel(PresetUse u) => switch (u) {
  PresetUse.any => 'Strength & running',
  PresetUse.strength => 'Strength',
  PresetUse.run => 'Running',
};

IconData useIcon(PresetUse u) => switch (u) {
  PresetUse.any => Icons.all_inclusive,
  PresetUse.strength => Icons.fitness_center,
  PresetUse.run => Icons.directions_run,
};

/// Zones screen: the list of named heart-rate presets.
class HrPresetsSection extends StatelessWidget {
  const HrPresetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    final zones = HrScope.of(context).zones;
    return StreamBuilder<List<HrPreset>>(
      stream: s.presets.watchAll(),
      builder: (context, snap) {
        final list = snap.data ?? const <HrPreset>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Zone presets', style: text.titleMedium)),
                TextButton.icon(
                  key: const Key('newPreset'),
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                  onPressed: () => editPreset(context),
                ),
              ],
            ),
            Text(
              'Name a heart-rate range, choose strength or running, and pick it when you start a workout or '
              'save it in a template.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 8),
            if (list.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('No presets yet'),
                  subtitle: Text('e.g. "Easy run" ${zones.zones[1].minBpm}–${zones.zones[1].maxBpm} bpm (your zone 2)'),
                  onTap: () => editPreset(context),
                ),
              ),
            for (final p in list)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: zoneColor(zones.zoneFor((p.minBpm + p.maxBpm) ~/ 2)?.number),
                    child: Icon(useIcon(p.use), size: 18, color: Colors.white),
                  ),
                  title: Text(p.name),
                  subtitle: Text('${p.minBpm}–${p.maxBpm} bpm · ${useLabel(p.use)}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => v == 'delete' ? s.presets.delete(p.id) : editPreset(context, p),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => editPreset(context, p),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Create or edit a preset (name, range, strength/running).
Future<void> editPreset(BuildContext context, [HrPreset? existing]) async {
  final s = Services.of(context);
  final zones = HrScope.of(context).zones;
  final name = TextEditingController(text: existing?.name ?? '');
  var min = existing?.minBpm ?? zones.zones[1].minBpm;
  var max = existing?.maxBpm ?? zones.zones[1].maxBpm;
  var use = existing?.use ?? PresetUse.any;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: Text(existing == null ? 'New zone preset' : 'Edit preset'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('presetName'),
                controller: name,
                autofocus: existing == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'Easy run'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Range: '),
                  EditableNumber(
                    value: min,
                    title: 'Minimum (bpm)',
                    min: 40,
                    max: max - 1,
                    onChanged: (v) => setState(() => min = v.round()),
                  ),
                  const Text(' – '),
                  EditableNumber(
                    value: max,
                    title: 'Maximum (bpm)',
                    min: min + 1,
                    max: 240,
                    onChanged: (v) => setState(() => max = v.round()),
                  ),
                  const Text(' bpm'),
                ],
              ),
              RangeSlider(
                min: 60,
                max: 220,
                divisions: 160,
                values: RangeValues(min.clamp(60, 219).toDouble(), max.clamp(61, 220).toDouble()),
                onChanged: (v) => setState(() {
                  if (v.end - v.start < 1) return;
                  min = v.start.round();
                  max = v.end.round();
                }),
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final z in zones.zones)
                    ActionChip(
                      label: Text('Z${z.number}'),
                      avatar: CircleAvatar(backgroundColor: zoneColor(z.number)),
                      onPressed: () => setState(() {
                        min = z.minBpm;
                        max = z.maxBpm;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('For'),
              const SizedBox(height: 4),
              SegmentedButton<PresetUse>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: PresetUse.strength, label: Text('Strength')),
                  ButtonSegment(value: PresetUse.run, label: Text('Running')),
                  ButtonSegment(value: PresetUse.any, label: Text('Both')),
                ],
                selected: {use},
                onSelectionChanged: (v) => setState(() => use = v.first),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
        ],
      ),
    ),
  );
  if (ok == true) {
    final n = name.text.trim().isEmpty ? '$min–$max bpm' : name.text.trim();
    await s.presets.save(id: existing?.id, name: n, min: min, max: max, use: use);
  }
  name.dispose();
}

/// The user's choice: a preset, or explicitly none.
class PresetChoice {
  const PresetChoice(this.preset);

  final HrPreset? preset;
}

/// Asks which preset to use (or none). Returns null when cancelled, and
/// "no preset" straight away when there are no presets for [use].
Future<PresetChoice?> pickPreset(BuildContext context, PresetUse use, {String? current, bool askIfNone = false}) async {
  final presets = await Services.of(context).presets.forUse(use);
  if (presets.isEmpty && !askIfNone) return const PresetChoice(null);
  if (!context.mounted) return null;
  return showModalBottomSheet<PresetChoice>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Heart-rate zone'), subtitle: Text('Beeps when you leave the range')),
          ListTile(
            leading: const Icon(Icons.do_not_disturb_on_outlined),
            title: const Text('No zone'),
            trailing: current == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(c, const PresetChoice(null)),
          ),
          for (final p in presets)
            ListTile(
              leading: Icon(useIcon(p.use)),
              title: Text(p.name),
              subtitle: Text('${p.minBpm}–${p.maxBpm} bpm'),
              trailing: current == p.id ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(c, PresetChoice(p)),
            ),
          if (presets.isEmpty)
            const ListTile(enabled: false, title: Text('Create presets on the HR zones screen (Profile)')),
        ],
      ),
    ),
  );
}

/// Row inside a workout/template showing the chosen preset; tap to change.
class PresetRow extends StatelessWidget {
  const PresetRow({super.key, required this.presetId, required this.onChanged, this.use = PresetUse.strength});

  final String? presetId;
  final ValueChanged<HrPreset?> onChanged;
  final PresetUse use;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return FutureBuilder<HrPreset?>(
      future: s.presets.byId(presetId),
      builder: (context, snap) {
        final p = snap.data;
        return ListTile(
          key: const Key('presetRow'),
          dense: true,
          leading: Icon(Icons.monitor_heart_outlined, color: p == null ? null : zoneColor(2)),
          title: Text(p == null ? 'No heart-rate zone' : '${p.name} · ${p.minBpm}–${p.maxBpm} bpm'),
          trailing: const Icon(Icons.edit_outlined, size: 18),
          onTap: () async {
            final choice = await pickPreset(context, use, current: presetId, askIfNone: true);
            if (choice != null) onChanged(choice.preset);
          },
        );
      },
    );
  }
}

/// Range text for a preset (used in summaries).
String presetRange(HrPreset p) => HrRange(min: p.minBpm, max: p.maxBpm).toString();
