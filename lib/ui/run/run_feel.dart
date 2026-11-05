import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../data/run_repository.dart';

/// Weather tags for a run (stored by key, comma-separated).
const runWeather = <String, String>{
  'sunny': '☀️ Sunny',
  'cloudy': '☁️ Cloudy',
  'rain': '🌧 Rain',
  'wind': '💨 Windy',
  'hot': '🥵 Hot',
  'cold': '🥶 Cold',
};

/// Words for the effort scale (1–10).
String effortWord(int e) => switch (e) {
  <= 2 => 'Very easy',
  <= 4 => 'Easy',
  <= 6 => 'Moderate',
  <= 8 => 'Hard',
  _ => 'Max effort',
};

/// After a run: how hard it felt (1–10), the weather and notes. Saved as
/// you go.
class RunFeelCard extends StatefulWidget {
  const RunFeelCard({super.key, required this.run});

  final Run run;

  @override
  State<RunFeelCard> createState() => _RunFeelCardState();
}

class _RunFeelCardState extends State<RunFeelCard> {
  late int? _effort = widget.run.effort;
  late final Set<String> _weather = {...?widget.run.weather?.split(',').where((w) => w.isNotEmpty)};
  late final _notes = TextEditingController(text: widget.run.notes);
  Timer? _debounce;
  late RunRepository _repo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = Services.of(context).runs; // (context can't be used in dispose)
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_notes.text != widget.run.notes) _saveNotes(); // typed and left quickly
    _notes.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() => _repo.updateNotes(widget.run.id, notes: _notes.text.trim());

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      key: const Key('runFeel'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('How did it feel?', style: text.titleMedium)),
                if (_effort != null) Text(effortWord(_effort!), style: text.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var e = 1; e <= 10; e++)
                  ChoiceChip(
                    key: Key('effort_$e'),
                    label: Text('$e'),
                    selected: _effort == e,
                    visualDensity: VisualDensity.compact,
                    onSelected: (on) {
                      setState(() => _effort = on ? e : null);
                      s.runs.updateNotes(widget.run.id, effort: on ? e : null, clearEffort: !on);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final w in runWeather.entries)
                  FilterChip(
                    key: Key('weather_${w.key}'),
                    label: Text(w.value),
                    selected: _weather.contains(w.key),
                    onSelected: (on) {
                      setState(() => on ? _weather.add(w.key) : _weather.remove(w.key));
                      s.runs.updateNotes(widget.run.id, weather: _weather.join(','));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('runNotes'),
              controller: _notes,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Notes (route, shoes, how the legs felt…)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 800), _saveNotes);
              },
            ),
          ],
        ),
      ),
    );
  }
}
