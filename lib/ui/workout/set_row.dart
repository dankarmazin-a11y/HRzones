part of 'active_workout_screen.dart';

/// One set: type label, previous values (tap to copy), inputs, RPE, done.
/// In a Stretching card: stretch name, optional assisting weight, seconds, ▶.
class SetRow extends StatefulWidget {
  const SetRow({super.key, required this.entry, required this.set, required this.index, this.partner});

  final LoggedExercise entry;
  final LoggedSet set;
  final int index;

  /// The right side of a one-sided set ([set] is the left): one row, the
  /// values apply to both sides, a tick for each.
  final LoggedSet? partner;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final _weight = TextEditingController(text: formatW(widget.set.weightKg));
  late final _reps = TextEditingController(text: widget.set.reps?.toString() ?? '');
  late final _secs = TextEditingController(text: widget.set.durationS?.toString() ?? '');
  late final _metres = TextEditingController(text: widget.set.distanceM == null ? '' : formatKg(widget.set.distanceM));

  /// The right side's own fields, shown full size while it is being edited
  /// (`_editRight` = which one was tapped: 'First' / 'Second').
  final _rFirst = TextEditingController();
  final _rSecond = TextEditingController();
  String? _editRight;

  @override
  void didUpdateWidget(SetRow old) {
    super.didUpdateWidget(old);
    _sync(_weight, formatW(widget.set.weightKg));
    _sync(_reps, widget.set.reps?.toString() ?? '');
    _sync(_secs, widget.set.durationS?.toString() ?? '');
  }

  /// Update a field from the model without fighting the user's typing.
  void _sync(TextEditingController c, String v) {
    if (c.text == v) return;
    final parsedSame = double.tryParse(c.text.replaceAll(',', '.')) == double.tryParse(v);
    if (!parsedSame) c.text = v;
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _secs.dispose();
    _metres.dispose();
    _rFirst.dispose();
    _rSecond.dispose();
    super.dispose();
  }

  String _label() {
    final s = widget.set;
    final side = widget.partner != null
        ? ''
        : switch (s.side) {
            Side.left => 'L',
            Side.right => 'R',
            null => '',
          };
    final sets = widget.entry.sets;
    if (s.subExercise != null) {
      // Stretch rows: a left + right pair shares one number.
      final n = sets.take(widget.index + 1).where((x) => x.side != Side.right).length;
      return '$n$side';
    }
    if (s.side != null && s.type == SetType.normal) {
      final n = sets.take(widget.index + 1).where((x) => x.type == SetType.normal && x.side != Side.right).length;
      return '$n$side';
    }
    switch (s.type) {
      case SetType.warmup:
        return 'W$side';
      case SetType.drop:
        return 'D$side';
      case SetType.failure:
        return 'F$side';
      case SetType.normal:
        final sets = widget.entry.sets;
        return '${sets.take(widget.index + 1).where((x) => x.type == SetType.normal).length}';
    }
  }

  Color? _labelColor(BuildContext context) => switch (widget.set.type) {
    SetType.warmup => Colors.amber,
    SetType.drop => Colors.purple,
    SetType.failure => Colors.red,
    SetType.normal => null,
  };

  String _previousText(WorkoutSet? p) {
    if (p == null) return '—';
    final w = p.weightKg;
    if (widget.entry.exercise.trackingType == TrackingType.duration) {
      return (w == null || w == 0) ? '${p.durationS ?? 0} s' : '+${formatW(w)} · ${p.durationS ?? 0}s';
    }
    if (widget.entry.exercise.trackingType == TrackingType.distance) {
      return '${formatKg(p.distanceM ?? 0)} m · ${formatDuration(Duration(seconds: p.durationS ?? 0))}';
    }
    final reps = p.reps ?? 0;
    return (w == null || w == 0) ? '$reps reps' : '${formatW(w)} × $reps';
  }

  void _fillFromPrevious(WorkoutSet? p) {
    if (p == null) return;
    final session = SessionScope.of(context);
    for (final x in _sides) {
      if (p.weightKg != null) session.setWeight(x, p.weightKg);
      if (p.reps != null) session.setReps(x, p.reps);
      if (p.durationS != null) session.setDuration(x, p.durationS);
      if (p.distanceM != null) session.setDistance(x, p.distanceM);
    }
    setState(() {
      _metres.text = widget.set.distanceM == null ? '' : formatKg(widget.set.distanceM);
      _weight.text = formatW(widget.set.weightKg);
      _reps.text = widget.set.reps?.toString() ?? '';
      _secs.text = widget.set.durationS?.toString() ?? '';
    });
  }

  /// The set and, for a one-sided set, its right side.
  List<LoggedSet> get _sides => [widget.set, ?widget.partner];

  /// ✓ L and ✓ R in one row (one-sided sets); a timed hold gets one ▶ that
  /// runs left, "switch sides", right.
  Widget _pairButtons(WorkoutSession session, TrackingType tracking) {
    final l = widget.set, r = widget.partner!;
    if (session.templateMode) return const SizedBox.shrink();
    if (tracking == TrackingType.duration && !session.editMode) {
      final t = session.timer;
      final running = t?.kind == TimerKind.setTimer && (t?.set == l || t?.set == r);
      if (l.done && r.done && !running) {
        return IconButton(
          tooltip: 'Undo',
          icon: const Icon(Icons.check_box, color: Colors.green),
          onPressed: () {
            session.toggleDone(widget.entry, r);
            session.toggleDone(widget.entry, l);
          },
        );
      }
      return IconButton(
        key: Key('pairTimer_${widget.index}'),
        tooltip: running ? 'Stop' : 'Start timer',
        icon: Icon(running ? Icons.stop_circle : Icons.play_circle, color: timedColor(context)),
        onPressed: () {
          FocusScope.of(context).unfocus();
          running ? session.stopTimer() : session.startSetTimer(widget.entry, l.done ? r : l);
        },
      );
    }
    Widget tick(LoggedSet x, String letter) => InkWell(
      key: Key('tick${letter}_${widget.index}'),
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        FocusScope.of(context).unfocus();
        session.toggleDone(widget.entry, x);
        if (!x.done) return;
        final record = await session.isRecord(widget.entry, x);
        record ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
      },
      child: SizedBox(
        width: 36,
        height: 44,
        child: Icon(
          x.done ? Icons.check_box : Icons.check_box_outline_blank,
          color: x.done ? Colors.green : null,
          semanticLabel: '$letter side',
        ),
      ),
    );
    return tick(l, 'L');
  }

  /// The right side, collapsed under the left: it copies the left values;
  /// tap a number to give the right side its own (usually it's the same).
  Widget _rightRow(WorkoutSession session, TrackingType tracking) {
    final l = widget.set, r = widget.partner!;
    final scheme = Theme.of(context).colorScheme;
    num? first(LoggedSet x) => tracking == TrackingType.distance ? x.distanceM : x.weightKg;
    num? second(LoggedSet x) =>
        tracking == TrackingType.duration || tracking == TrackingType.distance ? x.durationS : x.reps;
    // Weights show in kg or lb; metres stay plain numbers.
    String dbl(double v) => tracking == TrackingType.distance ? formatKg(v) : formatW(v);
    String show(num? v) => v == null ? '–' : (v is double ? dbl(v) : '$v');
    String text(num? v) => v == null ? '' : (v is double ? dbl(v) : '$v');
    final editing = _editRight != null;
    Widget cell(String key, num? mine, num? left, ValueChanged<String> onChanged, {bool decimal = false}) {
      if (editing) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: SetNumberField(
              key: Key('right${key}Field_${widget.index}'),
              controller: key == 'First' ? _rFirst : _rSecond,
              hint: text(left),
              decimal: decimal,
              autofocus: _editRight == key,
              onChanged: onChanged,
            ),
          ),
        );
      }
      final own = mine != left;
      return Expanded(
        child: InkWell(
          key: Key('right${key}_${widget.index}'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() {
            _rFirst.text = text(first(r));
            _rSecond.text = text(second(r));
            _editRight = key;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              show(mine),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: own ? FontWeight.w800 : FontWeight.w400,
                color: own ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    void setFirst(String v) {
      final n = double.tryParse(v.replaceAll(',', '.'));
      tracking == TrackingType.distance
          ? session.setDistance(r, n)
          : session.setWeightOnly(r, n == null ? null : Units.fromW(n));
    }

    void setSecond(String v) {
      final n = int.tryParse(v);
      tracking == TrackingType.duration || tracking == TrackingType.distance
          ? session.setDuration(r, n)
          : session.setReps(r, n);
    }

    // Only the right side failed: tap R to mark it F (and back). Warm-up and
    // drop set come from the main row and apply to both sides.
    final rightFailed = r.type == SetType.failure && l.type != SetType.failure;

    final showRpe = !widget.entry.exercise.isStretch && Services.of(context).level.value.showsAdvancedSetOptions;
    final timed = tracking == TrackingType.duration;
    final row = Row(
      key: Key('rightRow_${widget.index}'),
      children: [
        SizedBox(
          width: _setW,
          child: InkWell(
            key: Key('rightType_${widget.index}'),
            borderRadius: BorderRadius.circular(8),
            onTap: l.type == SetType.failure
                ? null
                : () => session.setSetType(r, rightFailed ? l.type : SetType.failure),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                rightFailed ? 'FR' : 'R',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: rightFailed ? FontWeight.bold : null,
                  color: rightFailed ? Colors.red : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: _prevW,
          child: Text(
            editing ? 'right side' : (rightFailed ? 'failure' : 'right side'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ),
        cell('First', first(r), first(l), setFirst, decimal: true),
        cell('Second', second(r), second(l), setSecond),
        if (showRpe) const SizedBox(width: _rpeW),
        SizedBox(
          width: _doneW,
          child: session.templateMode
              ? null
              : timed && !session.editMode
              ? Icon(
                  r.done ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 20,
                  color: r.done ? Colors.green : scheme.outline,
                )
              : InkWell(
                  key: Key('tickR_${widget.index}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    session.toggleDone(widget.entry, r);
                    if (!r.done) return;
                    final record = await session.isRecord(widget.entry, r);
                    record ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
                  },
                  child: SizedBox(
                    height: 36,
                    child: Icon(
                      r.done ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 22,
                      color: r.done ? Colors.green : null,
                      semanticLabel: 'R side',
                    ),
                  ),
                ),
        ),
      ],
    );
    if (!editing) return row;
    // Full-size fields while editing; back to the small line once the
    // keyboard leaves both of them.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (has) {
        if (!has && mounted) setState(() => _editRight = null);
      },
      child: Padding(padding: const EdgeInsets.only(top: 3), child: row),
    );
  }

  /// ✓ for weight/reps sets. Timed sets get ▶ (start countdown) / ■ (stop).
  Widget _doneButton(WorkoutSession session, LoggedSet s, TrackingType tracking) {
    if (session.templateMode) return const SizedBox.shrink(); // planning, not doing
    if (s.done) {
      return IconButton(
        tooltip: 'Undo',
        icon: const Icon(Icons.check_box, color: Colors.green),
        onPressed: () => session.toggleDone(widget.entry, s),
      );
    }
    if (tracking == TrackingType.distance && widget.entry.exercise.id == runExerciseId && !session.editMode) {
      final going = session.setRun?.set == s;
      return IconButton(
        key: Key('setRun_${widget.index}'),
        tooltip: going ? 'Stop' : 'Run it (GPS)',
        icon: Icon(going ? Icons.stop_circle : Icons.directions_run, color: timedColor(context)),
        onPressed: () async {
          FocusScope.of(context).unfocus();
          if (going) return session.stopSetRun();
          final messenger = ScaffoldMessenger.of(context);
          final access = await session.startSetRun(widget.entry, s);
          if (access != LocationAccess.granted) {
            messenger.showSnackBar(const SnackBar(content: Text('Location is needed to measure the run.')));
          }
        },
      );
    }
    if (tracking == TrackingType.duration && !session.editMode) {
      final running = session.timer?.kind == TimerKind.setTimer && session.timer?.set == s;
      return IconButton(
        tooltip: running ? 'Stop' : 'Start timer',
        icon: Icon(running ? Icons.stop_circle : Icons.play_circle, color: timedColor(context)),
        onPressed: () {
          FocusScope.of(context).unfocus();
          running ? session.stopTimer() : session.startSetTimer(widget.entry, s);
        },
      );
    }
    return IconButton(
      icon: const Icon(Icons.check_box_outline_blank),
      onPressed: () async {
        FocusScope.of(context).unfocus();
        session.toggleDone(widget.entry, s);
        // A tap you can feel; a stronger one for a new record.
        final record = await session.isRecord(widget.entry, s);
        record ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
      },
    );
  }

  /// Long-press on the set number: pick the type from a list (tapping still
  /// cycles number → F → W → D).
  Future<void> _pickSetType(WorkoutSession session) async {
    const names = {
      SetType.normal: ('Normal set', 'Counts for your records'),
      SetType.failure: ('F · Failure', 'Went until you couldn\'t do another rep'),
      SetType.warmup: ('W · Warm-up', 'Not counted in volume or records'),
      SetType.drop: ('D · Drop set', 'Lighter weight right after the previous set'),
    };
    final t = await showModalBottomSheet<SetType>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Set type')),
            for (final type in WorkoutSession.setTypeCycle)
              ListTile(
                key: Key('setType-${type.name}'),
                title: Text(names[type]!.$1),
                subtitle: Text(names[type]!.$2),
                trailing: widget.set.type == type ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(c, type),
              ),
          ],
        ),
      ),
    );
    if (t != null) {
      for (final x in _sides) {
        session.setSetType(x, t);
      }
    }
  }

  Future<void> _pickRpe() async {
    final session = SessionScope.of(context);
    const values = [6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];
    final v = await showModalBottomSheet<double>(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(title: Text('RPE (rate of perceived exertion)'), subtitle: Text('10 = nothing left')),
            for (final r in values) ListTile(title: Text(formatKg(r)), onTap: () => Navigator.pop(c, r)),
            ListTile(title: const Text('Clear'), onTap: () => Navigator.pop(c, -1)),
          ],
        ),
      ),
    );
    if (v == null) return;
    for (final x in _sides) {
      session.setRpe(x, v < 0 ? null : v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final s = widget.set;
    final prev = widget.entry.previousFor(widget.index);
    final tracking = widget.entry.exercise.trackingType;
    final scheme = Theme.of(context).colorScheme;
    final partner = widget.partner;
    final running =
        session.timer?.kind == TimerKind.setTimer &&
        (session.timer?.set == s || (partner != null && session.timer?.set == partner));
    // Typing a value on the left also sets the right side, unless the right
    // side was given its own number.
    void both(num? Function(LoggedSet x) value, void Function(LoggedSet x) f) {
      final old = value(s);
      f(s);
      final p = partner;
      if (p != null && (value(p) == null || value(p) == old)) f(p);
    }

    Widget field(TextEditingController c, String hint, ValueChanged<String> onChanged, {bool decimal = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: SetNumberField(controller: c, hint: hint, onChanged: onChanged, decimal: decimal),
        );

    String hintOf(num? v) => v == null ? '' : (v is double ? formatKg(v) : '$v');
    String weightHint(double? kg) => kg == null ? '' : formatW(kg);
    Widget weightField(String hint) => field(
      _weight,
      hint,
      (v) => both((x) => x.weightKg, (x) {
        final n = double.tryParse(v.replaceAll(',', '.'));
        session.setWeight(x, n == null ? null : Units.fromW(n)); // typed in kg or lb, stored in kg
      }),
      decimal: true,
    );
    Widget secondsCell() => running
        ? Center(
            child: ListenableBuilder(
              listenable: session.ticks,
              builder: (context, _) => Text(
                '${session.timer?.remaining ?? 0} s',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: timedColor(context)),
              ),
            ),
          )
        : field(
            _secs,
            hintOf(prev?.durationS ?? WorkoutSession.defaultSetSeconds),
            (v) => both((x) => x.durationS, (x) => session.setDuration(x, int.tryParse(v))),
          );

    final sub = s.subExercise;
    final children = sub != null
        ? <Widget>[
            SizedBox(
              width: _setW,
              child: Text(
                _label(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: sub))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      ExerciseAvatar(exercise: sub, radius: 12),
                      const SizedBox(width: 6),
                      Expanded(child: Text(sub.name, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: _kgW, child: weightField('')),
            SizedBox(width: _secW, child: secondsCell()),
            SizedBox(width: _doneW, child: _doneButton(session, s, TrackingType.duration)),
          ]
        : <Widget>[
            SizedBox(
              width: _setW,
              child: InkWell(
                // Set types (warm-up/drop/failure) are hidden for beginners.
                onTap: Services.of(context).level.value.showsAdvancedSetOptions
                    ? () {
                        session.cycleSetType(s);
                        if (partner != null) session.setSetType(partner, s.type);
                      }
                    : null,
                onLongPress: Services.of(context).level.value.showsAdvancedSetOptions
                    ? () => _pickSetType(session)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _label(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: _labelColor(context)),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _prevW,
              child: InkWell(
                onTap: () => _fillFromPrevious(prev),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _previousText(prev),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ),
            ),
            if (tracking == TrackingType.duration) ...[
              Expanded(child: weightField(weightHint(prev?.weightKg))),
              Expanded(child: secondsCell()),
            ] else if (tracking == TrackingType.distance && session.setRun?.set == s) ...[
              // Running it now: live metres and time.
              for (final metres in [true, false])
                Expanded(
                  child: Center(
                    child: ListenableBuilder(
                      listenable: session.ticks,
                      builder: (context, _) {
                        final r = session.setRun;
                        if (r == null) return const SizedBox.shrink();
                        return Text(
                          metres
                              ? '${r.metres.round()}${r.target == null ? '' : '/${formatKg(r.target)}'} m'
                              : formatDuration(r.elapsed),
                          key: metres ? const Key('setRunMetres') : null,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: timedColor(context)),
                        );
                      },
                    ),
                  ),
                ),
            ] else if (tracking == TrackingType.distance) ...[
              Expanded(
                child: field(
                  _metres,
                  hintOf(prev?.distanceM),
                  (v) =>
                      both((x) => x.distanceM, (x) => session.setDistance(x, double.tryParse(v.replaceAll(',', '.')))),
                  decimal: true,
                ),
              ),
              Expanded(
                child: field(
                  _secs,
                  hintOf(prev?.durationS),
                  (v) => both((x) => x.durationS, (x) => session.setDuration(x, int.tryParse(v))),
                ),
              ),
            ] else ...[
              Expanded(child: weightField(weightHint(prev?.weightKg))),
              Expanded(
                child: field(
                  _reps,
                  hintOf(prev?.reps),
                  (v) => both((x) => x.reps, (x) => session.setReps(x, int.tryParse(v))),
                ),
              ),
            ],
            if (!widget.entry.exercise.isStretch && Services.of(context).level.value.showsAdvancedSetOptions)
              SizedBox(
                width: _rpeW,
                child: InkWell(
                  onTap: _pickRpe,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      s.rpe == null ? '–' : formatKg(s.rpe),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            partner != null
                ? SizedBox(width: _doneW, child: _pairButtons(session, tracking))
                : SizedBox(width: _doneW, child: _doneButton(session, s, tracking)),
          ];

    final allDone = _sides.every((x) => x.done), someDone = _sides.any((x) => x.done);
    return Container(
      color: allDone
          ? Colors.green.withValues(alpha: 0.18)
          : (running ? Colors.teal.withValues(alpha: 0.18) : (someDone ? Colors.green.withValues(alpha: 0.08) : null)),
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: partner == null
          ? Row(children: children)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: children),
                _rightRow(session, tracking),
              ],
            ),
    );
  }
}
