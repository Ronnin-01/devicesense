import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One trend chart, reused for both Battery Level and Temperature so the
/// rendering logic exists in exactly one place (DRY) — only the data
/// key, color, unit, and axis bounds differ per metric.
class TrendChartCard extends StatelessWidget {
  const TrendChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.unit,
    required this.samples,
    required this.valueKey,
    required this.minY,
    required this.maxY,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String unit;
  final List<Map<String, dynamic>> samples;
  final String valueKey;
  final double? minY;
  final double? maxY;

  int _timestampOf(Map<String, dynamic> sample) {
    return int.tryParse(sample['timestamp']?.toString() ?? '') ?? 0;
  }

  List<FlSpot> _buildSpots(int firstTimestamp) {
    return samples
        .map((sample) {
          final value = double.tryParse(sample[valueKey]?.toString() ?? '');
          if (value == null) return null;

          final timestamp = _timestampOf(sample);
          final hoursSinceStart =
              (timestamp - firstTimestamp) / (1000 * 60 * 60);
          return FlSpot(hoursSinceStart, value);
        })
        .whereType<FlSpot>()
        .toList();
  }

  /// Picks a "nice" tick spacing (in hours) so labels land on round
  /// values (1h, 6h, 1 day, ...) instead of an arbitrary fraction — and
  /// keeps the axis to roughly 5-6 labels no matter how wide the window is.
  double _tickInterval(double spanHours) {
    const candidates = <double>[
      0.5,
      1,
      2,
      3,
      4,
      6,
      8,
      12,
      24,
      48,
      72,
      168,
      336,
      720,
    ];
    for (final candidate in candidates) {
      if (spanHours / candidate <= 6) return candidate;
    }
    return candidates.last;
  }

  /// Same-day windows show a clock time ("14:30"); wider windows show a
  /// date ("Jul 25") — the exact minute stops being the useful signal
  /// once the chart spans multiple days.
  String _axisLabel(DateTime time, double spanHours) {
    return spanHours <= 30
        ? DateFormat('HH:mm').format(time)
        : DateFormat('MMM d').format(time);
  }

  String _latestLabel(DateTime time) {
    final now = DateTime.now();
    final isToday =
        time.year == now.year && time.month == now.month && time.day == now.day;
    final clock = DateFormat('HH:mm').format(time);
    return isToday
        ? 'Today, $clock'
        : '${DateFormat('MMM d').format(time)}, $clock';
  }

  String _windowLabel(double spanHours) {
    if (spanHours < 1) return 'Last ${(spanHours * 60).round()} min';
    if (spanHours < 48) return 'Last ${spanHours.round()}h';
    return 'Last ${(spanHours / 24).round()} days';
  }

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return _buildCard(
        context,
        child: _NotEnoughData(theme: Theme.of(context)),
      );
    }

    final firstTimestamp = _timestampOf(samples.first);
    final spots = _buildSpots(firstTimestamp);

    if (spots.length < 2) {
      return _buildCard(
        context,
        child: _NotEnoughData(theme: Theme.of(context)),
      );
    }

    final theme = Theme.of(context);
    final spanHours = spots.last.x - spots.first.x;
    final interval = _tickInterval(spanHours);
    final latestTime = DateTime.fromMillisecondsSinceEpoch(
      _timestampOf(samples.last),
    );

    return _buildCard(
      context,
      headerTrailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${spots.last.y.toStringAsFixed(1)}$unit',
            style: theme.textTheme.titleMedium,
          ),
          Text(_latestLabel(latestTime), style: theme.textTheme.bodySmall),
        ],
      ),
      footer: Text(_windowLabel(spanHours), style: theme.textTheme.bodySmall),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: true,
            verticalInterval: interval,
            getDrawingVerticalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  final time = DateTime.fromMillisecondsSinceEpoch(
                    firstTimestamp + (value * 3600000).round(),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _axisLabel(time, spanHours),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final time = DateTime.fromMillisecondsSinceEpoch(
                    firstTimestamp + (spot.x * 3600000).round(),
                  );
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)}$unit\n'
                    '${DateFormat('MMM d, HH:mm').format(time)}',
                    theme.textTheme.bodySmall?.copyWith(color: Colors.white) ??
                        const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.5,
              // Only the most recent sample gets a visible dot — anchors
              // "this is the latest reading" without cluttering every
              // point along the line.
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => spot == barData.spots.last,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required Widget child,
    Widget? headerTrailing,
    Widget? footer,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                ),
                ?headerTrailing,
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 180, child: child),
            if (footer != null) ...[const SizedBox(height: 4), footer],
          ],
        ),
      ),
    );
  }
}

class _NotEnoughData extends StatelessWidget {
  const _NotEnoughData({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Not enough samples yet for a trend line',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
