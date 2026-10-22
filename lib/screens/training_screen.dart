import 'package:flutter/material.dart';

import '../models/scheduled_workout.dart';
import '../models/workout.dart';
import '../widgets/section_title.dart';
import '../widgets/water_header.dart';
import '../widgets/workout_timeline.dart';

class TrainingScreen extends StatelessWidget {
  final List<Workout> todaysWorkouts;
  final List<ScheduledWorkout> upcomingWorkouts;
  final bool calendarLoading;
  final String? calendarError;
  final void Function(Workout) onStartWorkout;
  final void Function(ScheduledWorkout) onOpenWorkout;

  const TrainingScreen({
    super.key,
    required this.todaysWorkouts,
    required this.upcomingWorkouts,
    required this.calendarLoading,
    required this.calendarError,
    required this.onStartWorkout,
    required this.onOpenWorkout,
  });

  String _formatDate(DateTime date) {
    const weekdays = ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];

    final weekday = weekdays[date.weekday - 1];

    return '$weekday, '
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const WaterHeader(height: 210),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Heute', icon: Icons.today_outlined),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                )
              else if (todaysWorkouts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Heute ist kein Training geplant.'),
                  ),
                )
              else
                ...todaysWorkouts.map(
                  (workout) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '${workout.totalDuration.inMinutes} Minuten',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),

                            if (workout.description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                workout.description,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],

                            const SizedBox(height: 22),

                            Text(
                              'Ablauf',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),

                            const SizedBox(height: 18),

                            WorkoutTimeline(workout: workout),

                            const SizedBox(height: 6),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => onStartWorkout(workout),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Training starten'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              const SectionTitle(
                'Trainingsplan',
                icon: Icons.calendar_month_outlined,
              ),
              const SizedBox(height: 12),

              if (upcomingWorkouts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Keine weiteren Trainings geplant.'),
                  ),
                )
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < upcomingWorkouts.length; i++) ...[
                        _UpcomingWorkoutTile(
                          scheduled: upcomingWorkouts[i],
                          formattedDate: _formatDate(upcomingWorkouts[i].start),
                          onTap: () => onOpenWorkout(upcomingWorkouts[i]),
                        ),
                        if (i < upcomingWorkouts.length - 1)
                          const Divider(height: 1, indent: 18, endIndent: 18),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpcomingWorkoutTile extends StatelessWidget {
  final ScheduledWorkout scheduled;
  final String formattedDate;
  final VoidCallback onTap;

  const _UpcomingWorkoutTile({
    required this.scheduled,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
                    scheduled.workout.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedDate · '
                    '${scheduled.workout.totalDuration.inMinutes} Min.',
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
    );
  }
}
