import 'package:flutter/material.dart';

import '../models/training_plan_draft.dart';
import '../widgets/workout_timeline.dart';

class TrainingPlanDraftScreen extends StatefulWidget {
  final TrainingPlanDraft draft;
  final Future<void> Function() onApply;

  const TrainingPlanDraftScreen({
    super.key,
    required this.draft,
    required this.onApply,
  });

  @override
  State<TrainingPlanDraftScreen> createState() =>
      _TrainingPlanDraftScreenState();
}

class _TrainingPlanDraftScreenState extends State<TrainingPlanDraftScreen> {
  bool applying = false;

  TrainingPlanDraft get draft => widget.draft;

  String _formatDate(DateTime date) {
    const weekdays = ['', 'Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];

    return '${weekdays[date.weekday]} '
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.';
  }

  String _monthName() {
    final parts = draft.targetMonth.split('-');

    if (parts.length != 2) {
      return draft.targetMonth;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);

    const months = [
      '',
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];

    if (year == null || month == null || month < 1 || month > 12) {
      return draft.targetMonth;
    }

    return '${months[month]} $year';
  }

  Future<void> _apply() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trainingsplan übernehmen?'),
        content: Text(
          '${draft.workouts.length} Trainings für '
          '${_monthName()} werden in deinen '
          'Rudertraining-Kalender übernommen.\n\n'
          'Bestehende PiRowFlo-Trainings werden '
          'nicht überschrieben.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Übernehmen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      applying = true;
    });

    try {
      await widget.onApply();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trainingsplan wurde übernommen.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        applying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trainingsplan konnte nicht '
            'übernommen werden: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trainingsplan ${_monthName()}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${draft.workouts.length} Einheiten · '
            '${draft.sessionsPerWeek} pro Woche',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 24),

          for (final draftWorkout in draft.workouts) ...[
            Builder(
              builder: (context) {
                final workout = draftWorkout.toWorkout();

                if (workout == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${_formatDate(draftWorkout.date)} · '
                        '${draftWorkout.name}\n'
                        'Training konnte nicht '
                        'interpretiert werden.',
                      ),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(draftWorkout.date),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          draftWorkout.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),

                        if (draftWorkout.description.isNotEmpty) ...[
                          const SizedBox(height: 6),

                          Text(
                            draftWorkout.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],

                        const SizedBox(height: 16),

                        WorkoutTimeline(workout: workout),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),
          ],

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: applying ? null : _apply,
              icon: applying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calendar_month_outlined),
              label: Text(
                applying
                    ? 'Trainingsplan wird übernommen …'
                    : 'Trainingsplan übernehmen',
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
