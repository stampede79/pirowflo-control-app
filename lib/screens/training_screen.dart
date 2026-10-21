import 'package:flutter/material.dart';

import '../models/scheduled_workout.dart';
import '../models/workout.dart';

class TrainingScreen extends StatelessWidget {
  final Workout? todaysWorkout;
  final List<ScheduledWorkout> upcomingWorkouts;
  final bool calendarLoading;
  final String? calendarError;
  final VoidCallback onStartWorkout;

  const TrainingScreen({
    super.key,
    required this.todaysWorkout,
    required this.upcomingWorkouts,
    required this.calendarLoading,
    required this.calendarError,
    required this.onStartWorkout,
  });

  String _formatDate(DateTime date) {
    const weekdays = ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];

    final weekday = weekdays[date.weekday - 1];

    return '$weekday, '
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.';
  }

  String _stepDescription(WorkoutStep step) {
    final parts = <String>['${step.duration.inMinutes} Min.'];

    if (step.targetPowerMin != null && step.targetPowerMax != null) {
      parts.add('${step.targetPowerMin}–${step.targetPowerMax} W');
    }

    if (step.targetSpmMin != null && step.targetSpmMax != null) {
      parts.add('${step.targetSpmMin}–${step.targetSpmMax} SPM');
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Heute', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

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
              child: Text(
                calendarError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          )
        else if (todaysWorkout == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Heute ist kein Training geplant.'),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todaysWorkout!.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (todaysWorkout!.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(todaysWorkout!.description),
                  ],

                  const SizedBox(height: 16),

                  for (final step in todaysWorkout!.steps) ...[
                    Text(
                      '${step.title}: '
                      '${_stepDescription(step)}',
                    ),
                    const SizedBox(height: 6),
                  ],

                  const SizedBox(height: 10),

                  Text(
                    'Gesamt: '
                    '${todaysWorkout!.totalDuration.inMinutes} Min.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onStartWorkout,
                      icon: const Icon(Icons.fitness_center),
                      label: const Text('Training starten'),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 28),

        Text('Trainingsplan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        if (upcomingWorkouts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Keine weiteren Trainings geplant.'),
            ),
          )
        else
          for (final scheduled in upcomingWorkouts) ...[
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.rowing),
                title: Text(scheduled.workout.name),
                subtitle: Text(
                  '${_formatDate(scheduled.start)} · '
                  '${scheduled.workout.totalDuration.inMinutes} Min.',
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}
