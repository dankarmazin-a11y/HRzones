part of 'active_workout_screen.dart';

/// Asks for a date and time (for logging or editing a past workout).
Future<DateTime?> pickWorkoutStart(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: initial.isAfter(now) ? now : initial,
    firstDate: DateTime(now.year - 5),
    lastDate: now,
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// A number cell in a set row: tapping it (or reaching it with Next) selects
/// the whole value, so typing replaces it. Tapping outside closes the
/// keyboard.
class SetNumberField extends StatefulWidget {
  const SetNumberField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.decimal = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool decimal;
  final bool autofocus;

  @override
  State<SetNumberField> createState() => _SetNumberFieldState();
}

class _SetNumberFieldState extends State<SetNumberField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) _selectAll();
    });
  }

  void _selectAll() {
    // After the tap has placed the cursor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = widget.controller;
      if (_focus.hasFocus) c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      autofocus: widget.autofocus,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(widget.decimal ? r'[0-9.,]' : r'[0-9]'))],
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onTap: _selectAll,
      onTapOutside: (_) => _focus.unfocus(),
      onChanged: widget.onChanged,
    );
  }
}

/// Moves to the next number field (kg → reps → next set's kg), skipping the
/// buttons in between (RPE, ✓) – landing on those closed the keyboard.
void focusNextNumberField(BuildContext context) {
  final current = FocusManager.instance.primaryFocus;
  bool isText(FocusNode n) => n.context?.findAncestorWidgetOfExactType<EditableText>() != null;
  // Text fields on this screen in reading order (rows top → bottom, then left
  // → right). Positions are used because focus changes apply only on the
  // next frame, so stepping with nextFocus() can't check where it landed.
  final fields = FocusScope.of(context).traversalDescendants.where((n) => n.canRequestFocus && isText(n)).toList()
    ..sort((a, b) {
      final dy = a.rect.top - b.rect.top;
      return dy.abs() > 4 ? dy.sign.toInt() : a.rect.left.compareTo(b.rect.left);
    });
  final i = current == null ? -1 : fields.indexOf(current);
  if (i + 1 < fields.length) {
    fields[i + 1].requestFocus();
  } else {
    current?.unfocus(); // last field: close the keyboard
  }
}

/// Above the keyboard while typing in a workout: Next (kg → reps → next
/// set) and Done. The iPhone number pad has no return key, so without this
/// the keyboard could not be closed.
class KeyboardBar extends StatelessWidget {
  const KeyboardBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Part of the text fields' tap region: tapping here doesn't count as
    // "tap outside".
    return TextFieldTapRegion(
      child: Material(
        color: scheme.surfaceContainerHighest,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const Spacer(),
              TextButton(
                key: const Key('keyboardNext'),
                onPressed: () => focusNextNumberField(context),
                child: const Text('Next'),
              ),
              TextButton(
                key: const Key('keyboardDone'),
                onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for a note's text. Returns null when cancelled ('' = remove it).
Future<String?> askNote(BuildContext context, String title, String initial, {String? help}) async {
  final c = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (help != null) Text(help, style: Theme.of(ctx).textTheme.bodySmall),
          TextField(
            key: const Key('noteText'),
            controller: c,
            autofocus: true,
            maxLines: 4,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'e.g. seat on 4, grip just outside the rings'),
          ),
        ],
      ),
      actions: [
        if (initial.isNotEmpty) TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Remove')),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          key: const Key('saveNote'),
          onPressed: () => Navigator.pop(ctx, c.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  c.dispose();
  return result;
}
