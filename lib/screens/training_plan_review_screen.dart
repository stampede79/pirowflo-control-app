import 'package:flutter/material.dart';

import '../models/training_plan_review.dart';

class TrainingPlanReviewScreen extends StatefulWidget {
  final TrainingPlanReview review;
  final Future<void> Function() onApply;

  const TrainingPlanReviewScreen({
    super.key,
    required this.review,
    required this.onApply,
  });

  @override
  State<TrainingPlanReviewScreen> createState() =>
      _TrainingPlanReviewScreenState();
}

class _TrainingPlanReviewScreenState extends State<TrainingPlanReviewScreen> {
  bool applying = false;

  TrainingPlanReview get review => widget.review;

  String _formatDate(DateTime date) {
    const weekdays = ['', 'Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];

    return '${weekdays[date.weekday]} '
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.';
  }

  String _actionLabel(String action) {
    return switch (action) {
      'skip' => 'Aussetzen',
      'move' => 'Verschieben',
      'modify' => 'Anpassen',
      _ => action,
    };
  }

  IconData _actionIcon(String action) {
    return switch (action) {
      'skip' => Icons.skip_next_outlined,
      'move' => Icons.event_repeat_outlined,
      'modify' => Icons.tune_outlined,
      _ => Icons.info_outline,
    };
  }

  Future<void> _apply() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plananpassungen übernehmen?'),
        content: Text(
          '${review.changes.length} '
          '${review.changes.length == 1 ? 'Änderung' : 'Änderungen'} '
          'werden in deinen Trainingsplan übernommen.\n\n'
          'Ausgesetzte Trainings bleiben im Kalender '
          'erhalten und werden als bewusst ausgesetzt '
          'markiert.',
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
            icon: const Icon(Icons.check),
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plananpassungen wurden übernommen.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        applying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Plananpassungen konnten nicht '
            'übernommen werden: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Trainingscoach')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Plananpassung empfohlen',
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 12),

          Text(review.summary, style: Theme.of(context).textTheme.bodyLarge),

          const SizedBox(height: 28),

          Text(
            '${review.changes.length} '
            '${review.changes.length == 1 ? 'Änderung' : 'Änderungen'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          for (final change in review.changes) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_actionIcon(change.action), color: colors.primary),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            _actionLabel(change.action),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),

                        Text(
                          _formatDate(change.originalDate),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),

                    if (change.name != null) ...[
                      const SizedBox(height: 12),

                      Text(
                        change.name!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],

                    const SizedBox(height: 8),

                    Text(
                      change.reason,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    if (change.action == 'move' && change.newDate != null) ...[
                      const SizedBox(height: 12),

                      Text(
                        'Neuer Termin: '
                        '${_formatDate(change.newDate!)}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],

          const SizedBox(height: 12),

          Card(
            color: colors.surfaceContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dies ist zunächst nur ein Vorschlag. '
                      'Dein Trainingsplan wurde noch nicht '
                      'verändert.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            color: colors.surfaceContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dies ist zunächst nur ein Vorschlag. '
                      'Dein Trainingsplan wurde noch nicht '
                      'verändert.',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // NEU:
          const SizedBox(height: 16),

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
                  : const Icon(Icons.check),
              label: Text(
                applying
                    ? 'Änderungen werden übernommen …'
                    : 'Änderungen übernehmen',
              ),
            ),
          ),

          // BESTAND:
          const SizedBox(height: 20),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
