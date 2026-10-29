import 'package:flutter/material.dart';

import '../models/scheduled_workout.dart';
import '../models/workout.dart';
import '../widgets/section_title.dart';
import '../widgets/water_header.dart';
import '../models/recent_workout_match.dart';
import '../models/endurain_activity.dart';
import 'rowing_activity_detail_screen.dart';
import '../models/training_history_entry.dart';
import '../models/training_plan_draft.dart';
import 'training_plan_draft_screen.dart';
import '../models/training_plan_review.dart';
import 'training_plan_review_screen.dart';
import '../utils/workout_display.dart';

enum TrainingView { overview, plan, history }

class TrainingScreen extends StatefulWidget {
  final List<ScheduledWorkout> todaysWorkouts;
  final List<ScheduledWorkout> upcomingWorkouts;
  final bool calendarLoading;
  final String? calendarError;
  final void Function(Workout) onStartWorkout;
  final void Function(ScheduledWorkout) onOpenWorkout;
  final List<TrainingHistoryEntry> trainingHistory;
  final Future<void> Function(RecentWorkoutMatch) onLinkWorkout;
  final String endurainServer;
  final String server;
  final String apiKey;
  final bool historyLoadingMore;
  final Future<void> Function() onLoadMoreHistory;
  final bool historyHasMore;
  final TrainingPlanDraft? trainingPlanDraft;
  final bool trainingPlanDraftLoading;
  final Future<void> Function() onApplyTrainingPlan;
  final TrainingPlanReview? trainingPlanReview;
  final bool trainingPlanReviewLoading;
  final Future<void> Function() onApplyTrainingPlanReview;
  final bool usingWorkoutCache;
  final DateTime? workoutCacheTimestamp;

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
    required this.server,
    required this.apiKey,
    required this.historyLoadingMore,
    required this.onLoadMoreHistory,
    required this.historyHasMore,
    required this.trainingPlanDraft,
    required this.trainingPlanDraftLoading,
    required this.onApplyTrainingPlan,
    required this.trainingPlanReview,
    required this.trainingPlanReviewLoading,
    required this.onApplyTrainingPlanReview,
    required this.usingWorkoutCache,
    required this.workoutCacheTimestamp,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  TrainingView view = TrainingView.overview;

  @override
  Widget build(BuildContext context) {
    return _TrainingContent(
      todaysWorkouts: widget.todaysWorkouts,
      upcomingWorkouts: widget.upcomingWorkouts,
      calendarLoading: widget.calendarLoading,
      calendarError: widget.calendarError,
      onStartWorkout: widget.onStartWorkout,
      onOpenWorkout: widget.onOpenWorkout,
      trainingHistory: widget.trainingHistory,
      onLinkWorkout: widget.onLinkWorkout,
      endurainServer: widget.endurainServer,
      server: widget.server,
      apiKey: widget.apiKey,
      historyLoadingMore: widget.historyLoadingMore,
      onLoadMoreHistory: widget.onLoadMoreHistory,
      historyHasMore: widget.historyHasMore,
      trainingPlanDraft: widget.trainingPlanDraft,
      trainingPlanDraftLoading: widget.trainingPlanDraftLoading,
      onApplyTrainingPlan: widget.onApplyTrainingPlan,
      view: view,
      trainingPlanReview: widget.trainingPlanReview,
      trainingPlanReviewLoading: widget.trainingPlanReviewLoading,
      usingWorkoutCache: widget.usingWorkoutCache,
      workoutCacheTimestamp: widget.workoutCacheTimestamp,
      onViewChanged: (newView) {
        setState(() {
          view = newView;
        });
      },
      onApplyTrainingPlanReview: widget.onApplyTrainingPlanReview,
    );
  }
}

class _TrainingContent extends StatelessWidget {
  final List<ScheduledWorkout> todaysWorkouts;
  final List<ScheduledWorkout> upcomingWorkouts;
  final bool calendarLoading;
  final String? calendarError;
  final void Function(Workout) onStartWorkout;
  final void Function(ScheduledWorkout) onOpenWorkout;
  final List<TrainingHistoryEntry> trainingHistory;
  final Future<void> Function(RecentWorkoutMatch) onLinkWorkout;
  final String endurainServer;
  final String server;
  final String apiKey;
  final bool historyLoadingMore;
  final Future<void> Function() onLoadMoreHistory;
  final bool historyHasMore;
  final TrainingPlanDraft? trainingPlanDraft;
  final bool trainingPlanDraftLoading;
  final Future<void> Function() onApplyTrainingPlan;
  final TrainingView view;
  final ValueChanged<TrainingView> onViewChanged;
  final TrainingPlanReview? trainingPlanReview;
  final bool trainingPlanReviewLoading;
  final Future<void> Function() onApplyTrainingPlanReview;
  final bool usingWorkoutCache;
  final DateTime? workoutCacheTimestamp;

  const _TrainingContent({
    required this.todaysWorkouts,
    required this.upcomingWorkouts,
    required this.calendarLoading,
    required this.calendarError,
    required this.onStartWorkout,
    required this.onOpenWorkout,
    required this.trainingHistory,
    required this.onLinkWorkout,
    required this.endurainServer,
    required this.server,
    required this.apiKey,
    required this.historyLoadingMore,
    required this.onLoadMoreHistory,
    required this.historyHasMore,
    required this.trainingPlanDraft,
    required this.trainingPlanDraftLoading,
    required this.onApplyTrainingPlan,
    required this.view,
    required this.onViewChanged,
    required this.trainingPlanReview,
    required this.trainingPlanReviewLoading,
    required this.onApplyTrainingPlanReview,
    required this.usingWorkoutCache,
    required this.workoutCacheTimestamp,
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

  String _formatMonth(DateTime date) {
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

    return '${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final workoutsByMonth = <DateTime, List<ScheduledWorkout>>{};

    for (final scheduled in upcomingWorkouts) {
      final month = DateTime(scheduled.start.year, scheduled.start.month);

      workoutsByMonth.putIfAbsent(month, () => []).add(scheduled);
    }

    TrainingHistoryEntry? latestCompletedEntry;

    for (final entry in trainingHistory) {
      final match = entry.match;

      if (match != null &&
          match.scheduledWorkout.isCompleted &&
          match.linkedActivity != null) {
        latestCompletedEntry = entry;
        break;
      }
    }
    return Column(
      children: [
        const WaterHeader(height: 210),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<TrainingView>(
              segments: const [
                ButtonSegment(
                  value: TrainingView.overview,
                  icon: Icon(Icons.home_outlined),
                  label: Text('Aktuell'),
                ),
                ButtonSegment(
                  value: TrainingView.plan,
                  icon: Icon(Icons.calendar_month_outlined),
                  label: Text('Plan'),
                ),
                ButtonSegment(
                  value: TrainingView.history,
                  icon: Icon(Icons.history),
                  label: Text('Historie'),
                ),
              ],
              selected: {view},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                onViewChanged(selection.first);
              },
            ),
          ),
        ),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (view == TrainingView.overview) ...[
                      SectionTitle(
                        todaysWorkouts.isNotEmpty
                            ? 'Heute'
                            : 'Letztes Training',
                        icon: todaysWorkouts.isNotEmpty
                            ? Icons.today_outlined
                            : Icons.history_outlined,
                      ),

                      const SizedBox(height: 12),

                      if (usingWorkoutCache &&
                          workoutCacheTimestamp != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Offline · Trainingsplan zuletzt '
                                'aktualisiert um '
                                '${workoutCacheTimestamp!.hour.toString().padLeft(2, '0')}:'
                                '${workoutCacheTimestamp!.minute.toString().padLeft(2, '0')} Uhr',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                      else if (todaysWorkouts.isNotEmpty)
                        ...todaysWorkouts.map((scheduled) {
                          final workout = scheduled.workout;
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              workout.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall,
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

                                      const SizedBox(height: 6),

                                      Text(
                                        '${workout.totalDuration.inMinutes} Minuten',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),

                                      if (workout.description.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          workout.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],

                                      const SizedBox(height: 18),

                                      if (scheduled.isCompleted) ...[
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
                                              if (activity.durationMinutes !=
                                                  null)
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
                                      ] else if (scheduled.isSkipped) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.event_busy_outlined,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Training entfällt',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                          ],
                                        ),
                                      ] else
                                        Text(
                                          'Details ansehen',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
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
                        })
                      else if (latestCompletedEntry != null)
                        _LatestCompletedWorkoutCard(
                          entry: latestCompletedEntry,
                          onOpenWorkout: onOpenWorkout,
                        )
                      else
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Noch kein abgeschlossenes Training vorhanden.',
                            ),
                          ),
                        ),
                    ],
                    if (view == TrainingView.overview &&
                        trainingPlanReview != null) ...[
                      const SizedBox(height: 32),

                      const SectionTitle(
                        'Trainingscoach',
                        icon: Icons.auto_awesome_outlined,
                      ),

                      const SizedBox(height: 12),

                      _TrainingPlanReviewTile(
                        review: trainingPlanReview!,
                        onApply: onApplyTrainingPlanReview,
                      ),
                    ],
                    if (view == TrainingView.overview &&
                        trainingPlanDraft != null) ...[
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
                    if (view == TrainingView.history &&
                        trainingHistory.isNotEmpty) ...[
                      const SizedBox(height: 32),

                      const SectionTitle(
                        'Trainingshistorie',
                        icon: Icons.history,
                      ),

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
                              server: server,
                              apiKey: apiKey,
                              onLink: trainingHistory[i].match == null
                                  ? null
                                  : () => onLinkWorkout(
                                      trainingHistory[i].match!,
                                    ),
                              onOpenWorkout: onOpenWorkout,
                            ),
                          ],
                        ],
                      ),

                      if (historyHasMore) ...[
                        const SizedBox(height: 8),

                        OutlinedButton.icon(
                          onPressed: historyLoadingMore
                              ? null
                              : onLoadMoreHistory,
                          icon: historyLoadingMore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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

                    if (view == TrainingView.plan) ...[
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
                        for (final entry in workoutsByMonth.entries) ...[
                          Text(
                            _formatMonth(entry.key),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),

                          const SizedBox(height: 8),

                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < entry.value.length;
                                  i++
                                ) ...[
                                  _UpcomingWorkoutTile(
                                    scheduled: entry.value[i],
                                    formattedDate: _formatDate(
                                      entry.value[i].start,
                                    ),
                                    onTap: () => onOpenWorkout(entry.value[i]),
                                  ),

                                  if (i < entry.value.length - 1)
                                    const Divider(
                                      height: 1,
                                      indent: 18,
                                      endIndent: 18,
                                    ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
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

class _TrainingPlanReviewTile extends StatelessWidget {
  final TrainingPlanReview review;
  final Future<void> Function() onApply;

  const _TrainingPlanReviewTile({required this.review, required this.onApply});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.tertiaryContainer,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Vorschau kommt als nächster Schritt.
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TrainingPlanReviewScreen(review: review, onApply: onApply),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: colors.onTertiaryContainer,
                size: 26,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plananpassung empfohlen',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onTertiaryContainer,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${review.changes.length} '
                      '${review.changes.length == 1 ? 'Training' : 'Trainings'} '
                      'betroffen',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onTertiaryContainer),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      review.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onTertiaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              Icon(Icons.chevron_right, color: colors.onTertiaryContainer),
            ],
          ),
        ),
      ),
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
  final String server;
  final String apiKey;
  final Future<void> Function()? onLink;
  final void Function(ScheduledWorkout) onOpenWorkout;

  const _TrainingHistoryTile({
    required this.entry,
    required this.formattedDate,
    required this.endurainServer,
    required this.server,
    required this.apiKey,
    required this.onLink,
    required this.onOpenWorkout,
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
              workoutDisplayName(scheduled.workout.name),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Training konnte nicht verknüpft werden: $e')),
      );
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
            RecentWorkoutMatchStatus.missed => (
              Icons.event_busy_outlined,
              colors.errorContainer,
              colors.onErrorContainer,
            ),
            RecentWorkoutMatchStatus.skipped => (
              Icons.skip_next_outlined,
              colors.surfaceContainerHighest,
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

        case RecentWorkoutMatchStatus.missed:
          subtitle =
              '${scheduled.workout.totalDuration.inMinutes} Min. geplant · '
              'nicht absolviert';

        case RecentWorkoutMatchStatus.skipped:
          subtitle =
              '${scheduled.workout.totalDuration.inMinutes} Min. geplant · '
              'ausgesetzt';
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
              server: server,
              apiKey: apiKey,
              analysis: entry.analysis,
            ),
          ),
        );

        return;
      }

      if (match?.status == RecentWorkoutMatchStatus.linked &&
          linkedActivity != null) {
        onOpenWorkout(match!.scheduledWorkout);

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

class _LatestCompletedWorkoutCard extends StatelessWidget {
  final TrainingHistoryEntry entry;
  final void Function(ScheduledWorkout) onOpenWorkout;

  const _LatestCompletedWorkoutCard({
    required this.entry,
    required this.onOpenWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final match = entry.match;
    final activity = match?.linkedActivity;

    if (match == null || activity == null) {
      return const SizedBox.shrink();
    }

    final scheduled = match.scheduledWorkout;
    final workout = scheduled.workout;

    final date = scheduled.start;

    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          onOpenWorkout(scheduled);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workoutDisplayName(workout.name),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
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

              const SizedBox(height: 16),

              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text('${(activity.duration / 60).toStringAsFixed(1)} Min.'),
                  Text('${activity.distanceKm.toStringAsFixed(2)} km'),
                  Text('Ø ${activity.averagePower.round()} W'),
                  Text('Ø HF ${activity.averageHeartRate.round()}'),
                ],
              ),

              if (entry.analysis != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Coach-Analyse verfügbar',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final skipped = scheduled.isSkipped;
    return InkWell(
      onTap: skipped ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: skipped
                    ? colors.surfaceContainerHighest
                    : colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                skipped ? Icons.skip_next_outlined : Icons.rowing,
                color: skipped ? colors.onSurfaceVariant : colors.primary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workoutDisplayName(scheduled.workout.name),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: skipped ? colors.onSurfaceVariant : null,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$formattedDate · '
                    '${scheduled.workout.totalDuration.inMinutes} Min.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  if (skipped) ...[
                    const SizedBox(height: 5),

                    Text(
                      'Ausgesetzt',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (scheduled.planStatusReason != null) ...[
                      const SizedBox(height: 2),

                      Text(
                        scheduled.planStatusReason!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            if (!skipped) Icon(Icons.chevron_right, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
