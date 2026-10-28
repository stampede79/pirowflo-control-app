import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../widgets/workout_timeline.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  final DateTime? scheduledDate;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    this.scheduledDate,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              workout.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            if (scheduledDate != null) ...[
              const SizedBox(height: 6),
              Text(
                '${_formatDate(scheduledDate!)} · '
                '${workout.totalDuration.inMinutes} Min.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],

            if (workout.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                workout.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],

            const SizedBox(height: 28),

            Text('Ablauf', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 18),

            WorkoutTimeline(workout: workout),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
