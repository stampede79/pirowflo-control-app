import 'package:flutter_test/flutter_test.dart';

import 'package:pirowflo_control/models/calendar_event.dart';
import 'package:pirowflo_control/models/endurain_activity.dart';
import 'package:pirowflo_control/models/recent_workout_match.dart';
import 'package:pirowflo_control/models/scheduled_workout.dart';
import 'package:pirowflo_control/models/training_history_entry.dart';
import 'package:pirowflo_control/models/workout.dart';
import 'package:pirowflo_control/services/training_history_merger.dart';

void main() {
  ScheduledWorkout workout({
    required String description,
    DateTime? start,
    Duration duration = const Duration(minutes: 40),
  }) {
    final workoutStart = start ?? DateTime(2026, 10, 24);

    return ScheduledWorkout(
      start: workoutStart,
      workout: Workout(
        name: 'Rudern – Test',
        description: 'Geplantes Training',
        steps: [
          WorkoutStep(
            type: WorkoutStepType.work,
            title: 'Hauptteil',
            duration: duration,
          ),
        ],
      ),
      calendarEvent: CalendarEvent(
        summary: 'Rudern – Test',
        description: description,
        start: workoutStart,
        allDay: true,
        href: '/test.ics',
        etag: '"test-etag"',
        uid: 'test-uid',
        rawIcs: 'BEGIN:VCALENDAR\nEND:VCALENDAR',
      ),
    );
  }

  EndurainActivity activity({
    required int id,
    DateTime? start,
    Duration duration = const Duration(minutes: 40),
  }) {
    return EndurainActivity(
      id: id,
      name: 'Indoor-Rudern',
      activityType: 13,
      startTime: start ?? DateTime(2026, 10, 24, 18),
      distance: 8000,
      duration: duration.inSeconds.toDouble(),
      averagePower: 130,
      maxPower: 180,
      averageHeartRate: 130,
      maxHeartRate: 155,
      averageCadence: 18,
      maxCadence: 24,
      calories: 300,
      normalizedPower: 135,
      totalCycles: 700,
    );
  }

  group('TrainingHistoryMerger', () {
    test('zeigt verknüpfte Aktivität nicht zusätzlich als freies Training', () {
      final scheduled = workout(
        description: '''
[PIROWFLO]
work=40m,120-130w
[/PIROWFLO]

[PIROWFLO_RESULT]
endurain_activity_id=1053
linked_at=2026-10-24T21:30:00+02:00
[/PIROWFLO_RESULT]
''',
      );

      final linkedActivity = activity(id: 1053);

      final result = TrainingHistoryMerger.merge([scheduled], [linkedActivity]);

      expect(result, hasLength(1));

      expect(result.first.type, TrainingHistoryEntryType.planned);

      expect(result.first.match?.status, RecentWorkoutMatchStatus.linked);

      expect(result.first.match?.linkedActivity?.id, 1053);
    });

    test('zeigt unverplante Endurain-Aktivität als freies Training', () {
      final freeActivity = activity(
        id: 1060,
        start: DateTime(2026, 10, 23, 18),
      );

      final result = TrainingHistoryMerger.merge([], [freeActivity]);

      expect(result, hasLength(1));

      expect(result.first.type, TrainingHistoryEntryType.free);

      expect(result.first.activity?.id, 1060);
      expect(result.first.match?.scheduledWorkout, isNull);
      expect(result.first.match?.status, isNull);
    });

    test('mischt geplante und freie Trainings chronologisch', () {
      final linkedWorkout = workout(
        start: DateTime(2026, 10, 24),
        description: '''
[PIROWFLO]
work=40m,120-130w
[/PIROWFLO]

[PIROWFLO_RESULT]
endurain_activity_id=1053
linked_at=2026-10-24T21:30:00+02:00
[/PIROWFLO_RESULT]
''',
      );

      final linkedActivity = activity(
        id: 1053,
        start: DateTime(2026, 10, 24, 18),
      );

      final freeActivity = activity(
        id: 1060,
        start: DateTime(2026, 10, 23, 19),
      );

      final waitingWorkout = workout(
        start: DateTime(2026, 10, 22),
        description: '''
[PIROWFLO]
work=50m,105-110w
[/PIROWFLO]
''',
        duration: const Duration(minutes: 50),
      );

      final result = TrainingHistoryMerger.merge(
        [waitingWorkout, linkedWorkout],
        [freeActivity, linkedActivity],
      );

      expect(result, hasLength(3));

      expect(result[0].match?.status, RecentWorkoutMatchStatus.linked);
      expect(result[0].match?.linkedActivity?.id, 1053);

      expect(result[1].type, TrainingHistoryEntryType.free);
      expect(result[1].activity?.id, 1060);

      expect(result[2].match?.status, RecentWorkoutMatchStatus.waiting);
      expect(result[2].activity, isNull);
    });

    test('Kandidat erscheint nicht zusätzlich als freies Training', () {
      final scheduled = workout(
        start: DateTime(2026, 10, 24),
        description: '''
[PIROWFLO]
work=40m,120-130w
[/PIROWFLO]
''',
      );

      final candidateActivity = activity(
        id: 1053,
        start: DateTime(2026, 10, 24, 18),
        duration: const Duration(minutes: 41),
      );

      final result = TrainingHistoryMerger.merge(
        [scheduled],
        [candidateActivity],
      );

      expect(result, hasLength(1));

      expect(result.first.type, TrainingHistoryEntryType.planned);

      expect(result.first.match?.status, RecentWorkoutMatchStatus.candidate);

      expect(result.first.match?.candidate?.activity.id, 1053);
    });
  });
}
