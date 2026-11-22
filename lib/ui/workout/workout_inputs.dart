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
/// The barbell weight being typed (owner, 17 Nov): the keyboard bar shows its
/// plates. Weight in kg; null when no barbell weight field has focus.
typedef PlateTarget = ({String exerciseId, double kg});

/// No plate picture above this (nobody loads more than ~600 kg on a bar).
const maxPreviewKg = 600.0;
final platePreview = ValueNotifier<PlateTarget?>(null);

class SetNumberField extends StatefulWidget {
  const SetNumberField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.decimal = false,
    this.autofocus = false,
    this.plateFor,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool decimal;
  final bool autofocus;

  /// A barbell exercise's weight field: tells [platePreview] what's typed.
  final String? plateFor;

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
      _plates();
    });
    widget.controller.addListener(_plates);
  }

  void _plates() {
    final id = widget.plateFor;
    if (id == null) return;
    if (!_focus.hasFocus) {
      if (platePreview.value?.exerciseId == id) platePreview.value = null;
      return;
    }
    final n = double.tryParse(widget.controller.text.replaceAll(',', '.'));
    final hinted = double.tryParse(widget.hint.replaceAll(',', '.'));
    final shown = n ?? hinted;
    platePreview.value = shown == null || shown <= 0 ? null : (exerciseId: id, kg: Units.fromW(shown));
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
    widget.controller.removeListener(_plates);
    if (widget.plateFor != null && _focus.hasFocus) platePreview.value = null;
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
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(widget.decimal ? r'[0-9.,]' : r'[0-9]')),
        // "999.75" at most – a stray 1000000 crashed the app (22 Nov)
        LengthLimitingTextInputFormatter(widget.decimal ? 6 : 5),
      ],
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
        // owner (22 Nov): Next and Done fill the whole line – big, easy to hit
        child: SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Center(child: _PlatePreview()),
              ),
              Expanded(
                child: TextButton(
                  key: const Key('keyboardNext'),
                  style: TextButton.styleFrom(shape: const RoundedRectangleBorder()),
                  onPressed: () => focusNextNumberField(context),
                  child: const Text('Next', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
              Expanded(
                child: TextButton(
                  key: const Key('keyboardDone'),
                  style: TextButton.styleFrom(shape: const RoundedRectangleBorder()),
                  onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: const Text('Done', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
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

/// Left of Next / Done while typing a barbell weight: the plates for one side,
/// in their colours, smallest drawing that still reads ("20 · 5 · 1.25").
/// Tap = the full plate calculator.
class _PlatePreview extends StatelessWidget {
  const _PlatePreview();

  /// Bar + gym plates per exercise, read once (typing must not flicker); cleared
  /// after the calculator, where they can change.
  static final _cache = <String, Future<(double, List<double>)>>{};

  Future<(double, List<double>)> _setup(BuildContext context, String exerciseId) =>
      _cache.putIfAbsent('$exerciseId|${Units.lb}', () => _read(context, exerciseId));

  Future<(double, List<double>)> _read(BuildContext context, String exerciseId) async {
    final db = Services.of(context).db;
    final lb = Units.lb;
    final plates = await db.getSetting(lb ? 'platesLb' : 'plates');
    final bar = await db.getSetting('${lb ? 'barLb' : 'bar'}.$exerciseId') ?? await db.getSetting(lb ? 'barLb' : 'bar');
    final barW = double.tryParse(bar?.split('|').last ?? '') ?? (lb ? 45 : 20);
    final list = plates == null || plates.isEmpty
        ? (lb ? allPlatesLb : standardPlates)
        : ([for (final p in plates.split(',')) ?double.tryParse(p)]..sort((a, b) => b.compareTo(a)));
    return (barW, list);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<PlateTarget?>(
    valueListenable: platePreview,
    builder: (context, target, _) {
      if (target == null) return const SizedBox.shrink();
      return FutureBuilder<(double, List<double>)>(
        key: ValueKey(target.exerciseId), // keeps the last result while typing
        future: _setup(context, target.exerciseId),
        builder: (context, snap) {
          final setup = snap.data;
          if (setup == null) return const SizedBox.shrink();
          final lb = Units.lb;
          // A typo like 1000000 kg must not try to draw a million plates (it froze the app, 22 Nov).
          if (target.kg > maxPreviewKg) return const SizedBox.shrink();
          final result = platesPerSide(Units.toW(target.kg), bar: setup.$1, plates: setup.$2);
          if (result.perSide.isEmpty) return const SizedBox.shrink();
          final biggest = lb ? 45.0 : 25.0;
          return InkWell(
            key: const Key('platePreview'),
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              await showCalculators(context, weightKg: target.kg, exerciseId: target.exerciseId);
              _cache.clear();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12, height: 4, child: ColoredBox(color: Color(0xFFA9B1BA))),
                  for (final p in result.perSide)
                    Container(
                      width: 5,
                      height: 10 + 22 * (p / biggest).clamp(0.0, 1.0),
                      margin: const EdgeInsets.only(right: 1),
                      decoration: BoxDecoration(
                        color: plateColor(p, lb: lb),
                        border: Border.all(color: const Color(0xFF1D1D1D), width: 0.8),
                      ),
                    ),
                  const SizedBox(width: 3, height: 10, child: ColoredBox(color: Color(0xFF7D8791))),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      result.perSide.map(formatKg).join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF141B2B),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
