import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/template_repository.dart';
import '../exercises/exercise_library_screen.dart';

/// Create or edit a template: name, exercises (reorderable), sets and rest.
class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({super.key, this.existing});

  final TemplateWithSlots? existing;

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late final _name = TextEditingController(text: widget.existing?.template.name ?? '');
  late final List<TemplateSlot> _slots = [
    for (final s in widget.existing?.slots ?? const <TemplateSlot>[])
      TemplateSlot(
        exerciseId: s.exerciseId,
        targetSets: s.targetSets,
        restSeconds: s.restSeconds,
        supersetGroup: s.supersetGroup,
      ),
  ];
  final _exercises = <String, Exercise>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final repo = Services.of(context).exercises;
    for (final s in _slots) {
      final e = await repo.byId(s.exerciseId);
      if (e != null) _exercises[e.id] = e;
    }
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    final picked = await ExerciseLibraryScreen.pick(context);
    if (picked == null) return;
    setState(() {
      for (final e in picked) {
        _exercises[e.id] = e;
        _slots.add(TemplateSlot(exerciseId: e.id, restSeconds: e.defaultRestSeconds));
      }
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a name and at least one exercise')));
      return;
    }
    await Services.of(context).templates.save(id: widget.existing?.template.id, name: name, slots: _slots);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final id = widget.existing?.template.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete template?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await Services.of(context).templates.delete(id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New template' : 'Edit template'),
        actions: [
          if (widget.existing != null) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Template name',
                hintText: 'Push A',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _slots.length,
              onReorderItem: (from, to) => setState(() => _slots.insert(to, _slots.removeAt(from))),
              itemBuilder: (context, i) {
                final s = _slots[i];
                return ListTile(
                  key: ObjectKey(s),
                  title: Text(_exercises[s.exerciseId]?.name ?? '…'),
                  subtitle: Text('${s.targetSets} sets · rest ${s.restSeconds} s'),
                  leading: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setState(() => _slots.removeAt(i)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: s.targetSets > 1 ? () => setState(() => s.targetSets--) : null,
                      ),
                      IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => s.targetSets++)),
                      const Icon(Icons.drag_handle),
                    ],
                  ),
                  onTap: () async {
                    final rest = await pickRestSeconds(context, s.restSeconds);
                    if (rest != null) setState(() => s.restSeconds = rest);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add exercises'),
      ),
    );
  }
}

/// Bottom sheet to choose a rest time.
Future<int?> pickRestSeconds(BuildContext context, int current) {
  const options = [0, 30, 45, 60, 90, 120, 150, 180, 240, 300];
  return showModalBottomSheet<int>(
    context: context,
    builder: (c) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Rest timer')),
          for (final o in options)
            ListTile(
              title: Text(o == 0 ? 'Off' : (o < 60 ? '$o s' : '${o ~/ 60}:${(o % 60).toString().padLeft(2, '0')} min')),
              trailing: o == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(c, o),
            ),
        ],
      ),
    ),
  );
}
