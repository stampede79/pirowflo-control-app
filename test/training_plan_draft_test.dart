import 'package:flutter_test/flutter_test.dart';

import 'package:pirowflo_control/models/training_plan_draft.dart';

void main() {
  test('parst Monthly Training Plan Draft', () {
    final draft = TrainingPlanDraft.fromJson({
      'status': 'draft',
      'generated_at': '2026-10-25T14:53:09',
      'target_month': '2026-11',
      'sessions_per_week': 3,
      'model': 'gpt-6-luna',
      'workouts': [
        {
          'date': '2026-11-03',
          'name': 'Rudern – Grundlage',
          'description': 'Ruhige Einheit.',
          'warmup': '5m',
          'repeat': 1,
          'work': '35m,100-108w,16-18spm',
          'recovery': null,
          'cooldown': '5m',
        },
      ],
    });

    expect(draft.status, 'draft');
    expect(draft.targetMonth, '2026-11');
    expect(draft.sessionsPerWeek, 3);
    expect(draft.model, 'gpt-6-luna');
    expect(draft.workouts, hasLength(1));

    final workout = draft.workouts.first;

    expect(workout.date, DateTime(2026, 11, 3));
    expect(workout.name, 'Rudern – Grundlage');
    expect(workout.repeat, 1);
    expect(workout.work, '35m,100-108w,16-18spm');
    expect(workout.recovery, isNull);
  });
}
