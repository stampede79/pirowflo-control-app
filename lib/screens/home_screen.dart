import 'package:flutter/material.dart';

import '../models/scheduled_workout.dart';
import '../widgets/section_title.dart';
import '../widgets/system_status_card.dart';
import '../widgets/water_header.dart';

class HomeScreen extends StatelessWidget {
  final bool running;
  final String activeMode;

  final bool smartRowConnected;
  final bool smartRowReady;

  final bool calendarLoading;
  final String? calendarError;
  final List<ScheduledWorkout> todaysWorkouts;

  final ScheduledWorkout? nextWorkout;
  final void Function(ScheduledWorkout) onOpenWorkout;
  final VoidCallback onStartTraining;
  final bool usingWorkoutCache;
  final DateTime? workoutCacheTimestamp;

  const HomeScreen({
    super.key,
    required this.running,
    required this.activeMode,
    required this.smartRowConnected,
    required this.smartRowReady,
    required this.calendarLoading,
    required this.calendarError,
    required this.todaysWorkouts,
    required this.onStartTraining,
    required this.nextWorkout,
    required this.onOpenWorkout,
    required this.usingWorkoutCache,
    required this.workoutCacheTimestamp,
  });

  String _formatDate(DateTime date) {
    const weekdays = ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];

    final weekday = weekdays[date.weekday - 1];

    return '$weekday, '
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.';
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final target = DateTime(date.year, date.month, date.day);

    final days = target.difference(today).inDays;

    if (days == 1) {
      return 'Morgen';
    }

    if (days == 2) {
      return 'Übermorgen';
    }

    if (days > 2 && days <= 7) {
      return 'In $days Tagen';
    }

    if (days > 7) {
      return 'In $days Tagen · ${_formatDate(date)}';
    }

    return _formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const WaterHeader(height: 310),

            Positioned(
              left: 20,
              right: 20,
              bottom: -105,
              child: SystemStatusCard(
                running: running,
                activeMode: activeMode,
                smartRowConnected: smartRowConnected,
                smartRowReady: smartRowReady,
              ),
            ),
          ],
        ),

        // Platz für die über das Bild hinausragende Status-Card.
        const SizedBox(height: 135),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Heute', icon: Icons.today_outlined),

              const SizedBox(height: 12),

              if (usingWorkoutCache && workoutCacheTimestamp != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Offline · Trainingsplan zuletzt '
                        'aktualisiert um '
                        '${workoutCacheTimestamp!.hour.toString().padLeft(2, '0')}:'
                        '${workoutCacheTimestamp!.minute.toString().padLeft(2, '0')} Uhr',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              if (calendarLoading)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 16),
                        Text('Trainingsplan wird geladen …'),
                      ],
                    ),
                  ),
                )
              else if (calendarError != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cloud_off_outlined),
                        const SizedBox(width: 12),
                        Expanded(child: Text(calendarError!)),
                      ],
                    ),
                  ),
                )
              else if (todaysWorkouts.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.self_improvement,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text('Heute ist kein Training geplant.'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...todaysWorkouts.map((scheduled) {
                  final workout = scheduled.workout;
                  final completed = scheduled.isCompleted;
                  final activity = scheduled.activity;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onOpenWorkout(scheduled),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      completed
                                          ? Icons.check_circle_outline
                                          : Icons.rowing,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          workout.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${workout.totalDuration.inMinutes} Minuten',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),

                                  Icon(
                                    Icons.chevron_right,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ],
                              ),

                              if (workout.description.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  workout.description,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],

                              const SizedBox(height: 16),

                              if (completed) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Training abgeschlossen',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ],
                                ),

                                if (activity != null) ...[
                                  const SizedBox(height: 12),

                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,
                                    children: [
                                      if (activity.durationMinutes != null)
                                        Text(
                                          '${activity.durationMinutes!.toStringAsFixed(1)} Min.',
                                        ),
                                      if (activity.distanceKm != null)
                                        Text(
                                          '${activity.distanceKm!.toStringAsFixed(2)} km',
                                        ),
                                      if (activity.averagePower != null)
                                        Text(
                                          'Ø ${activity.averagePower!.round()} W',
                                        ),
                                      if (activity.averageHr != null)
                                        Text(
                                          'Ø HF ${activity.averageHr!.round()}',
                                        ),
                                    ],
                                  ),
                                ],
                              ] else
                                Text(
                                  'Details ansehen',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStartTraining,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    todaysWorkouts.any(
                          (scheduled) =>
                              !scheduled.isCompleted &&
                              !scheduled.isSkipped &&
                              !scheduled.isMissed,
                        )
                        ? 'Training starten'
                        : 'Freies Training starten',
                  ),
                ),
              ),

              if (todaysWorkouts.isEmpty && nextWorkout != null) ...[
                const SizedBox(height: 30),

                const SectionTitle(
                  'Nächstes Training',
                  icon: Icons.event_outlined,
                ),

                const SizedBox(height: 12),

                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onOpenWorkout(nextWorkout!),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.event_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nextWorkout!.workout.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  '${_formatRelativeDate(nextWorkout!.start)} · '
                                  '${nextWorkout!.workout.totalDuration.inMinutes} Min.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
