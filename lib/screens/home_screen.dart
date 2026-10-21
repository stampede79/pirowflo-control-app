import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../models/scheduled_workout.dart';

class HomeScreen extends StatelessWidget {
  final bool running;
  final String activeMode;

  final bool smartRowConnected;
  final bool smartRowReady;

  final bool calendarLoading;
  final String? calendarError;
  final Workout? todaysWorkout;

  final VoidCallback onStartWorkout;
  final ScheduledWorkout? nextWorkout;

  const HomeScreen({
    super.key,
    required this.running,
    required this.activeMode,
    required this.smartRowConnected,
    required this.smartRowReady,
    required this.calendarLoading,
    required this.calendarError,
    required this.todaysWorkout,
    required this.onStartWorkout,
    required this.nextWorkout,
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
      padding: const EdgeInsets.all(20),
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _StatusRow(
                  icon: running
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  iconColor: running ? Colors.green : Colors.grey,
                  title: running ? 'PiRowFlo läuft' : 'PiRowFlo gestoppt',
                  subtitle: 'Modus: $activeMode',
                ),
                const SizedBox(height: 16),
                _StatusRow(
                  icon: smartRowReady
                      ? Icons.check_circle
                      : smartRowConnected
                      ? Icons.sync
                      : Icons.radio_button_unchecked,
                  iconColor: smartRowReady
                      ? Colors.green
                      : smartRowConnected
                      ? Colors.orange
                      : Colors.grey,
                  title: smartRowReady
                      ? 'SmartRow verbunden'
                      : smartRowConnected
                      ? 'SmartRow verbindet …'
                      : 'SmartRow nicht verbunden',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

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
                  const SizedBox(height: 10),
                  Text('${todaysWorkout!.totalDuration.inMinutes} Minuten'),
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

        // Hier kommt im nächsten Schritt:
        //
        // Nächstes Training
        // Do., 22.10. · längere Grundlage · 50 Min.
        if (nextWorkout != null) ...[
          const SizedBox(height: 28),

          Text(
            'Nächstes Training',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '${_formatDate(nextWorkout!.start)} · '
                '${nextWorkout!.workout.name} · '
                '${nextWorkout!.workout.totalDuration.inMinutes} Min.',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;

  const _StatusRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
