import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import 'custom_exercise_screen.dart';
import 'exercise_detail_screen.dart';

/// Browse/search all exercises. With [pickMode] it returns the selected
/// exercises (multi-select) via Navigator.pop.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key, this.pickMode = false});

  final bool pickMode;

  static Future<List<Exercise>?> pick(BuildContext context) => Navigator.of(context).push<List<Exercise>>(
    MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pickMode: true), fullscreenDialog: true),
  );

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _query = '';
  String? _muscle;
  String? _equipment;
  List<Exercise> _results = [];
  final _selected = <Exercise>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _search();
  }

  Future<void> _search() async {
    final r = await Services.of(context).exercises.search(query: _query, muscle: _muscle, equipment: _equipment);
    if (mounted) setState(() => _results = r);
  }

  void _tap(Exercise e) {
    if (widget.pickMode) {
      setState(() => _selected.contains(e) ? _selected.remove(e) : _selected.add(e));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: e)));
    }
  }

  Future<void> _createCustom() async {
    final created = await Navigator.of(context)
        .push<Exercise>(MaterialPageRoute(builder: (_) => CustomExerciseScreen(initialName: _query)));
    if (created == null) return;
    await _search();
    if (widget.pickMode) setState(() => _selected.add(created));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickMode ? 'Add exercises' : 'Exercises'),
        actions: [IconButton(tooltip: 'Custom exercise', icon: const Icon(Icons.add), onPressed: _createCustom)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search exercises',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                _query = v;
                _search();
              },
            ),
          ),
          _FilterRow(
            label: 'Muscle',
            options: muscleGroups,
            selected: _muscle,
            onChanged: (v) {
              _muscle = v;
              _search();
            },
          ),
          _FilterRow(
            label: 'Equipment',
            options: equipmentTypes,
            selected: _equipment,
            onChanged: (v) {
              _equipment = v;
              _search();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${_results.length} exercises', style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final e = _results[i];
                final selected = _selected.contains(e);
                return ListTile(
                  title: Text(e.name),
                  subtitle: Text(
                    [titleCase(e.primaryMuscle), if (e.equipment != null) titleCase(e.equipment!)].join(' · '),
                  ),
                  leading: CircleAvatar(child: Text(e.name.isEmpty ? '?' : e.name[0])),
                  trailing: widget.pickMode
                      ? Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked)
                      : (e.isCustom ? const Chip(label: Text('Custom')) : null),
                  selected: selected,
                  onTap: () => _tap(e),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.pickMode && _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pop(List<Exercise>.of(_selected)),
              icon: const Icon(Icons.check),
              label: Text('Add ${_selected.length}'),
            )
          : null,
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.options, required this.selected, required this.onChanged});

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
          ),
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(titleCase(o)),
                selected: selected == o,
                onSelected: (on) => onChanged(on ? o : null),
              ),
            ),
        ],
      ),
    );
  }
}
