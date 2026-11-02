import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Asks the user to type a number. Returns null when cancelled or invalid.
Future<num?> promptNumber(
  BuildContext context, {
  required String title,
  num? initial,
  num min = 0,
  num max = 100000,
  bool decimal = false,
  String? suffix,
}) async {
  final controller = TextEditingController(
    text: initial == null ? '' : (decimal ? initial.toString() : initial.round().toString()),
  );
  controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
  String? error;
  final result = await showDialog<num>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) {
        void submit() {
          final v = decimal
              ? double.tryParse(controller.text.replaceAll(',', '.'))
              : int.tryParse(controller.text.trim());
          if (v == null || v < min || v > max) {
            setState(() => error = 'Enter a number from ${_fmt(min)} to ${_fmt(max)}');
            return;
          }
          Navigator.pop(c, v);
        }

        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]'))],
            decoration: InputDecoration(suffixText: suffix, errorText: error),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            FilledButton(onPressed: submit, child: const Text('OK')),
          ],
        );
      },
    ),
  );
  controller.dispose();
  return result;
}

String _fmt(num v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

/// A number shown as tappable text (dotted underline). Tapping lets the user
/// type a new value instead of using the slider/buttons next to it.
class EditableNumber extends StatelessWidget {
  const EditableNumber({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.min = 0,
    this.max = 100000,
    this.decimal = false,
    this.suffix,
    this.display,
    this.style,
  });

  final num value;
  final ValueChanged<num> onChanged;
  final String title;
  final num min;
  final num max;
  final bool decimal;
  final String? suffix;

  /// Text to show instead of the plain number (e.g. "1:30").
  final String? display;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final v = await promptNumber(
          context,
          title: title,
          initial: value,
          min: min,
          max: max,
          decimal: decimal,
          suffix: suffix,
        );
        if (v != null) onChanged(v);
      },
      child: Text(
        display ?? _fmt(value),
        style: base.copyWith(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: Theme.of(context).colorScheme.primary,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// "Off", "45 s", "1:30".
String formatRest(int seconds) {
  if (seconds <= 0) return 'Off';
  if (seconds < 60) return '$seconds s';
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// Bottom sheet to choose a rest time (presets or typed).
Future<int?> pickRestSeconds(BuildContext context, int current, {String title = 'Rest timer'}) {
  const options = [0, 30, 45, 60, 90, 120, 150, 180, 240, 300];
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: Text(title, style: Theme.of(c).textTheme.titleMedium)),
          for (final o in options)
            ListTile(
              title: Text(formatRest(o)),
              trailing: o == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(c, o),
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Custom…'),
            trailing: options.contains(current) ? null : Text(formatRest(current)),
            onTap: () async {
              final v = await promptNumber(c, title: 'Rest (seconds)', initial: current, max: 3600, suffix: 's');
              if (c.mounted) Navigator.pop(c, v?.round());
            },
          ),
        ],
      ),
    ),
  );
}
