import 'package:flutter/material.dart';

import '../models/endurain_summary.dart';
import '../widgets/water_header.dart';

class StatisticsScreen extends StatelessWidget {
  final EndurainSummary? summary;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;
  final EndurainSummaryPeriod period;
  final ValueChanged<EndurainSummaryPeriod> onPeriodChanged;

  const StatisticsScreen({
    super.key,
    required this.summary,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.period,
    required this.onPeriodChanged,
  });

  String _formatDistance(double meters) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')} h';
    }

    return '${duration.inMinutes} Min.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WaterHeader(
          height: 210,
          title: 'Statistik',
          subtitle: 'Deine Entwicklung im Überblick',
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<EndurainSummaryPeriod>(
              segments: EndurainSummaryPeriod.values
                  .map(
                    (period) =>
                        ButtonSegment(value: period, label: Text(period.label)),
                  )
                  .toList(),
              selected: {period},
              showSelectedIcon: false,
              onSelectionChanged: loading
                  ? null
                  : (selection) {
                      onPeriodChanged(selection.first);
                    },
            ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(switch (period) {
                  EndurainSummaryPeriod.week => 'Diese Woche',
                  EndurainSummaryPeriod.month => 'Dieser Monat',
                  EndurainSummaryPeriod.year => 'Dieses Jahr',
                  EndurainSummaryPeriod.lifetime => 'Gesamt',
                }, style: Theme.of(context).textTheme.headlineMedium),

                const SizedBox(height: 6),

                Text(
                  'Deine Indoor-Ruderaktivitäten aus Endurain',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 24),

                if (loading && summary == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (error != null && summary == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: onRefresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (summary != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatisticCard(
                          icon: Icons.rowing,
                          value: '${summary!.activityCount}',
                          label: summary!.activityCount == 1
                              ? 'Training'
                              : 'Trainings',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatisticCard(
                          icon: Icons.straighten,
                          value: _formatDistance(summary!.distance),
                          label: 'Distanz',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _StatisticCard(
                          icon: Icons.timer_outlined,
                          value: _formatDuration(summary!.duration),
                          label: 'Trainingszeit',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatisticCard(
                          icon: Icons.local_fire_department_outlined,
                          value: '${summary!.calories.round()}',
                          label: 'kcal',
                        ),
                      ),
                    ],
                  ),

                  if (summary!.breakdown.isNotEmpty) ...[
                    const SizedBox(height: 32),

                    Text(switch (period) {
                      EndurainSummaryPeriod.week => 'Wochenverlauf',
                      EndurainSummaryPeriod.month => 'Monatsverlauf',
                      EndurainSummaryPeriod.year => 'Jahresverlauf',
                      EndurainSummaryPeriod.lifetime => 'Entwicklung',
                    }, style: Theme.of(context).textTheme.titleLarge),

                    const SizedBox(height: 16),

                    _DistanceChart(
                      breakdown: summary!.breakdown,
                      period: period,
                    ),
                  ],

                  if (loading) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                  ],

                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatisticCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DistanceChart extends StatelessWidget {
  final List<EndurainSummaryBreakdown> breakdown;
  final EndurainSummaryPeriod period;

  const _DistanceChart({required this.breakdown, required this.period});

  String _label(int value) {
    return switch (period) {
      EndurainSummaryPeriod.week => const [
        'Mo',
        'Di',
        'Mi',
        'Do',
        'Fr',
        'Sa',
        'So',
      ][value],

      EndurainSummaryPeriod.month => 'KW$value',

      EndurainSummaryPeriod.year => const [
        '',
        'Jan',
        'Feb',
        'Mär',
        'Apr',
        'Mai',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Okt',
        'Nov',
        'Dez',
      ][value],

      EndurainSummaryPeriod.lifetime => '$value',
    };
  }

  @override
  Widget build(BuildContext context) {
    final maxDistance = breakdown.fold<double>(
      0,
      (max, item) => item.distance > max ? item.distance : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
        child: SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final item in breakdown)
                Expanded(
                  child: _DayBar(
                    label: _label(item.period),
                    distance: item.distance,
                    maxDistance: maxDistance,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final String label;
  final double distance;
  final double maxDistance;

  const _DayBar({
    required this.label,
    required this.distance,
    required this.maxDistance,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxDistance <= 0
        ? 0.0
        : (distance / maxDistance).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (distance > 0)
          Text(
            (distance / 1000).toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 4),

        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction,
              child: Container(
                width: 22,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
