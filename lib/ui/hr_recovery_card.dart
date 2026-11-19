import 'package:flutter/material.dart';

import '../app_services.dart';
import '../hr/hr_monitor.dart';
import 'theme/app_theme.dart';
import 'theme/emblems.dart';

/// Heart-rate recovery after a workout or run (owner, 19 Nov): measuring
/// live for a minute right after finishing, then the drop with its word and
/// your recent average. Hidden when there's nothing to show.
class HrRecoveryCard extends StatelessWidget {
  const HrRecoveryCard({super.key, required this.ownerId, required this.stored});

  /// The workout or run.
  final String ownerId;

  /// The saved drop (past workouts), loaded by the caller.
  final Future<int?> stored;

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return ValueListenableBuilder<HrRecovery?>(
      valueListenable: s.hr.recovery,
      builder: (context, live, _) {
        if (live != null && live.ownerId == ownerId) {
          if (!live.done) return _Card(measuring: live);
          if (live.drop != null) return _Card(drop: live.drop);
        }
        return FutureBuilder<int?>(
          future: stored,
          builder: (context, snap) => snap.data == null ? const SizedBox.shrink() : _Card(drop: snap.data),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({this.measuring, this.drop});

  final HrRecovery? measuring;
  final int? drop;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = AppTheme.of(context);
    final m = measuring;
    return Card(
      key: const Key('hrRecoveryCard'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Emblem(EmblemKind.heart),
            const SizedBox(width: 12),
            Expanded(
              child: m != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Heart-rate recovery', style: text.titleSmall),
                        Text(
                          'Stay still for a minute · ${m.secondsLeft} s',
                          key: const Key('hrRecoveryMeasuring'),
                          style: text.bodySmall?.copyWith(color: t.muted),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: 1 - m.secondsLeft / 60, color: AppColors.heart),
                      ],
                    )
                  : FutureBuilder<double?>(
                      future: Services.of(context).workouts.hrRecoveryAverage(),
                      builder: (context, avg) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Heart-rate recovery', style: text.titleSmall),
                          Text(
                            '−$drop beats in 1 minute · ${hrRecoveryWord(drop!)}',
                            key: const Key('hrRecoveryResult'),
                            style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (avg.data != null)
                            Text(
                              'Your recent average: −${avg.data!.round()}. A bigger drop = fitter.',
                              style: text.bodySmall?.copyWith(color: t.muted),
                            ),
                        ],
                      ),
                    ),
            ),
            if (m != null)
              Text(
                '${m.startBpm} → ${m.bpm ?? '–'}',
                style: text.titleMedium?.copyWith(color: AppColors.heart, fontWeight: FontWeight.w800),
              ),
          ],
        ),
      ),
    );
  }
}
