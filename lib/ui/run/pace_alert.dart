import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../hr/zones.dart';
import '../../run/geo.dart';

/// "Pace alert" row: off, or the target pace range. Tap to change.
class PaceAlertRow extends StatefulWidget {
  const PaceAlertRow({super.key});

  @override
  State<PaceAlertRow> createState() => _PaceAlertRowState();
}

class _PaceAlertRowState extends State<PaceAlertRow> {
  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final range = s.run.paceAlert;
    return ListTile(
      key: const Key('paceAlertRow'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.speed),
      title: const Text('Pace alert'),
      subtitle: Text(
        range == null
            ? 'Off – tap to beep when you run faster or slower than a target pace'
            : '${formatPace(range.min.toDouble())}–${formatPace(range.max.toDouble())} /km',
      ),
      trailing: range == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              key: const Key('paceAlertOff'),
              tooltip: 'Turn off',
              icon: const Icon(Icons.close),
              onPressed: () async {
                await s.setPaceAlert(null);
                setState(() {});
              },
            ),
      onTap: () async {
        final r = await pickPaceRange(context, range);
        if (r == null) return;
        await s.setPaceAlert(r);
        if (mounted) setState(() {});
      },
    );
  }
}

/// Asks for a pace range: fastest and slowest pace per km (± 5 s, or type).
Future<HrRange?> pickPaceRange(BuildContext context, HrRange? current) async {
  var fast = current?.min ?? 330, slow = current?.max ?? 360;
  return showDialog<HrRange>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) {
        Widget row(String label, int value, ValueChanged<int> set, Key key) => Row(
          children: [
            Expanded(child: Text(label)),
            IconButton(onPressed: () => set(value - 5), icon: const Icon(Icons.remove)),
            TextButton(
              key: key,
              onPressed: () async {
                final v = await promptPace(c, label, value);
                if (v != null) set(v);
              },
              child: Text(formatPace(value.toDouble()), style: Theme.of(c).textTheme.titleLarge),
            ),
            IconButton(onPressed: () => set(value + 5), icon: const Icon(Icons.add)),
          ],
        );
        return AlertDialog(
          title: const Text('Target pace (per km)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row('Fastest', fast, (v) => setState(() => fast = v.clamp(120, slow - 5)), const Key('paceFast')),
              row('Slowest', slow, (v) => setState(() => slow = v.clamp(fast + 5, 1200)), const Key('paceSlow')),
              const SizedBox(height: 8),
              Text(
                'You get beeps (and a voice) when your pace stays outside this range for 10 seconds.',
                style: Theme.of(c).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            FilledButton(
              key: const Key('savePace'),
              onPressed: () => Navigator.pop(c, HrRange(min: fast, max: slow)),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

/// Type a pace as m:ss (or just minutes). Returns seconds per km.
Future<int?> promptPace(BuildContext context, String title, int current) async {
  final v = await showDialog<String>(
    context: context,
    builder: (_) => _PaceInputDialog(title: '$title (m:ss per km)', initial: formatPace(current.toDouble())),
  );
  if (v == null) return null;
  final m = RegExp(r'^\s*(\d{1,2})(?:[:.,](\d{1,2}))?\s*$').firstMatch(v);
  if (m == null) return null;
  return int.parse(m[1]!) * 60 + int.parse(m[2] ?? '0');
}

/// Owns its text controller, so it lives until the dialog's closing
/// animation has finished.
class _PaceInputDialog extends StatefulWidget {
  const _PaceInputDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_PaceInputDialog> createState() => _PaceInputDialogState();
}

class _PaceInputDialogState extends State<_PaceInputDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const Key('paceInput'),
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.datetime,
      onSubmitted: (t) => Navigator.pop(context, t),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('OK')),
    ],
  );
}
