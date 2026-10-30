import 'package:flutter/material.dart';

import '../models/scheduled_workout.dart';
import '../models/workout.dart';
import '../models/workout_analysis.dart';
import '../widgets/workout_timeline.dart';
import '../widgets/water_header.dart';
import '../models/endurain_activity.dart';
import 'rowing_activity_detail_screen.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final ScheduledWorkout scheduledWorkout;
  final WorkoutAnalysis? analysis;
  final EndurainActivity? endurainActivity;
  final String server;
  final String apiKey;

  const WorkoutDetailScreen({
    super.key,
    required this.scheduledWorkout,
    this.analysis,
    this.endurainActivity,
    required this.server,
    required this.apiKey,
  });

  Workout get workout => scheduledWorkout.workout;

  String _formatDate(DateTime date) {
    const weekdays = ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];

    final weekday = weekdays[date.weekday - 1];

    return '$weekday, '
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.';
  }

  String _statusLabel() {
    if (scheduledWorkout.isCompleted) {
      return 'Abgeschlossen';
    }

    if (scheduledWorkout.isSkipped) {
      return 'Übersprungen';
    }

    if (scheduledWorkout.isMissed) {
      return 'Verpasst';
    }

    return 'Geplant';
  }

  String _analysisLabel(String? value) {
    return switch (value) {
      'good' => 'Gut',
      'partial' => 'Teilweise',
      'poor' => 'Schlecht',
      'appropriate' => 'Angemessen',
      'low' => 'Niedrig',
      'high' => 'Hoch',
      'moderate' => 'Moderat',
      'easy' => 'Locker',
      'hard' => 'Hart',
      'stable' => 'Stabil',
      'improving' => 'Verbessernd',
      'declining' => 'Rückläufig',
      'concerning' => 'Auffällig',
      null => '–',
      _ => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final activity = scheduledWorkout.activity;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Stack(
              children: [
                WaterHeader(
                  height: 225,
                  title: workout.name,
                  subtitle:
                      '${_formatDate(scheduledWorkout.start)} · '
                      '${_statusLabel()}',
                ),

                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton.filledTonal(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Zurück',
                  ),
                ),
              ],
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const _DetailSectionTitle(
                    title: 'Trainingsplan',
                    icon: Icons.route_outlined,
                  ),

                  const SizedBox(height: 16),

                  WorkoutTimeline(workout: workout),

                  if (activity != null) ...[
                    const SizedBox(height: 32),

                    const _DetailSectionTitle(
                      title: 'Ergebnis',
                      icon: Icons.analytics_outlined,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            value: activity.durationMinutes != null
                                ? '${activity.durationMinutes!.toStringAsFixed(1)} Min.'
                                : '–',
                            label: 'Dauer',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            value: activity.distanceKm != null
                                ? '${activity.distanceKm!.toStringAsFixed(2)} km'
                                : '–',
                            label: 'Distanz',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            value: activity.averagePower != null
                                ? '${activity.averagePower!.round()} W'
                                : '–',
                            label: 'Ø Leistung',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            value: activity.normalizedPower != null
                                ? '${activity.normalizedPower!.round()} W'
                                : '–',
                            label: 'Normalized Power',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            value: activity.averageHr != null
                                ? '${activity.averageHr!.round()} bpm'
                                : '–',
                            label: 'Ø Herzfrequenz',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            value: activity.maxHr != null
                                ? '${activity.maxHr!.round()} bpm'
                                : '–',
                            label: 'Max. Herzfrequenz',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _MetricCard(
                      value: activity.averageSpm != null
                          ? '${activity.averageSpm!.round()} SPM'
                          : '–',
                      label: 'Ø Schlagrate',
                    ),
                    if (endurainActivity != null) ...[
                      const SizedBox(height: 16),

                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RowingActivityDetailScreen(
                                activity: endurainActivity!,
                                server: server,
                                apiKey: apiKey,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.query_stats_outlined),
                        label: const Text('Detaillierte Aktivitätsdaten'),
                      ),
                    ],
                  ],

                  if (analysis != null) ...[
                    const SizedBox(height: 32),

                    const _DetailSectionTitle(
                      title: 'Coach-Auswertung',
                      icon: Icons.psychology_outlined,
                    ),

                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _AnalysisRow(
                              label: 'Ausführung',
                              value: _analysisLabel(analysis!.execution),
                            ),
                            _AnalysisRow(
                              label: 'Belastung',
                              value: _analysisLabel(analysis!.loadAssessment),
                            ),
                            _AnalysisRow(
                              label: 'Anstrengung',
                              value: _analysisLabel(analysis!.effort),
                            ),
                            _AnalysisRow(
                              label: 'Entwicklung',
                              value: _analysisLabel(analysis!.progression),
                            ),
                            _AnalysisRow(
                              label: 'Recovery',
                              value: analysis!.recoveryConcern == true
                                  ? 'Beobachten'
                                  : 'Unauffällig',
                              last: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (analysis!.summary.isNotEmpty) ...[
                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zusammenfassung',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(analysis!.summary),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (analysis!.recommendation != null &&
                        analysis!.recommendation!.isNotEmpty) ...[
                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Empfehlung',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(analysis!.recommendation!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],

                  if (scheduledWorkout.isCompleted && activity == null) ...[
                    const SizedBox(height: 28),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.link_off_outlined),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Für dieses Training ist '
                                'noch keine Aktivität '
                                'verknüpft.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _DetailSectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;

  const _MetricCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _AnalysisRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        if (!last) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
