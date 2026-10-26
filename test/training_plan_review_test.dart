import 'package:flutter_test/flutter_test.dart';

import 'package:pirowflo_control/models/training_plan_review.dart';

void main() {
  test('parst Weekly Coach Review', () {
    final review = TrainingPlanReview.fromJson({
      'status': 'pending',
      'target_month': '2026-11',
      'generated_at': '2026-10-25T19:37:50',
      'review': {
        'plan_still_suitable': true,
        'summary': 'Der Plan kann ansonsten unverändert bleiben.',
        'changes': [
          {
            'action': 'skip',
            'original_date': '2026-11-07',
            'new_date': null,
            'reason': 'Abwesenheit Hamburg/Wismar',
            'name': 'Rudern – längere Grundlage',
            'description': null,
            'warmup': '5m',
            'repeat': 1,
            'work': '40m,100-108w,16-18spm',
            'recovery': null,
            'cooldown': '5m',
          },
        ],
      },
    });

    expect(review.status, 'pending');
    expect(review.targetMonth, '2026-11');
    expect(review.planStillSuitable, isTrue);
    expect(review.changes, hasLength(1));

    final change = review.changes.first;

    expect(change.action, 'skip');
    expect(change.originalDate, DateTime(2026, 11, 7));
    expect(change.newDate, isNull);
    expect(change.name, 'Rudern – längere Grundlage');
  });
}
