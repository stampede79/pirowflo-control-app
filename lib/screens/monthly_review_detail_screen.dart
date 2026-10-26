import 'package:flutter/material.dart';

import '../models/coach_overview.dart';

class MonthlyReviewDetailScreen extends StatelessWidget {
  final CoachMonthlyReview review;

  const MonthlyReviewDetailScreen({super.key, required this.review});

  String _monthName(int month) {
    const names = [
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

    return names[month - 1];
  }

  String _assessment(String? value) {
    return switch (value) {
      'good' => 'Gut',
      'mixed' => 'Gemischt',
      'concerning' => 'Auffällig',
      _ => 'Unklar',
    };
  }

  String _trend(String? value) {
    return switch (value) {
      'improving' => 'Verbessert',
      'stable' => 'Stabil',
      'declining' => 'Rückläufig',
      _ => 'Unklar',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monatsbericht')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            '${_monthName(review.month)} '
            '${review.year}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(_assessment(review.assessment))),
              Chip(
                label: Text(
                  'Trend: '
                  '${_trend(review.trend)}',
                ),
              ),
              Chip(
                label: Text(
                  'Belastung: '
                  '${_load(review.loadAssessment)}',
                ),
              ),
              Chip(
                label: Text(
                  'Regeneration: '
                  '${_recovery(review.recoveryAssessment)}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          _TextSection(title: 'Zusammenfassung', text: review.summary),

          if (review.strengths.isNotEmpty)
            _ListSection(title: 'Stärken', items: review.strengths),

          if (review.focusAreas.isNotEmpty)
            _ListSection(title: 'Schwerpunkte', items: review.focusAreas),

          if (review.keyObservations.isNotEmpty)
            _ListSection(title: 'Beobachtungen', items: review.keyObservations),

          if (review.recommendation.isNotEmpty)
            _TextSection(title: 'Empfehlung', text: review.recommendation),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  final String title;
  final String text;

  const _TextSection({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(text),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ListSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
