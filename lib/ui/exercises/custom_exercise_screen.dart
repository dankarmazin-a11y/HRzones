import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/exercise_repository.dart';

/// Create a custom exercise; pops with the new [Exercise].
class CustomExerciseScreen extends StatefulWidget {
  const CustomExerciseScreen({super.key, this.initialName = ''});

  final String initialName;

  @override
  State<CustomExerciseScreen> createState() => _CustomExerciseScreenState();
}

class _CustomExerciseScreenState extends State<CustomExerciseScreen> {
  late final _name = TextEditingController(text: widget.initialName);
  String _muscle = muscleGroups.first;
  String? _equipment;
  TrackingType _tracking = TrackingType.weightReps;

  static const _trackingLabels = {
    TrackingType.weightReps: 'Weight × reps',
    TrackingType.bodyweightReps: 'Bodyweight reps',
    TrackingType.duration: 'Time',
  };

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final e = await Services.of(context).exercises
        .createCustom(name: name, primaryMuscle: _muscle, equipment: _equipment, trackingType: _tracking);
    if (mounted) Navigator.of(context).pop(e);
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
        title: const Text('New exercise'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _muscle,
            decoration: const InputDecoration(labelText: 'Primary muscle', border: OutlineInputBorder()),
            items: [for (final m in muscleGroups) DropdownMenuItem(value: m, child: Text(titleCase(m)))],
            onChanged: (v) => setState(() => _muscle = v ?? _muscle),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _equipment,
            decoration: const InputDecoration(labelText: 'Equipment', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              for (final m in equipmentTypes) DropdownMenuItem(value: m, child: Text(titleCase(m))),
            ],
            onChanged: (v) => setState(() => _equipment = v),
          ),
          const SizedBox(height: 16),
          SegmentedButton<TrackingType>(
            segments: [
              for (final MapEntry(:key, :value) in _trackingLabels.entries)
                ButtonSegment(value: key, label: Text(value)),
            ],
            selected: {_tracking},
            onSelectionChanged: (s) => setState(() => _tracking = s.first),
          ),
        ],
      ),
    );
  }
}
