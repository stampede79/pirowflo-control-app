import 'package:flutter/material.dart';

import '../models/endurain_activity.dart';
import 'rowing_activity_detail_screen.dart';

class RowingActivitiesScreen extends StatelessWidget {
  final List<EndurainActivity> activities;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;
  final String endurainServer;

  const RowingActivitiesScreen({
    super.key,
    required this.activities,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.endurainServer,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '${duration.inMinutes}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            'Rudertrainings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Deine letzten Indoor-Ruderaktivitäten aus Endurain',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),

          if (loading && activities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null && activities.isEmpty)
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
          else if (activities.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Keine Rudertrainings gefunden.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < activities.length; i++) ...[
                    _ActivityTile(
                      activity: activities[i],
                      formatDate: _formatDate,
                      formatDuration: _formatDuration,
                      endurainServer: endurainServer,
                    ),
                    if (i < activities.length - 1)
                      const Divider(height: 1, indent: 18, endIndent: 18),
                  ],
                ],
              ),
            ),

          if (loading && activities.isNotEmpty) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final EndurainActivity activity;
  final String Function(DateTime) formatDate;
  final String Function(double) formatDuration;
  final String endurainServer;

  const _ActivityTile({
    required this.activity,
    required this.formatDate,
    required this.formatDuration,
    required this.endurainServer,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RowingActivityDetailScreen(
              activity: activity,
              endurainServer: endurainServer,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.rowing,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatDate(activity.startTime)} · '
                    '${activity.distanceKm.toStringAsFixed(2)} km · '
                    '${formatDuration(activity.duration)}',
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${activity.averagePower.round()} W · '
                    '${activity.averageCadence.round()} SPM · '
                    '${activity.averageHeartRate.round()} bpm',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
