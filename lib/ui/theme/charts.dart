import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The one chart look (docs/DESIGN.md "soft"): thin horizontal grid lines in
/// the track colour, curved lines in the bright colour with a fading area
/// under them, small dots, muted axis labels.
class SoftChart {
  SoftChart._();

  static FlGridData grid(BuildContext context, {double? interval}) {
    final t = AppTheme.of(context);
    return FlGridData(
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) => FlLine(color: t.track, strokeWidth: 1),
    );
  }

  static TextStyle axis(BuildContext context) => TextStyle(fontSize: 10, color: AppTheme.of(context).muted);

  static LineChartBarData line(BuildContext context, List<FlSpot> spots, {Color? color, bool area = true}) {
    final c = color ?? AppTheme.of(context).bright;
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      preventCurveOverShooting: true,
      color: c,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: spots.length <= 30,
        getDotPainter: (_, _, _, _) =>
            FlDotCirclePainter(radius: 2.6, color: c, strokeWidth: 1.5, strokeColor: Theme.of(context).cardColor),
      ),
      belowBarData: BarAreaData(
        show: area,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.withValues(alpha: 0.22), c.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  static LineTouchData touch(BuildContext context, String Function(LineBarSpot s) label) {
    final t = AppTheme.of(context);
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => t.ink,
        getTooltipItems: (spots) => [
          for (final s in spots) LineTooltipItem(label(s), const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}
