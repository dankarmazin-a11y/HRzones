import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/preset_repository.dart';
import '../number_input.dart';
import 'timers_screen.dart';

/// Create or edit an interval timer: name, rounds and segments.
class IntervalEditorScreen extends StatefulWidget {
  const IntervalEditorScreen({super.key, this.existing});

  final IntervalPreset? existing;

  @override
  State<IntervalEditorScreen> createState() => _IntervalEditorScreenState();
}

class _IntervalEditorScreenState extends State<IntervalEditorScreen> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late int _rounds = widget.existing?.rounds ?? 4;
  late final List<IntervalSegment> _segments = widget.existing == null
      ? [
          const IntervalSegment(label: 'Work', seconds: 40),
          const IntervalSegment(label: 'Rest', seconds: 20, work: false),
        ]
      : decodeSegments(widget.existing!.segmentsJson);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_segments.isEmpty) return;
    final name = _name.text.trim().isEmpty ? 'My timer' : _name.text.trim();
    await Services.of(context).intervals
        .save(id: widget.existing?.id, name: name, rounds: _rounds, segments: _segments);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _renameSegment(int i) async {
    final c = TextEditingController(text: _segments[i].label);
    final label = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Segment name'),
        content: TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.sentences),
        actions: [TextButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('OK'))],
      ),
    );
    if (label != null && label.isNotEmpty) setState(() => _segments[i] = _segments[i].copyWith(label: label));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New timer' : 'Edit timer'),
        actions: [
          IconButton(
            tooltip: 'Try it',
            icon: const Icon(Icons.play_arrow),
            onPressed: () => runIntervals(context, name: _name.text, rounds: _rounds, segments: _segments),
          ),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Hill sprints',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Rounds: ', style: text.titleMedium),
              EditableNumber(
                value: _rounds,
                title: 'Rounds',
                min: 1,
                max: 100,
                style: text.titleMedium,
                onChanged: (v) => setState(() => _rounds = v.round()),
              ),
              const Spacer(),
              IconButton(
                onPressed: _rounds > 1 ? () => setState(() => _rounds--) : null,
                icon: const Icon(Icons.remove),
              ),
              IconButton(onPressed: () => setState(() => _rounds++), icon: const Icon(Icons.add)),
            ],
          ),
          Text(intervalSummary(_segments, _rounds), style: text.bodySmall),
          const SizedBox(height: 16),
          Text('Each round', style: text.titleMedium),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _segments.length,
            onReorderItem: (from, to) => setState(() => _segments.insert(to, _segments.removeAt(from))),
            itemBuilder: (context, i) {
              final seg = _segments[i];
              return Card(
                key: ObjectKey(seg),
                child: ListTile(
                  leading: ActionChip(
                    label: Text(seg.work ? 'Work' : 'Rest'),
                    backgroundColor: seg.work
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.blue.withValues(alpha: 0.2),
                    onPressed: () => setState(() => _segments[i] = seg.copyWith(work: !seg.work)),
                  ),
                  title: InkWell(onTap: () => _renameSegment(i), child: Text('${seg.label}  ✎')),
                  subtitle: Row(
                    children: [
                      EditableNumber(
                        value: seg.seconds,
                        title: 'Seconds',
                        min: 1,
                        max: 7200,
                        suffix: 's',
                        display: formatRest(seg.seconds),
                        onChanged: (v) => setState(() => _segments[i] = seg.copyWith(seconds: v.round())),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _segments.length > 1 ? () => setState(() => _segments.removeAt(i)) : null,
                      ),
                      ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add segment'),
            onPressed: () => setState(
              () => _segments.add(IntervalSegment(label: _segments.length.isEven ? 'Work' : 'Rest', seconds: 30)),
            ),
          ),
        ],
      ),
    );
  }
}
