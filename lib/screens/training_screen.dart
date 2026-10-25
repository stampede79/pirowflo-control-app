import 'package:flutter/material.dart';

import '../models/scheduled_workout.dart';
import '../models/workout.dart';
import '../widgets/section_title.dart';
import '../widgets/water_header.dart';
import '../widgets/workout_timeline.dart';
import '../models/recent_workout_match.dart';
import '../models/endurain_activity.dart';
import '../utils/user_friendly_error.dart';
import 'rowing_activity_detail_screen.dart';
import '../models/training_history_entry.dart';
import '../models/training_plan_draft.dart';
import 'training_plan_draft_screen.dart';

class TrainingScreen extends StatelessWidget {
  final List<Workout> todaysWorkouts;
  final List<ScheduledWorkout> upcomingWorkouts;
  final bool calendarLoading;
  final String? calendarError;
  final void Function(Workout) onStartWorkout;
  final void Function(ScheduledWorkout) onOpenWorkout;
  final List<TrainingHistoryEntry> trainingHistory;
  final Future<void> Function(RecentWorkoutMatch) onLinkWorkout;
  final String endurainServer;
  final bool historyLoadingMore;
  final Future<void> Function() onLoadMoreHistory;
  final bool historyHasMore;
  final TrainingPlanDraft? trainingPlanDraft;
  final bool trainingPlanDraftLoading;
  final Future<void> Function() onApplyTrainingPlan;

  const TrainingScreen({
    super.key,
    required this.todaysWorkouts,
    required this.upcomingWorkouts,
    required this.calendarLoading,
    required this.calendarError,
    required this.onStartWorkout,
    required this.onOpenWorkout,
    required this.trainingHistory,
    required this.onLinkWorkout,
    required this.endurainServer,
    required this.historyLoadingMore,
    required this.onLoadMoreHistory,
    required this.historyHasMore,
    required this.trainingPlanDraft,
    required this.trainingPlanDraftLoading,
    required this.onApplyTrainingPlan,
  });

  String _formatHistoryDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.';
  }

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
              if (trainingPlanDraft != null) ...[
                const SizedBox(height: 32),

                const SectionTitle(
                  'Neuer Trainingsplan',
                  icon: Icons.auto_awesome_outlined,
                ),

                const SizedBox(height: 12),

                _TrainingPlanDraftTile(
                  draft: trainingPlanDraft!,
                  onApply: onApplyTrainingPlan,
                ),
              ],
              if (trainingHistory.isNotEmpty) ...[
                const SizedBox(height: 32),

                const SectionTitle('Trainingshistorie', icon: Icons.history),

                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < trainingHistory.length; i++) ...[
                      if (i == 0 ||
                          trainingHistory[i].date.year !=
                              trainingHistory[i - 1].date.year) ...[
                        if (i > 0) const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                          child: Text(
                            trainingHistory[i].date.year.toString(),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],

                      _TrainingHistoryTile(
                        entry: trainingHistory[i],
                        formattedDate: _formatHistoryDate(
                          trainingHistory[i].date,
                        ),
                        endurainServer: endurainServer,
                        onLink: trainingHistory[i].match == null
                            ? null
                            : () => onLinkWorkout(trainingHistory[i].match!),
                      ),
                    ],
                  ],
                ),

                if (historyHasMore) ...[
                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    onPressed: historyLoadingMore ? null : onLoadMoreHistory,
                    icon: historyLoadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: Text(
                      historyLoadingMore
                          ? 'Ältere Trainings werden gesucht …'
                          : 'Ältere Trainings laden',
                    ),
                  ),
                ],
              ],

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

class _TrainingPlanDraftTile extends StatelessWidget {
  final TrainingPlanDraft draft;
  final Future<void> Function() onApply;

  const _TrainingPlanDraftTile({required this.draft, required this.onApply});

  String get _monthName {
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Vorschau folgt im nächsten Schritt.
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TrainingPlanDraftScreen(draft: draft, onApply: onApply),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: colors.onSecondaryContainer,
                size: 26,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSecondaryContainer,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${draft.workouts.length} Einheiten · '
                      '${draft.sessionsPerWeek} pro Woche',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              Icon(Icons.chevron_right, color: colors.onSecondaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingHistoryTile extends StatelessWidget {
  final TrainingHistoryEntry entry;
  final String formattedDate;
  final String endurainServer;
  final Future<void> Function()? onLink;

  const _TrainingHistoryTile({
    required this.entry,
    required this.formattedDate,
    required this.endurainServer,
    required this.onLink,
  });

  Future<void> _confirmLink(
    BuildContext context,
    EndurainActivity activity,
  ) async {
    final match = entry.match;

    if (match == null || onLink == null) {
      return;
    }

    final scheduled = match.scheduledWorkout;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Training verknüpfen?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scheduled.workout.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 16),

            Text(
              'Geplant: '
              '${scheduled.workout.totalDuration.inMinutes} Min.',
            ),

            const SizedBox(height: 8),

            Text(
              'Endurain #${activity.id}\n'
              '${Duration(seconds: activity.duration.round()).inMinutes} Min. · '
              '${activity.distanceKm.toStringAsFixed(1)} km · '
              'Ø ${activity.averagePower.toStringAsFixed(0)} W\n'
              'Start: '
              '${activity.startTime.toLocal().hour.toString().padLeft(2, '0')}:'
              '${activity.startTime.toLocal().minute.toString().padLeft(2, '0')} Uhr',
            ),

            const SizedBox(height: 16),

            const Text(
              'Die Endurain-Aktivität wird dauerhaft mit diesem '
              'Kalendertraining verknüpft.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.link),
            label: const Text('Verknüpfen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await onLink!();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Training wurde mit Endurain verknüpft.')),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserFriendlyError.nextcloud(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = entry.match;
    final freeActivity = entry.activity;

    final scheduled = match?.scheduledWorkout;
    final candidateActivity = match?.candidate?.activity;
    final linkedActivity = match?.linkedActivity;

    final colors = Theme.of(context).colorScheme;

    final bool isFree = entry.type == TrainingHistoryEntryType.free;

    final (icon, backgroundColor, foregroundColor) = isFree
        ? (Icons.rowing, colors.secondaryContainer, colors.onSecondaryContainer)
        : switch (match!.status) {
            RecentWorkoutMatchStatus.linked => (
              Icons.check_circle_outline,
              colors.primaryContainer,
              colors.onPrimaryContainer,
            ),
            RecentWorkoutMatchStatus.candidate => (
              Icons.help_outline,
              colors.tertiaryContainer,
              colors.onTertiaryContainer,
            ),
            RecentWorkoutMatchStatus.waiting => (
              Icons.schedule_outlined,
              colors.surfaceContainer,
              colors.onSurfaceVariant,
            ),
          };

    final String title;
    final String subtitle;

    if (isFree) {
      final activity = freeActivity!;

      title = 'Freies Training';

      subtitle =
          '${Duration(seconds: activity.duration.round()).inMinutes} Min. · '
          '${activity.distanceKm.toStringAsFixed(1)} km · '
          'Ø ${activity.averagePower.toStringAsFixed(0)} W';
    } else {
      final plannedMatch = match!;

      title = scheduled!.workout.name;

      switch (plannedMatch.status) {
        case RecentWorkoutMatchStatus.linked:
          if (linkedActivity != null) {
            subtitle =
                '${Duration(seconds: linkedActivity.duration.round()).inMinutes} Min. · '
                '${linkedActivity.distanceKm.toStringAsFixed(1)} km · '
                'Ø ${linkedActivity.averagePower.toStringAsFixed(0)} W';
          } else {
            subtitle =
                '${scheduled.workout.totalDuration.inMinutes} Min. · '
                'mit Endurain verknüpft';
          }

        case RecentWorkoutMatchStatus.candidate:
          final actualMinutes = candidateActivity == null
              ? null
              : Duration(seconds: candidateActivity.duration.round()).inMinutes;

          subtitle = actualMinutes == null
              ? '${scheduled.workout.totalDuration.inMinutes} Min. geplant'
              : '${scheduled.workout.totalDuration.inMinutes} Min. geplant · '
                    '$actualMinutes Min. tatsächlich';

        case RecentWorkoutMatchStatus.waiting:
          subtitle =
              '${scheduled.workout.totalDuration.inMinutes} Min. geplant · '
              'wartet auf Aktivität';
      }
    }

    final bool interactive =
        isFree ||
        (match?.status == RecentWorkoutMatchStatus.linked &&
            linkedActivity != null) ||
        (match?.status == RecentWorkoutMatchStatus.candidate &&
            candidateActivity != null);

    Future<void> handleTap() async {
      if (isFree && freeActivity != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RowingActivityDetailScreen(
              activity: freeActivity,
              endurainServer: endurainServer,
            ),
          ),
        );

        return;
      }

      if (match?.status == RecentWorkoutMatchStatus.linked &&
          linkedActivity != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RowingActivityDetailScreen(
              activity: linkedActivity,
              endurainServer: endurainServer,
            ),
          ),
        );

        return;
      }

      if (match?.status == RecentWorkoutMatchStatus.candidate &&
          candidateActivity != null) {
        await _confirmLink(context, candidateActivity);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: interactive ? handleTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: foregroundColor, size: 24),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: foregroundColor,
                                  ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            formattedDate,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: foregroundColor),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: foregroundColor),
                      ),
                    ],
                  ),
                ),

                if (interactive) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: foregroundColor),
                ],
              ],
            ),
          ),
        ),
      ),
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
