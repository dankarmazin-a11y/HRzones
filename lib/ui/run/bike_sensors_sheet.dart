import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../bike/bike_sensors.dart';
import '../../hr/ble_hr_source.dart' show bluetoothSupported;
import '../number_input.dart';

/// Ready sheet (rides) and Settings › Running: the bike's Bluetooth sensors.
class BikeSensorsRow extends StatefulWidget {
  const BikeSensorsRow({super.key});

  @override
  State<BikeSensorsRow> createState() => _BikeSensorsRowState();
}

class _BikeSensorsRowState extends State<BikeSensorsRow> {
  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final list = s.bike.sensors;
    return ListTile(
      key: const Key('bikeSensorsRow'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.sensors),
      title: const Text('Bike sensors'),
      subtitle: Text(list.isEmpty ? 'None – tap to add speed, cadence or power' : list.map((x) => x.name).join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const BikeSensorsSheet(),
        );
        if (mounted) setState(() {});
      },
    );
  }
}

String sensorTypeText(BikeSensorType t) => switch (t) {
  BikeSensorType.speedCadence => 'Speed / cadence',
  BikeSensorType.power => 'Power meter',
};

/// Saved sensors (remove with ✕), the wheel size, and a search for new ones.
class BikeSensorsSheet extends StatefulWidget {
  const BikeSensorsSheet({super.key});

  @override
  State<BikeSensorsSheet> createState() => _BikeSensorsSheetState();
}

class _BikeSensorsSheetState extends State<BikeSensorsSheet> {
  StreamSubscription<List<BikeSensor>>? _scan;
  List<BikeSensor> _found = const [];
  bool _scanning = false;
  String? _error;

  @override
  void dispose() {
    _scan?.cancel();
    super.dispose();
  }

  void _search() {
    _scan?.cancel();
    setState(() {
      _scanning = true;
      _error = null;
    });
    _scan = scanBikeSensors().listen(
      (list) => setState(() => _found = list),
      onError: (Object e) => setState(() {
        _scanning = false;
        _error = 'Could not search – is Bluetooth on and allowed for HR Zones?';
      }),
    );
    // stop after 20 s (battery)
    Future<void>.delayed(const Duration(seconds: 20), () {
      _scan?.cancel();
      if (mounted) setState(() => _scanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    final text = Theme.of(context).textTheme;
    final saved = s.bike.sensors;
    final fresh = _found.where((f) => !saved.any((x) => x.id == f.id)).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bike sensors', style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Speed and cadence sensors, power meters and smart trainers that use standard Bluetooth. '
                'They connect when a ride starts.',
                style: text.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final x in saved)
                ListTile(
                  key: Key('sensor_${x.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(x.type == BikeSensorType.power ? Icons.bolt : Icons.speed),
                  title: Text(x.name),
                  subtitle: Text(sensorTypeText(x.type)),
                  trailing: IconButton(
                    key: Key('removeSensor_${x.id}'),
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      await s.setBikeSensors([...saved.where((y) => y.id != x.id)]);
                      setState(() {});
                    },
                  ),
                ),
              ListTile(
                key: const Key('wheelSize'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.trip_origin),
                title: const Text('Wheel size'),
                subtitle: Text('${s.bike.wheelMm} mm around (700 × 25c = 2105, 700 × 28c = 2136, 29″ MTB ≈ 2300)'),
                onTap: () async {
                  final v = await promptNumber(
                    context,
                    title: 'Wheel size (mm around)',
                    initial: s.bike.wheelMm,
                    min: 1000,
                    max: 3000,
                    suffix: 'mm',
                  );
                  if (v == null) return;
                  await s.setWheelMm(v.round());
                  setState(() {});
                },
              ),
              const Divider(),
              if (!bluetoothSupported)
                Text(
                  'Bluetooth sensors work in the phone app.',
                  key: const Key('sensorsNoBluetooth'),
                  style: text.bodyMedium,
                )
              else ...[
                Row(
                  children: [
                    Expanded(child: Text('Nearby sensors', style: text.titleSmall)),
                    if (_scanning)
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      TextButton.icon(
                        key: const Key('scanSensors'),
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                        onPressed: _search,
                      ),
                  ],
                ),
                if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                if (_scanning && fresh.isEmpty)
                  Text('Spin the wheel or the pedals to wake the sensor up…', style: text.bodySmall),
                for (final f in fresh)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(f.type == BikeSensorType.power ? Icons.bolt : Icons.speed),
                    title: Text(f.name),
                    subtitle: Text(sensorTypeText(f.type)),
                    trailing: const Icon(Icons.add),
                    onTap: () async {
                      await s.setBikeSensors([...saved, f]);
                      setState(() {});
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
