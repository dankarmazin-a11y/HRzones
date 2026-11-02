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
  ExerciseGroup? _group;
  ExerciseSearchResult _results = const ExerciseSearchResult(popular: [], others: []);
  final _selected = <Exercise>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _search();
  }

  int _searchId = 0;

  Future<void> _search() async {
    // Only the latest search may update the list (an earlier, slower one
    // must not overwrite newer filter results).
    final id = ++_searchId;
    final r = await Services.of(context).exercises
        .search(query: _query, muscle: _muscle, equipment: _equipment, group: _group);
    if (mounted && id == _searchId) setState(() => _results = r);
  }

  /// Section headers (String) and exercises, in display order.
  List<Object> get _rows {
    final r = _results;
    final groupName = _muscle != null ? titleCase(_muscle!) : (_group != null ? titleCase(_group!.name) : null);
    return [
      if (r.popular.isNotEmpty) groupName == null ? 'Most popular' : 'Most popular · $groupName',
      ...r.popular,
      if (r.others.isNotEmpty) r.popular.isEmpty ? '${r.length} exercises (A–Z)' : 'All exercises (A–Z)',
      ...r.others,
    ];
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
            label: 'Type',
            options: const ['strength', 'stretching', 'cardio'],
            selected: _group?.name,
            onChanged: (v) {
              _group = v == null ? null : ExerciseGroup.values.byName(v);
              _search();
            },
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
          Expanded(
            child: ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, i) {
                final row = _rows[i];
                if (row is String) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(row, style: Theme.of(context).textTheme.titleSmall),
                  );
                }
                final e = row as Exercise;
                final selected = _selected.contains(e);
                return ListTile(
                  title: Text(e.name),
                  subtitle: Text(
                    [
                      titleCase(e.primaryMuscle),
                      if (e.equipment != null) titleCase(e.equipment!),
                      if (e.isTimed) 'Timed',
                    ].join(' · '),
                  ),
                  leading: CircleAvatar(
                    child: e.isStretch ? const Icon(Icons.self_improvement) : Text(e.name.isEmpty ? '?' : e.name[0]),
                  ),
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
