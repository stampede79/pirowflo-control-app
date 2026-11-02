import 'package:flutter/material.dart';

import '../models/coach_overview.dart';
import '../widgets/water_header.dart';
import '../widgets/section_title.dart';
import '../utils/workout_display.dart';

enum CoachView { current, week, month }

class CoachScreen extends StatefulWidget {
  final CoachOverview? overview;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  final Future<void> Function(int recommendationId, String status)
  onAnswerAvailability;

  final Future<void> Function(int recommendationId, String decision)
  onDecideRecommendation;

  const CoachScreen({
    super.key,
    required this.overview,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onAnswerAvailability,
    required this.onDecideRecommendation,
  });

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  CoachView view = CoachView.current;

  String _monthLabel(int month, int year) {
    const months = [
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

    if (month < 1 || month > 12) {
      return '$month/$year';
    }

    return '${months[month - 1]} $year';
  }

  String _trend(String? value) {
    return switch (value) {
      'improving' => 'Verbessernd',
      'stable' => 'Stabil',
      'declining' => 'Rückläufig',
      'unclear' => 'Noch unklar',
      _ => 'Unklar',
    };
  }

  String _consistency(String? value) {
    return switch (value) {
      'good' => 'Gut',
      'mixed' => 'Gemischt',
      'poor' => 'Schwach',
      _ => 'Unklar',
    };
  }

  String _progression(String? value) {
    return switch (value) {
      'positive' => 'Positiv',
      'stable' => 'Stabil',
      'concerning' => 'Auffällig',
      'unclear' => 'Noch unklar',
      _ => 'Unklar',
    };
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _weeklyAssessment(String? value) {
    return switch (value) {
      'good' => 'Gute Woche',
      'mixed' => 'Gemischte Woche',
      'concerning' => 'Auffällige Woche',
      _ => 'Noch keine Bewertung',
    };
  }

  String _monthlyAssessment(String? value) {
    return switch (value) {
      'good' => 'Guter Monat',
      'mixed' => 'Gemischter Monat',
      'concerning' => 'Auffälliger Monat',
      _ => 'Noch keine Bewertung',
    };
  }

  String _execution(String value) {
    return switch (value) {
      'good' => 'Gut ausgeführt',
      'partial' => 'Teilweise erfüllt',
      'poor' => 'Nicht wie geplant',
      _ => 'Nicht bewertet',
    };
  }

  String _load(String? value) {
    return switch (value) {
      'low' => 'Niedrig',
      'appropriate' => 'Angemessen',
      'high' => 'Hoch',
      _ => 'Unklar',
    };
  }

  String _recovery(String? value) {
    return switch (value) {
      'good' => 'Gut',
      'watch' => 'Beobachten',
      'concerning' => 'Auffällig',
      _ => 'Unklar',
    };
  }

  String _effort(String value) {
    return switch (value) {
      'easy' => 'Locker',
      'moderate' => 'Moderat',
      'hard' => 'Hart',
      _ => 'Unklar',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.overview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.error != null && widget.overview == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'Coach-Daten konnten nicht '
                    'geladen werden.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final weekly = widget.overview?.weeklyReview;
    final workout = widget.overview?.latestWorkoutAnalysis;
    final monthly = widget.overview?.monthlyReview;

    final actionableRecommendations =
        widget.overview?.pendingRecommendations
            .where(
              (recommendation) =>
                  recommendation.type == 'availability_conflict' ||
                  recommendation.type == 'workout_replanning',
            )
            .toList() ??
        const <CoachRecommendation>[];

    final hasCurrentContent =
        workout != null ||
        (widget.overview?.pendingRecommendations.isNotEmpty ?? false);

    final showEmptyState = switch (view) {
      CoachView.current => !hasCurrentContent,
      CoachView.week => weekly == null,
      CoachView.month => monthly == null,
    };

    return Column(
      children: [
        const WaterHeader(
          height: 210,
          title: 'Dein Coach',
          subtitle: 'Analyse, Entwicklung und Trainingssteuerung',
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<CoachView>(
              segments: const [
                ButtonSegment(
                  value: CoachView.current,
                  icon: Icon(Icons.auto_awesome_outlined),
                  label: Text('Aktuell'),
                ),
                ButtonSegment(
                  value: CoachView.week,
                  icon: Icon(Icons.calendar_view_week_outlined),
                  label: Text('Woche'),
                ),
                ButtonSegment(
                  value: CoachView.month,
                  icon: Icon(Icons.calendar_month_outlined),
                  label: Text('Monat'),
                ),
              ],
              selected: {view},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() {
                  view = selection.first;
                });
              },
            ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                if (widget.loading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],

                const SizedBox(height: 28),

                if (view == CoachView.current &&
                    actionableRecommendations.isNotEmpty) ...[
                  const SizedBox(height: 28),

                  SectionTitle(
                    'Deine Entscheidung',
                    icon: Icons.event_available_outlined,
                  ),

                  const SizedBox(height: 12),

                  for (final recommendation in actionableRecommendations) ...[
                    if (recommendation.type == 'availability_conflict')
                      _AvailabilityQuestion(
                        recommendation: recommendation,
                        onAnswer: widget.onAnswerAvailability,
                      )
                    else if (recommendation.type == 'workout_replanning')
                      _ReplanningQuestion(
                        recommendation: recommendation,
                        onDecision: widget.onDecideRecommendation,
                      ),

                    const SizedBox(height: 12),
                  ],
                ],

                if (view == CoachView.week && weekly != null) ...[
                  SectionTitle(
                    'KW ${weekly.isoWeek}',
                    icon: Icons.calendar_view_week_outlined,
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusChip(
                                label: _weeklyAssessment(weekly.assessment),
                                icon: Icons.auto_awesome,
                              ),
                              _StatusChip(
                                label:
                                    'Trend: '
                                    '${_trend(weekly.trend)}',
                                icon: Icons.trending_up,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _CoachMetric(
                                  label: 'Belastung',
                                  value: _load(weekly.loadAssessment),
                                  icon: Icons.monitor_heart_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CoachMetric(
                                  label: 'Regeneration',
                                  value: _recovery(weekly.recoveryAssessment),
                                  icon: Icons.bedtime_outlined,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _CoachMetric(
                            label: 'Konsistenz',
                            value: _consistency(weekly.consistency),
                            icon: Icons.balance_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (weekly.summary.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    const SectionTitle(
                      'Wochenfazit',
                      icon: Icons.summarize_outlined,
                    ),

                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          weekly.summary,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],

                  if (weekly.keyObservations.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    const SectionTitle(
                      'Beobachtungen',
                      icon: Icons.visibility_outlined,
                    ),

                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            for (
                              var i = 0;
                              i < weekly.keyObservations.length;
                              i++
                            ) ...[
                              _Observation(text: weekly.keyObservations[i]),
                              if (i < weekly.keyObservations.length - 1)
                                const Divider(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (weekly.recommendation.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    const SectionTitle(
                      'Coach-Empfehlung',
                      icon: Icons.lightbulb_outline,
                    ),

                    const SizedBox(height: 12),

                    _CoachHint(text: weekly.recommendation),
                  ],
                ],

                if (view == CoachView.month && monthly != null) ...[
                  SectionTitle(
                    _monthLabel(monthly.month, monthly.year),
                    icon: Icons.calendar_month_outlined,
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusChip(
                                label: _monthlyAssessment(monthly.assessment),
                                icon: Icons.auto_awesome,
                              ),
                              _StatusChip(
                                label:
                                    'Trend: '
                                    '${_trend(monthly.trend)}',
                                icon: Icons.trending_up,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _CoachMetric(
                                  label: 'Belastung',
                                  value: _load(monthly.loadAssessment),
                                  icon: Icons.monitor_heart_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CoachMetric(
                                  label: 'Regeneration',
                                  value: _recovery(monthly.recoveryAssessment),
                                  icon: Icons.bedtime_outlined,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _CoachMetric(
                                  label: 'Konsistenz',
                                  value: _consistency(monthly.consistency),
                                  icon: Icons.balance_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CoachMetric(
                                  label: 'Entwicklung',
                                  value: _progression(monthly.progression),
                                  icon: Icons.show_chart_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (monthly.summary.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    const SectionTitle(
                      'Monatsfazit',
                      icon: Icons.summarize_outlined,
                    ),

                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          monthly.summary,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],

                  if (monthly.keyObservations.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    const SectionTitle(
                      'Entwicklungen',
                      icon: Icons.insights_outlined,
                    ),

                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            for (
                              var i = 0;
                              i < monthly.keyObservations.length;
                              i++
                            ) ...[
                              _Observation(text: monthly.keyObservations[i]),
                              if (i < monthly.keyObservations.length - 1)
                                const Divider(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (monthly.strengths.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    const SectionTitle(
                      'Stärken',
                      icon: Icons.check_circle_outline,
                    ),

                    const SizedBox(height: 12),

                    _CoachListCard(items: monthly.strengths, icon: Icons.check),
                  ],

                  if (monthly.focusAreas.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    const SectionTitle(
                      'Fokus',
                      icon: Icons.center_focus_strong,
                    ),

                    const SizedBox(height: 12),

                    _CoachListCard(
                      items: monthly.focusAreas,
                      icon: Icons.arrow_forward,
                    ),
                  ],

                  if (monthly.recommendation.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    const SectionTitle(
                      'Empfehlung',
                      icon: Icons.lightbulb_outline,
                    ),

                    const SizedBox(height: 12),

                    _CoachHint(text: monthly.recommendation),
                  ],
                ],

                if (view == CoachView.current && workout != null) ...[
                  const SizedBox(height: 28),

                  SectionTitle('Letztes Training', icon: Icons.rowing),

                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workoutDisplayName(workout.name),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _date(workout.date),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),

                          const SizedBox(height: 16),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusChip(
                                label: _execution(workout.execution),
                                icon: Icons.check_circle_outline,
                              ),
                              _StatusChip(
                                label:
                                    'Belastung: '
                                    '${_load(workout.loadAssessment)}',
                                icon: Icons.monitor_heart_outlined,
                              ),
                              _StatusChip(
                                label:
                                    'Intensität: '
                                    '${_effort(workout.effort)}',
                                icon: Icons.speed_outlined,
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Text(
                            workout.summary,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),

                          if (workout.recommendation.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _CoachHint(text: workout.recommendation),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                if (showEmptyState) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Noch keine Coach-Auswertungen '
                        'vorhanden.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoachMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CoachMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailabilityQuestion extends StatefulWidget {
  final CoachRecommendation recommendation;

  final Future<void> Function(int recommendationId, String status) onAnswer;

  const _AvailabilityQuestion({
    required this.recommendation,
    required this.onAnswer,
  });

  @override
  State<_AvailabilityQuestion> createState() => _AvailabilityQuestionState();
}

class _AvailabilityQuestionState extends State<_AvailabilityQuestion> {
  bool saving = false;

  Future<void> _answer(String status) async {
    setState(() {
      saving = true;
    });

    try {
      await widget.onAnswer(widget.recommendation.id, status);
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.recommendation.payload;

    final workoutName = payload['workout_name']?.toString().replaceFirst(
      RegExp(r'^Rudern\s*[–-]\s*'),
      '',
    );

    final event = payload['event_summary']?.toString() ?? 'Kalendereintrag';

    final rawDate = payload['workout_date']?.toString();

    final date = rawDate != null ? DateTime.tryParse(rawDate) : null;

    final dateText = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}.'
              '${date.month.toString().padLeft(2, '0')}.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$workoutName · $dateText',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            Text(
              'In deinem Kalender steht '
              '„$event“. Kannst du das '
              'Training an diesem Tag '
              'durchführen?',
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: saving ? null : () => _answer('available'),
                  child: const Text('Ja'),
                ),
                OutlinedButton(
                  onPressed: saving ? null : () => _answer('limited'),
                  child: const Text('Eingeschränkt'),
                ),
                OutlinedButton(
                  onPressed: saving ? null : () => _answer('unavailable'),
                  child: const Text('Nein'),
                ),
              ],
            ),

            if (saving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachListCard extends StatelessWidget {
  final List<String> items;
  final IconData icon;

  const _CoachListCard({required this.items, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[i],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              if (i < items.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _Observation extends StatelessWidget {
  final String text;

  const _Observation({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            Icons.circle,
            size: 8,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _ReplanningQuestion extends StatefulWidget {
  final CoachRecommendation recommendation;

  final Future<void> Function(int recommendationId, String decision) onDecision;

  const _ReplanningQuestion({
    required this.recommendation,
    required this.onDecision,
  });

  @override
  State<_ReplanningQuestion> createState() => _ReplanningQuestionState();
}

class _ReplanningQuestionState extends State<_ReplanningQuestion> {
  bool saving = false;

  Future<void> _decide(String decision) async {
    setState(() {
      saving = true;
    });

    try {
      await widget.onDecision(widget.recommendation.id, decision);
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  String _date(String? value) {
    if (value == null) {
      return '--';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.';
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.recommendation.payload;

    final name =
        payload['workout_name']?.toString().replaceFirst(
          RegExp(r'^Rudern\s*[–-]\s*'),
          '',
        ) ??
        'Training';

    final original = _date(payload['original_date']?.toString());

    final target = _date(payload['target_date']?.toString());

    final before = payload['days_after_previous'];

    final after = payload['days_before_following'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_repeat_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Planänderung vorgeschlagen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(name, style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 8),

            Text(
              '$original → $target',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            if (before != null && after != null) ...[
              const SizedBox(height: 12),
              Text(
                'Damit bleiben $before Tage '
                'Abstand zur vorherigen und '
                '$after Tage zur nächsten '
                'Trainingseinheit.',
              ),
            ],

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: saving ? null : () => _decide('accept'),
                  icon: const Icon(Icons.check),
                  label: const Text('Übernehmen'),
                ),
                OutlinedButton(
                  onPressed: saving ? null : () => _decide('reject'),
                  child: const Text('Ablehnen'),
                ),
              ],
            ),

            if (saving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoachHint extends StatelessWidget {
  final String text;

  const _CoachHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
