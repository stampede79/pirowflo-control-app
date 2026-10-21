import 'package:flutter/material.dart';

import '../models/workout.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  final DateTime? scheduledDate;
  final VoidCallback onStartWorkout;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    required this.onStartWorkout,
    this.scheduledDate,
  });

  String _formatDate(DateTime date) {
    const weekdays = ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];

    final weekday = weekdays[date.weekday - 1];

    return '$weekday, '
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (seconds == 0) {
      return '$minutes Min.';
    }

    return '$minutes:${seconds.toString().padLeft(2, '0')} Min.';
  }

  String _formatPace(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;

    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }

  String _stepTypeLabel(WorkoutStepType type) {
    return switch (type) {
      WorkoutStepType.warmup => 'Warm-up',
      WorkoutStepType.work => 'Belastung',
      WorkoutStepType.recovery => 'Erholung',
      WorkoutStepType.cooldown => 'Cool-down',
    };
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
              Text(workout.description),
            ],

            const SizedBox(height: 24),

            for (final step in workout.steps) ...[
              _WorkoutStepCard(
                step: step,
                formatDuration: _formatDuration,
                formatPace: _formatPace,
                stepTypeLabel: _stepTypeLabel,
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: onStartWorkout,
              icon: const Icon(Icons.fitness_center),
              label: const Text('Training jetzt starten'),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _WorkoutStepCard extends StatelessWidget {
  final WorkoutStep step;
  final String Function(Duration) formatDuration;
  final String Function(int) formatPace;
  final String Function(WorkoutStepType) stepTypeLabel;

  const _WorkoutStepCard({
    required this.step,
    required this.formatDuration,
    required this.formatPace,
    required this.stepTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stepTypeLabel(step.type),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(step.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Text(formatDuration(step.duration)),

            if (step.targetPowerMin != null && step.targetPowerMax != null) ...[
              const SizedBox(height: 6),
              Text('${step.targetPowerMin}–${step.targetPowerMax} W'),
            ],

            if (step.targetSpmMin != null && step.targetSpmMax != null) ...[
              const SizedBox(height: 6),
              Text('${step.targetSpmMin}–${step.targetSpmMax} SPM'),
            ],

            if (step.hasTargetPace) ...[
              const SizedBox(height: 6),
              Text(
                '${formatPace(step.targetPaceMinSeconds!)}–'
                '${formatPace(step.targetPaceMaxSeconds!)} /500 m',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
