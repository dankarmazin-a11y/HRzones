import 'package:flutter/material.dart';

import '../hr/hr_monitor.dart';
import '../hr/zone_alert_engine.dart';
import '../hr/zones.dart';
import 'number_input.dart';
import 'zone_colors.dart';

/// Live heart rate, target range, simulated source controls and test beeps.
class HrMonitorCard extends StatelessWidget {
  const HrMonitorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final m = HrScope.of(context);
    final text = Theme.of(context).textTheme;
    final color = zoneColor(m.zone?.number);
    final sim = m.simulated;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Heart rate', style: text.titleMedium),
                const Spacer(),
                Text('Source: ${m.source.displayName}', style: text.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                m.bpm?.toString() ?? '--',
                key: const Key('bpm'),
                style: text.displayLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(_statusLabel(m), style: text.titleSmall?.copyWith(color: color)),
            ),
            if (m.lastAlert != null && m.running) ...[
              const SizedBox(height: 8),
              _AlertBanner(alert: m.lastAlert!, at: m.lastAlertAt!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Target range: ', style: text.titleSmall),
                EditableNumber(
                  value: m.range.min,
                  title: 'Range minimum (bpm)',
                  min: 40,
                  max: m.range.max - 1,
                  style: text.titleSmall,
                  onChanged: (v) => m.setRange(HrRange(min: v.round(), max: m.range.max)),
                ),
                Text('–', style: text.titleSmall),
                EditableNumber(
                  value: m.range.max,
                  title: 'Range maximum (bpm)',
                  min: m.range.min + 1,
                  max: 240,
                  style: text.titleSmall,
                  onChanged: (v) => m.setRange(HrRange(min: m.range.min, max: v.round())),
                ),
                Text(' bpm', style: text.titleSmall),
              ],
            ),
            RangeSlider(
              min: 60,
              max: 220,
              divisions: 160,
              values: RangeValues(m.range.min.clamp(60, 219).toDouble(), m.range.max.clamp(61, 220).toDouble()),
              labels: RangeLabels('${m.range.min}', '${m.range.max}'),
              onChanged: (v) {
                if (v.end - v.start >= 1) m.setRange(HrRange(min: v.start.round(), max: v.end.round()));
              },
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final z in m.zones.zones)
                  ActionChip(
                    label: Text('Z${z.number}'),
                    avatar: CircleAvatar(backgroundColor: zoneColor(z.number)),
                    onPressed: () => m.setRange(m.zones.rangeForZone(z.number)),
                  ),
              ],
            ),
            if (sim != null) ...[
              const Divider(height: 32),
              Row(
                children: [
                  Text('Simulated HR: ', style: text.titleSmall),
                  EditableNumber(
                    value: sim.bpm,
                    title: 'Simulated heart rate (bpm)',
                    min: 30,
                    max: 240,
                    style: text.titleSmall,
                    onChanged: (v) => m.setSimulatedBpm(v.round()),
                  ),
                  Text(' bpm', style: text.titleSmall),
                ],
              ),
              Slider(
                key: const Key('simSlider'),
                min: 40,
                max: 210,
                divisions: 170,
                value: sim.bpm.clamp(40, 210).toDouble(),
                label: '${sim.bpm}',
                onChanged: (v) => m.setSimulatedBpm(v.round()),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Simulate signal loss'),
                value: sim.signalLost,
                onChanged: m.setSignalLost,
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('startStop'),
              icon: Icon(m.running ? Icons.stop : Icons.play_arrow),
              label: Text(m.running ? 'Stop monitoring' : 'Start monitoring'),
              onPressed: m.running ? m.stop : m.start,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => m.testBeep(ZoneAlert.high),
                    child: const Text('Test HIGH beep'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(onPressed: () => m.testBeep(ZoneAlert.low), child: const Text('Test LOW beep')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(HrMonitor m) {
    if (!m.running) return 'Not monitoring';
    final zone = m.zone == null ? '' : ' · Zone ${m.zone!.number}';
    return switch (m.status) {
      RangeStatus.noSignal => 'No signal – alerts paused',
      RangeStatus.inRange => 'In range$zone',
      RangeStatus.above => 'Above range$zone',
      RangeStatus.below => 'Below range$zone',
    };
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert, required this.at});

  final ZoneAlert alert;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final high = alert == ZoneAlert.high;
    final t =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}:'
        '${at.second.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (high ? Colors.red : Colors.blue).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(high ? 'Last alert $t: HIGH (3 beeps)' : 'Last alert $t: LOW (2 beeps)', textAlign: TextAlign.center),
    );
  }
}
