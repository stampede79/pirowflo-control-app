import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/endurain_stream.dart';

class RowingStreamChart extends StatelessWidget {
  final EndurainStream stream;
  final String title;
  final String unit;
  final IconData icon;
  final double edgeThreshold;
  final bool removeSpikes;
  final bool useMedianFilter;
  final DateTime chartStart;
  final Duration chartDuration;

  const RowingStreamChart({
    super.key,
    required this.stream,
    required this.title,
    required this.unit,
    required this.icon,
    required this.chartStart,
    required this.chartDuration,
    this.edgeThreshold = 0,
    this.removeSpikes = true,
    this.useMedianFilter = true,
  });

  int _findActiveStart(List<EndurainStreamPoint> points) {
    const windowSize = 12;
    const requiredActive = 9;

    for (var i = 0; i <= points.length - windowSize; i++) {
      final window = points.sublist(i, i + windowSize);

      final activeValues =
          window
              .map((point) => point.value)
              .where((value) => value >= edgeThreshold)
              .toList()
            ..sort();

      if (activeValues.length < requiredActive) {
        continue;
      }

      final median = activeValues[activeValues.length ~/ 2];

      if (median < edgeThreshold * 2) {
        continue;
      }

      for (var j = i; j < i + windowSize; j++) {
        if (points[j].value >= edgeThreshold * 2) {
          return j;
        }
      }

      return i;
    }

    return 0;
  }

  List<EndurainStreamPoint> _removeShortSpikes(
    List<EndurainStreamPoint> points,
  ) {
    if (points.length < 11) {
      return points;
    }

    final result = List<EndurainStreamPoint>.from(points);

    double median(List<double> values) {
      final sorted = List<double>.from(values)..sort();
      return sorted[sorted.length ~/ 2];
    }

    var i = 4;

    while (i < points.length - 4) {
      final before = median(
        points.sublist(i - 4, i).map((point) => point.value).toList(),
      );

      // Kandidat muss deutlich über dem vorherigen Niveau liegen.
      final threshold = math.max(before + 80, before * 2.0);

      if (points[i].value <= threshold) {
        i++;
        continue;
      }

      // Zusammenhängenden hohen Block suchen,
      // maximal 5 Sekunden lang.
      var end = i;

      while (end < points.length &&
          end < i + 5 &&
          points[end].value > threshold) {
        end++;
      }

      final spikeLength = end - i;

      if (spikeLength == 0 || spikeLength > 5 || end + 4 > points.length) {
        i++;
        continue;
      }

      final after = median(
        points.sublist(end, end + 4).map((point) => point.value).toList(),
      );

      // Vor und nach dem Peak muss das Leistungsniveau
      // ungefähr gleich sein.
      final surroundingsMatch =
          (before - after).abs() <= math.max(20, ((before + after) / 2) * 0.25);

      if (!surroundingsMatch) {
        i = end;
        continue;
      }

      // Messartefakt durch linearen Übergang ersetzen.
      for (var j = i; j < end; j++) {
        final fraction = (j - i + 1) / (spikeLength + 1);

        final replacement = before + (after - before) * fraction;

        result[j] = EndurainStreamPoint(
          time: points[j].time,
          value: replacement,
        );
      }

      i = end;
    }

    return result;
  }

  List<EndurainStreamPoint> _preparePoints(List<EndurainStreamPoint> source) {
    if (source.isEmpty) {
      return const [];
    }

    final start = _findActiveStart(source);
    var end = source.length;

    while (end > start && source[end - 1].value <= edgeThreshold) {
      end--;
    }

    final trimmed = source.sublist(start, end);

    final prepared = removeSpikes ? _removeShortSpikes(trimmed) : trimmed;

    if (!useMedianFilter || prepared.length < 5) {
      return prepared;
    }

    final filtered = <EndurainStreamPoint>[];

    for (var i = 0; i < prepared.length; i++) {
      final from = math.max(0, i - 2);
      final to = math.min(prepared.length, i + 3);

      final window =
          prepared.sublist(from, to).map((point) => point.value).toList()
            ..sort();

      final median = window[window.length ~/ 2];

      filtered.add(EndurainStreamPoint(time: prepared[i].time, value: median));
    }

    return filtered;
  }

  List<EndurainStreamPoint> _downsample(
    List<EndurainStreamPoint> points, {
    int maxPoints = 200,
  }) {
    if (points.length <= maxPoints) {
      return points;
    }

    final result = <EndurainStreamPoint>[];
    final step = points.length / maxPoints;

    for (var i = 0; i < maxPoints; i++) {
      final index = math.min((i * step).floor(), points.length - 1);

      result.add(points[index]);
    }

    return result;
  }

  String _formatElapsed(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (seconds == 0) {
      return '$minutes min';
    }

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final prepared = _preparePoints(stream.points);
    final points = _downsample(prepared);

    final totalDuration = chartDuration;

    Duration atFraction(double fraction) {
      return Duration(
        milliseconds: (totalDuration.inMilliseconds * fraction).round(),
      );
    }

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final values = points.map((point) => point.value).toList();

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final average = values.reduce((a, b) => a + b) / values.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'Ø ${average.round()} $unit',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _StreamPainter(
                  points: points,
                  minValue: minValue,
                  maxValue: maxValue,
                  lineColor: Theme.of(context).colorScheme.primary,
                  gridColor: Theme.of(context).colorScheme.outlineVariant,
                  chartStart: chartStart,
                  chartDuration: chartDuration,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  _formatElapsed(atFraction(1 / 3)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _formatElapsed(atFraction(2 / 3)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _formatElapsed(totalDuration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min ${minValue.round()} $unit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Max ${maxValue.round()} $unit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamPainter extends CustomPainter {
  final List<EndurainStreamPoint> points;
  final double minValue;
  final double maxValue;
  final Color lineColor;
  final Color gridColor;
  final DateTime chartStart;
  final Duration chartDuration;

  const _StreamPainter({
    required this.points,
    required this.minValue,
    required this.maxValue,
    required this.lineColor,
    required this.gridColor,
    required this.chartStart,
    required this.chartDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final range = maxValue - minValue;
    final effectiveRange = range <= 0 ? 1.0 : range;

    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final elapsed = points[i].time.difference(chartStart);

      final fraction = chartDuration.inMilliseconds <= 0
          ? 0.0
          : elapsed.inMilliseconds / chartDuration.inMilliseconds;

      final x = size.width * fraction.clamp(0.0, 1.0);

      final normalized = (points[i].value - minValue) / effectiveRange;

      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _StreamPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.chartStart != chartStart ||
        oldDelegate.chartDuration != chartDuration;
  }
}
