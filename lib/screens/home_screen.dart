import 'package:flutter/material.dart';

import '../models/scheduled_workout.dart';
import '../models/workout.dart';
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
  final List<Workout> todaysWorkouts;

  final void Function(Workout) onStartWorkout;
  final ScheduledWorkout? nextWorkout;
  final void Function(ScheduledWorkout) onOpenWorkout;

  const HomeScreen({
    super.key,
    required this.running,
    required this.activeMode,
    required this.smartRowConnected,
    required this.smartRowReady,
    required this.calendarLoading,
    required this.calendarError,
    required this.todaysWorkouts,
    required this.onStartWorkout,
    required this.nextWorkout,
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
                ...todaysWorkouts.map(
                  (workout) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
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
                                    Icons.rowing,
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
                              ],
                            ),

                            if (workout.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                workout.description,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],

                            const SizedBox(height: 20),

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
                              Icons.calendar_month_outlined,
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
                                  '${_formatDate(nextWorkout!.start)} · '
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
