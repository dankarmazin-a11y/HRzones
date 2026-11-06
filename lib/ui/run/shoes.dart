import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../app_services.dart';
import '../../data/shoe_repository.dart';
import '../number_input.dart';

String _km(double km) => km.toStringAsFixed(km >= 100 ? 0 : 1);

/// Run tab: your shoes with their km; tap for the shoes screen.
class ShoesCard extends StatelessWidget {
  const ShoesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<ShoeKm>>(
      stream: s.shoes.watchAll(),
      builder: (context, snap) {
        final active = (snap.data ?? const <ShoeKm>[]).where((x) => !x.shoe.retired).toList();
        return Card(
          key: const Key('shoesCard'),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShoesScreen())),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Shoes', style: text.titleMedium)),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  if (active.isEmpty)
                    Text('Add your running shoes to count their km.', style: text.bodySmall)
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
                '${_km(shoe.km)} / ${_km(shoe.shoe.limitKm)} km',
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
          if (worn)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Time for new shoes?', style: text.bodySmall?.copyWith(color: Colors.orange.shade800)),
            ),
        ],
      ),
    );
  }
}

/// All shoes: add, edit, choose the default, retire, delete.
class ShoesScreen extends StatelessWidget {
  const ShoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Shoes')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addShoe'),
        icon: const Icon(Icons.add),
        label: const Text('Add shoes'),
        onPressed: () => editShoe(context),
      ),
      body: StreamBuilder<List<ShoeKm>>(
        stream: s.shoes.watchAll(),
        builder: (context, snap) {
          final list = snap.data ?? const <ShoeKm>[];
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add the shoes you run in. Every run adds its km, and you get a reminder when they reach '
                  'their replacement km (about 700 km for most running shoes).',
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
                        : (x.shoe.isDefault ? const Text('Used for new runs') : null),
                    onTap: () => editShoe(context, x),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        switch (v) {
                          case 'default':
                            await s.shoes.setDefault(x.shoe.id);
                          case 'retire':
                            await s.shoes.setRetired(x.shoe.id, !x.shoe.retired);
                          case 'delete':
                            await s.shoes.delete(x.shoe.id);
                        }
                      },
                      itemBuilder: (_) => [
                        if (!x.shoe.isDefault && !x.shoe.retired)
                          const PopupMenuItem(value: 'default', child: Text('Use for new runs')),
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

/// Add or edit a pair: name, km they already have, replacement km.
Future<void> editShoe(BuildContext context, [ShoeKm? existing]) async {
  final s = Services.of(context);
  final result = await showDialog<(String, double, double)>(
    context: context,
    builder: (_) => _ShoeDialog(existing: existing),
  );
  if (result == null) return;
  final (name, startKm, limitKm) = result;
  await s.shoes.save(id: existing?.shoe.id, name: name, startKm: startKm, limitKm: limitKm);
}

class _ShoeDialog extends StatefulWidget {
  const _ShoeDialog({this.existing});

  final ShoeKm? existing;

  @override
  State<_ShoeDialog> createState() => _ShoeDialogState();
}

class _ShoeDialogState extends State<_ShoeDialog> {
  late final _name = TextEditingController(text: widget.existing?.shoe.name ?? '');
  late double _start = widget.existing?.shoe.startKm ?? 0;
  late double _limit = widget.existing?.shoe.limitKm ?? 700;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add shoes' : 'Edit shoes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('shoeName'),
            controller: _name,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Nike Pegasus 41'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text('Km already on them')),
              EditableNumber(
                key: const Key('shoeStartKm'),
                value: _start,
                title: 'Km already on them',
                decimal: true,
                max: 5000,
                suffix: 'km',
                display: '${_km(_start)} km',
                onChanged: (v) => setState(() => _start = v.toDouble()),
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(child: Text('Replace at')),
              EditableNumber(
                key: const Key('shoeLimitKm'),
                value: _limit,
                title: 'Replace at (km)',
                min: 50,
                max: 5000,
                suffix: 'km',
                display: '${_km(_limit)} km',
                onChanged: (v) => setState(() => _limit = v.toDouble()),
              ),
            ],
          ),
        ],
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

/// Run summary: which shoes (tap to change) and a reminder when worn out.
class RunShoeRow extends StatelessWidget {
  const RunShoeRow({super.key, required this.runId, required this.shoeId});

  final String runId;
  final String? shoeId;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return StreamBuilder<List<ShoeKm>>(
      stream: s.shoes.watchAll(),
      builder: (context, snap) {
        final all = snap.data ?? const <ShoeKm>[];
        final shoe = all.where((x) => x.shoe.id == shoeId).firstOrNull;
        if (all.isEmpty) return const SizedBox.shrink();
        return ListTile(
          key: const Key('runShoe'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.directions_walk),
          title: Text(shoe == null ? 'Which shoes?' : shoe.shoe.name),
          subtitle: shoe == null
              ? null
              : Text(
                  shoe.wornOut
                      ? '${_km(shoe.km)} km – time for new shoes?'
                      : '${_km(shoe.km)} of ${_km(shoe.shoe.limitKm)} km',
                  style: shoe.wornOut ? TextStyle(color: Colors.orange.shade800) : null,
                ),
          trailing: const Icon(Icons.edit_outlined, size: 18),
          onTap: () async {
            final picked = await pickShoe(context, current: shoeId);
            if (picked != null) await s.shoes.setRunShoe(runId, picked.isEmpty ? null : picked);
          },
        );
      },
    );
  }
}

/// Choose shoes ('' = none). Null when cancelled.
Future<String?> pickShoe(BuildContext context, {String? current}) async {
  final s = Services.of(context);
  final list = (await s.shoes.all()).where((x) => !x.shoe.retired || x.shoe.id == current).toList();
  if (!context.mounted) return null;
  return showModalBottomSheet<String>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Shoes')),
          ListTile(
            title: const Text('None'),
            trailing: current == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(c, ''),
          ),
          for (final x in list)
            ListTile(
              title: Text(x.shoe.name),
              subtitle: Text('${_km(x.km)} km'),
              trailing: current == x.shoe.id ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(c, x.shoe.id),
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add shoes'),
            onTap: () async {
              Navigator.pop(c);
              await editShoe(context);
            },
          ),
        ],
      ),
    ),
  );
}
