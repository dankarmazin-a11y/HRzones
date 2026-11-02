import 'dart:async';

import 'package:flutter/material.dart';

import '../hr/ble_hr_source.dart';
import '../hr/heart_rate_source.dart';
import '../hr/hr_monitor.dart';
import '../hr/simulated_hr_source.dart';

/// Profile section: which heart-rate source the app listens to.
class HrSourceSection extends StatelessWidget {
  const HrSourceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final m = HrScope.of(context);
    final text = Theme.of(context).textTheme;
    final isBle = m.source.kind == HrSourceKind.bluetooth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Heart-rate source', style: text.titleMedium),
        const SizedBox(height: 4),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(isBle ? Icons.bluetooth_connected : Icons.tune),
          title: Text(m.source.displayName),
          subtitle: Text(isBle ? (m.sourceStatus ?? '') : 'Slider on the Home screen (for testing)'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (bluetoothSupported)
              FilledButton.tonalIcon(
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(isBle ? 'Change strap' : 'Connect a strap'),
                onPressed: () async {
                  final device = await showModalBottomSheet<HrDevice>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const _ScanSheet(),
                  );
                  if (device != null) await m.setSource(BleHrSource(deviceId: device.id, deviceName: device.name));
                },
              ),
            if (isBle)
              OutlinedButton(onPressed: () => m.setSource(SimulatedHrSource()), child: const Text('Use simulated')),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          bluetoothSupported
              ? 'Works with chest straps and arm bands (Polar, Garmin, Wahoo, Coros…) and watches in '
                    '"broadcast heart rate" mode. Start monitoring with the ♥ button in a workout.'
              : 'Bluetooth straps work in the iPhone app (not in the web preview).',
          style: text.bodySmall,
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.headphones),
          title: const Text('AirPods / Apple Watch (Apple Health)'),
          subtitle: const Text('Needs the paid Apple Developer account – planned for the beta'),
          enabled: false,
        ),
      ],
    );
  }
}

class _ScanSheet extends StatefulWidget {
  const _ScanSheet();

  @override
  State<_ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<_ScanSheet> {
  StreamSubscription<List<HrDevice>>? _sub;
  List<HrDevice> _devices = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = scanHrDevices().listen(
      (d) => setState(() => _devices = d),
      onError: (Object e) => setState(() => _error = '$e'),
    );
  }

  @override
  void dispose() {
    _sub?.cancel(); // stops scanning
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              title: Text('Looking for heart-rate sensors…'),
              subtitle: Text('Put the strap on (it wakes up with skin contact) and keep the phone close.'),
              trailing: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Bluetooth problem: $_error\nCheck that Bluetooth is on and allowed for HR Zones.'),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final d in _devices)
                    ListTile(
                      leading: const Icon(Icons.monitor_heart_outlined),
                      title: Text(d.name),
                      subtitle: Text(d.rssi == null ? '' : 'Signal ${d.rssi} dBm'),
                      onTap: () => Navigator.pop(context, d),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
