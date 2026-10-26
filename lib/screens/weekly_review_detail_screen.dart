import 'package:flutter/material.dart';

import '../models/coach_overview.dart';

class WeeklyReviewDetailScreen extends StatelessWidget {
  final CoachWeeklyReview review;

  const WeeklyReviewDetailScreen({super.key, required this.review});

  String _assessment(String value) {
    return switch (value) {
      'good' => 'Gute Woche',
      'mixed' => 'Gemischte Woche',
      'concerning' => 'Auffällige Woche',
      _ => 'Nicht bewertet',
    };
  }

  String _trend(String value) {
    return switch (value) {
      'improving' => 'Verbessernd',
      'stable' => 'Stabil',
      'declining' => 'Rückläufig',
      'unclear' => 'Noch unklar',
      _ => 'Unklar',
    };
  }

  String _load(String value) {
    return switch (value) {
      'low' => 'Niedrig',
      'appropriate' => 'Angemessen',
      'high' => 'Hoch',
      _ => 'Unklar',
    };
  }

  String _recovery(String value) {
    return switch (value) {
      'good' => 'Gut',
      'watch' => 'Beobachten',
      'concerning' => 'Auffällig',
      _ => 'Unklar',
    };
  }

  String _consistency(String value) {
    return switch (value) {
      'good' => 'Gut',
      'mixed' => 'Gemischt',
      'poor' => 'Schwach',
      _ => 'Unklar',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KW ${review.isoWeek} · ${review.year}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              _assessment(review.assessment),
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: Icons.trending_up,
                  label: 'Trend: ${_trend(review.trend)}',
                ),
                _MetricChip(
                  icon: Icons.monitor_heart_outlined,
                  label:
                      'Belastung: '
                      '${_load(review.loadAssessment)}',
                ),
                _MetricChip(
                  icon: Icons.bedtime_outlined,
                  label:
                      'Regeneration: '
                      '${_recovery(review.recoveryAssessment)}',
                ),
                _MetricChip(
                  icon: Icons.balance_outlined,
                  label:
                      'Konsistenz: '
                      '${_consistency(review.consistency)}',
                ),
              ],
            ),

            const SizedBox(height: 28),

            const _SectionTitle(
              icon: Icons.summarize_outlined,
              title: 'Wochenfazit',
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  review.summary,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),

            if (review.keyObservations.isNotEmpty) ...[
              const SizedBox(height: 28),

              const _SectionTitle(
                icon: Icons.visibility_outlined,
                title: 'Beobachtungen',
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      for (
                        var i = 0;
                        i < review.keyObservations.length;
                        i++
                      ) ...[
                        _Observation(text: review.keyObservations[i]),
                        if (i < review.keyObservations.length - 1)
                          const Divider(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            if (review.recommendation.isNotEmpty) ...[
              const SizedBox(height: 28),

              const _SectionTitle(
                icon: Icons.auto_awesome,
                title: 'Empfehlung',
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          review.recommendation,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
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
          padding: const EdgeInsets.only(top: 6),
          child: Icon(
            Icons.circle,
            size: 7,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
