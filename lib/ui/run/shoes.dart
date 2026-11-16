import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../data/database.dart' show GearKind;
import '../../data/shoe_repository.dart';
import '../number_input.dart';
import '../theme/emblems.dart';
import '../../units/units.dart';

/// Shoe km (stored in km) in the chosen unit: "412" / "256.0".
String _km(double km) {
  final v = Units.toD(km * 1000);
  return v.toStringAsFixed(v >= 100 ? 0 : 1);
}

double _shown(double km) => double.parse(Units.toD(km * 1000).toStringAsFixed(1));
double _stored(num v) => Units.fromD(v.toDouble()) / 1000;

String _gearTitle(GearKind kind) => kind == GearKind.bike ? 'Bikes' : 'Shoes';

/// Run tab: your shoes (or bikes) with their km; tap for the shoes screen.
class ShoesCard extends StatelessWidget {
  const ShoesCard({super.key, this.kind = GearKind.shoe, this.hideWhenEmpty = false});

  final GearKind kind;

  /// Run tab: no bikes card until there's a bike.
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<ShoeKm>>(
      stream: s.shoes.watchAll(kind: kind),
      builder: (context, snap) {
        final active = (snap.data ?? const <ShoeKm>[]).where((x) => !x.shoe.retired).toList();
        if (hideWhenEmpty && active.isEmpty) return const SizedBox.shrink();
        final bike = kind == GearKind.bike;
        return Card(
          key: Key(bike ? 'bikesCard' : 'shoesCard'),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShoesScreen(kind: kind))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(_gearTitle(kind), style: text.titleMedium)),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  if (active.isEmpty)
                    Text(
                      bike
                          ? 'Add your bike to count its ${Units.mi ? 'miles' : 'km'} and get a service reminder.'
                          : 'Add your running shoes to count their ${Units.mi ? 'miles' : 'km'}.',
                      style: text.bodySmall,
                    )
                  else
                    for (final x in active.take(3)) ShoeBar(shoe: x),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Name, km and a bar towards the replacement km (orange when worn out).
class ShoeBar extends StatelessWidget {
  const ShoeBar({super.key, required this.shoe});

  final ShoeKm shoe;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final worn = shoe.wornOut;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (shoe.shoe.isDefault) const Icon(Icons.star, size: 16),
              Expanded(child: Text(shoe.shoe.name, style: text.bodyLarge)),
              Text(
                shoe.isBike ? '${_km(shoe.km)} ${Units.d}' : '${_km(shoe.km)} / ${_km(shoe.shoe.limitKm)} ${Units.d}',
                style: text.bodyMedium?.copyWith(color: worn ? Colors.orange.shade800 : null),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: shoe.used,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            color: worn ? Colors.orange : scheme.primary,
          ),
          if (shoe.isBike)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                worn
                    ? 'Service due – ${_km(shoe.counted)} ${Units.d} since the last one'
                    : '${_km(shoe.shoe.limitKm - shoe.counted)} ${Units.d} to the next service',
                key: Key('service_${shoe.shoe.id}'),
                style: text.bodySmall?.copyWith(color: worn ? Colors.orange.shade800 : null),
              ),
            )
          else if (worn)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Time for new shoes?', style: text.bodySmall?.copyWith(color: Colors.orange.shade800)),
            ),
        ],
      ),
    );
  }
}

/// All shoes (or bikes): add, edit, choose the default, retire, delete.
class ShoesScreen extends StatelessWidget {
  const ShoesScreen({super.key, this.kind = GearKind.shoe});

  final GearKind kind;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final bike = kind == GearKind.bike;
    return Scaffold(
      appBar: AppBar(title: Text(_gearTitle(kind))),
      floatingActionButton: FloatingActionButton.extended(
        key: Key(bike ? 'addBike' : 'addShoe'),
        icon: const Icon(Icons.add),
        label: Text(bike ? 'Add bike' : 'Add shoes'),
        onPressed: () => editShoe(context, null, kind),
      ),
      body: StreamBuilder<List<ShoeKm>>(
        stream: s.shoes.watchAll(kind: kind),
        builder: (context, snap) {
          final list = snap.data ?? const <ShoeKm>[];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  bike
                      ? 'Add the bike you ride. Every ride adds its distance, and you get a reminder when it is '
                            'time for a service (every ${Units.mi ? '1,900 miles' : '3,000 km'} unless you change it).'
                      : 'Add the shoes you run in. Every run adds its distance, and you get a reminder when they '
                            'reach their replacement distance (about ${Units.mi ? '430 miles' : '700 km'} for most '
                            'running shoes).',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            // Keep cards that load data built off-screen (no jumping while scrolling).
            scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              for (final x in list)
                Card(
                  child: ListTile(
                    key: Key('shoe_${x.shoe.id}'),
                    title: Opacity(
                      opacity: x.shoe.retired ? 0.5 : 1,
                      child: ShoeBar(shoe: x),
                    ),
                    subtitle: x.shoe.retired
                        ? const Text('Retired')
                        : (x.shoe.isDefault ? Text(bike ? 'Used for new rides' : 'Used for new runs') : null),
                    onTap: () => editShoe(context, x, kind),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        switch (v) {
                          case 'serviced':
                            await s.shoes.markServiced(x.shoe.id);
                          case 'default':
                            await s.shoes.setDefault(x.shoe.id);
                          case 'retire':
                            await s.shoes.setRetired(x.shoe.id, !x.shoe.retired);
                          case 'delete':
                            await s.shoes.delete(x.shoe.id);
                        }
                      },
                      itemBuilder: (_) => [
                        if (bike && !x.shoe.retired)
                          const PopupMenuItem(value: 'serviced', child: Text('Serviced today')),
                        if (!x.shoe.isDefault && !x.shoe.retired)
                          PopupMenuItem(value: 'default', child: Text(bike ? 'Use for new rides' : 'Use for new runs')),
                        PopupMenuItem(value: 'retire', child: Text(x.shoe.retired ? 'Back in use' : 'Retire')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Add or edit a pair (or a bike): name, km they already have, replacement
/// (or service) km.
Future<void> editShoe(BuildContext context, [ShoeKm? existing, GearKind kind = GearKind.shoe]) async {
  final s = Services.of(context);
  final k = existing?.shoe.kind ?? kind;
  final result = await showDialog<(String, double, double)>(
    context: context,
    builder: (_) => _ShoeDialog(existing: existing, kind: k),
  );
  if (result == null) return;
  final (name, startKm, limitKm) = result;
  await s.shoes.save(id: existing?.shoe.id, name: name, startKm: startKm, limitKm: limitKm, kind: k);
}

class _ShoeDialog extends StatefulWidget {
  const _ShoeDialog({this.existing, required this.kind});

  final ShoeKm? existing;
  final GearKind kind;

  @override
  State<_ShoeDialog> createState() => _ShoeDialogState();
}

class _ShoeDialogState extends State<_ShoeDialog> {
  late final _name = TextEditingController(text: widget.existing?.shoe.name ?? '');
  late double _start = widget.existing?.shoe.startKm ?? 0;
  late double _limit = widget.existing?.shoe.limitKm ?? (_bike ? defaultServiceKm : 700);
  bool get _bike => widget.kind == GearKind.bike;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _bike
            ? (widget.existing == null ? 'Add bike' : 'Edit bike')
            : (widget.existing == null ? 'Add shoes' : 'Edit shoes'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('shoeName'),
              controller: _name,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: _bike ? 'e.g. Road bike' : 'e.g. Nike Pegasus 41',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('${Units.mi ? 'Miles' : 'Km'} already on ${_bike ? 'it' : 'them'}')),
                EditableNumber(
                  key: const Key('shoeStartKm'),
                  value: _shown(_start),
                  title: '${Units.mi ? 'Miles' : 'Km'} already on ${_bike ? 'it' : 'them'}',
                  decimal: true,
                  max: _bike ? 200000 : 5000,
                  suffix: Units.d,
                  display: '${_km(_start)} ${Units.d}',
                  onChanged: (v) => setState(() => _start = _stored(v)),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text(_bike ? 'Service every' : 'Replace at')),
                EditableNumber(
                  key: const Key('shoeLimitKm'),
                  value: _shown(_limit),
                  title: '${_bike ? 'Service every' : 'Replace at'} (${Units.d})',
                  min: 30,
                  max: _bike ? 20000 : 5000,
                  suffix: Units.d,
                  display: '${_km(_limit)} ${Units.d}',
                  onChanged: (v) => setState(() => _limit = _stored(v)),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          key: const Key('saveShoe'),
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, (name, _start, _limit));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Run summary: which shoes (or bike for a ride; tap to change) and a
/// reminder when worn out / due for a service.
class RunShoeRow extends StatelessWidget {
  const RunShoeRow({super.key, required this.runId, required this.shoeId, this.kind = GearKind.shoe});

  final String runId;
  final String? shoeId;
  final GearKind kind;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return StreamBuilder<List<ShoeKm>>(
      stream: s.shoes.watchAll(kind: kind),
      builder: (context, snap) {
        final all = snap.data ?? const <ShoeKm>[];
        final shoe = all.where((x) => x.shoe.id == shoeId).firstOrNull;
        if (all.isEmpty) return const SizedBox.shrink();
        final bike = kind == GearKind.bike;
        return ListTile(
          key: Key(bike ? 'runBike' : 'runShoe'),
          contentPadding: EdgeInsets.zero,
          leading: Emblem(bike ? EmblemKind.bike : EmblemKind.shoe),
          title: Text(shoe == null ? (bike ? 'Which bike?' : 'Which shoes?') : shoe.shoe.name),
          subtitle: shoe == null
              ? null
              : Text(
                  bike
                      ? (shoe.wornOut
                            ? '${_km(shoe.km)} ${Units.d} – service due'
                            : '${_km(shoe.km)} ${Units.d} · service in ${_km(shoe.shoe.limitKm - shoe.counted)} ${Units.d}')
                      : shoe.wornOut
                      ? '${_km(shoe.km)} ${Units.d} – time for new shoes?'
                      : '${_km(shoe.km)} of ${_km(shoe.shoe.limitKm)} ${Units.d}',
                  style: shoe.wornOut ? TextStyle(color: Colors.orange.shade800) : null,
                ),
          trailing: const Icon(Icons.edit_outlined, size: 18),
          onTap: () async {
            final picked = await pickShoe(context, current: shoeId, kind: kind);
            if (picked != null) await s.shoes.setRunShoe(runId, picked.isEmpty ? null : picked);
          },
        );
      },
    );
  }
}

/// Choose shoes or a bike ('' = none). Null when cancelled.
Future<String?> pickShoe(BuildContext context, {String? current, GearKind kind = GearKind.shoe}) async {
  final s = Services.of(context);
  final bike = kind == GearKind.bike;
  final list = (await s.shoes.all(kind: kind)).where((x) => !x.shoe.retired || x.shoe.id == current).toList();
  if (!context.mounted) return null;
  return showModalBottomSheet<String>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(_gearTitle(kind))),
          ListTile(
            title: const Text('None'),
            trailing: current == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(c, ''),
          ),
          for (final x in list)
            ListTile(
              title: Text(x.shoe.name),
              subtitle: Text('${_km(x.km)} ${Units.d}'),
              trailing: current == x.shoe.id ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(c, x.shoe.id),
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(bike ? 'Add bike' : 'Add shoes'),
            onTap: () async {
              Navigator.pop(c);
              await editShoe(context, null, kind);
            },
          ),
        ],
      ),
    ),
  );
}
