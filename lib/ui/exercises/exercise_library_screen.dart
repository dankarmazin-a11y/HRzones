import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../workout/training_level.dart';
import '../../workout/training_place.dart';
import '../body_map.dart';
import 'custom_exercise_screen.dart';
import 'exercise_avatar.dart';
import 'exercise_detail_screen.dart';

/// Browse/search all exercises. With [pickMode] it returns the selected
/// exercises (multi-select) via Navigator.pop.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key, this.pickMode = false, this.initialGroup});

  final bool pickMode;

  /// Start with this type filter (e.g. stretching).
  final ExerciseGroup? initialGroup;

  static Future<List<Exercise>?> pick(BuildContext context, {ExerciseGroup? group}) => Navigator.of(context)
      .push<List<Exercise>>(
        MaterialPageRoute(
          builder: (_) => ExerciseLibraryScreen(pickMode: true, initialGroup: group),
          fullscreenDialog: true,
        ),
      );

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _query = '';
  String? _muscle;
  String? _equipment;
  late ExerciseGroup? _group = widget.initialGroup;
  bool _showMap = false;

  /// Ignore the training level and list every exercise.
  bool _allLevels = false;

  /// Ignore where the user trains and list every piece of equipment.
  bool _allEquipment = false;

  /// Where you train decides the equipment (in a workout, hybrid trainers'
  /// place for today).
  TrainingPlace get _place {
    final s = Services.of(context);
    return s.effectivePlace(inWorkout: widget.pickMode && s.session.active != null);
  }

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
    final s = Services.of(context);
    final level = s.level.value;
    final r = await s.exercises.search(
      query: _query,
      muscle: _muscle,
      equipment: _equipment,
      group: _group,
      levels: _allLevels ? null : level.exerciseLevels,
      allowedEquipment: _allEquipment ? null : _place.equipment,
    );
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
        title: Text(
          !widget.pickMode
              ? 'Exercises'
              : (widget.initialGroup == ExerciseGroup.stretching ? 'Add stretches' : 'Add exercises'),
        ),
        actions: [
          IconButton(
            key: const Key('toggleBodyMap'),
            tooltip: 'Body map',
            isSelected: _showMap,
            icon: const Icon(Icons.accessibility_new),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(tooltip: 'Custom exercise', icon: const Icon(Icons.add), onPressed: _createCustom),
        ],
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
          if (_showMap)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                height: 220,
                child: BodyMap(
                  selected: _muscle == null ? const {} : musclesOf(_muscle!).toSet(),
                  onTap: (m) {
                    // Beginners filter by simple groups (Back, Arms…).
                    final detailed = Services.of(context).level.value.detailedMuscles;
                    final pick = m == null || detailed ? m : simpleGroupOf(m);
                    setState(() => _muscle = pick == _muscle ? null : pick);
                    _search();
                  },
                ),
              ),
            ),
          _FilterRow(
            label: 'Type',
            options: const ['strength', 'stretching', 'cardio', 'timers'],
            selected: _group?.name,
            onChanged: (v) {
              _group = v == null ? null : ExerciseGroup.values.byName(v);
              _search();
            },
          ),
          _FilterRow(
            label: 'Muscle',
            options: Services.of(context).level.value.detailedMuscles ? muscleGroups : simpleMuscleGroups.keys.toList(),
            selected: _muscle,
            onChanged: (v) {
              _muscle = v;
              _search();
            },
          ),
          if (Services.of(context).level.value != TrainingLevel.advanced)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _allLevels
                          ? 'Showing every level'
                          : 'Showing ${Services.of(context).level.value.label.toLowerCase()} exercises + the popular ones',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  FilterChip(
                    key: const Key('allLevels'),
                    label: const Text('All levels'),
                    selected: _allLevels,
                    onSelected: (v) {
                      setState(() => _allLevels = v);
                      _search();
                    },
                  ),
                ],
              ),
            ),
          if (_place.equipment != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _allEquipment
                          ? 'Showing all equipment'
                          : 'Showing ${_place.label.toLowerCase()} equipment (Profile › Where you train)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  FilterChip(
                    key: const Key('allEquipment'),
                    label: const Text('All equipment'),
                    selected: _allEquipment,
                    onSelected: (v) {
                      setState(() => _allEquipment = v);
                      _search();
                    },
                  ),
                ],
              ),
            ),
          _FilterRow(
            label: 'Equipment',
            options: [
              for (final e in equipmentTypes)
                if (_allEquipment || _place.allows(e)) e,
            ],
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
                  leading: ExerciseAvatar(exercise: e),
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
