import 'package:flutter_test/flutter_test.dart';

import 'package:pirowflo_control/models/calendar_event.dart';
import 'package:pirowflo_control/models/endurain_activity.dart';
import 'package:pirowflo_control/models/recent_workout_match.dart';
import 'package:pirowflo_control/models/scheduled_workout.dart';
import 'package:pirowflo_control/models/workout.dart';
import 'package:pirowflo_control/services/recent_workout_matcher.dart';

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

  group('RecentWorkoutMatcher', () {
    test('erkennt bereits verknüpftes Training', () {
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

      final result = RecentWorkoutMatcher.resolve(
        [scheduled],
        [linkedActivity],
      );

      expect(result, hasLength(1));
      expect(result.first.status, RecentWorkoutMatchStatus.linked);
      expect(result.first.result, isNotNull);
      expect(result.first.result!.endurainActivityId, 1053);
      expect(result.first.linkedActivity?.id, 1053);
      expect(result.first.candidate, isNull);
    });

    test('vergibt eine Endurain-Aktivität nur einmal', () {
      final firstWorkout = workout(
        description: '''
[PIROWFLO]
work=30m,100-110w
[/PIROWFLO]
''',
        duration: const Duration(minutes: 30),
      );

      final secondWorkout = workout(
        description: '''
[PIROWFLO]
work=40m,120-130w
[/PIROWFLO]
''',
        duration: const Duration(minutes: 40),
      );

      final candidate = activity(
        id: 1053,
        duration: const Duration(minutes: 39),
      );

      final result = RecentWorkoutMatcher.resolve(
        [firstWorkout, secondWorkout],
        [candidate],
      );

      expect(result, hasLength(2));

      expect(
        result.where(
          (match) => match.status == RecentWorkoutMatchStatus.candidate,
        ),
        hasLength(1),
      );

      expect(
        result.where(
          (match) => match.status == RecentWorkoutMatchStatus.waiting,
        ),
        hasLength(1),
      );

      final matched = result.firstWhere(
        (match) => match.status == RecentWorkoutMatchStatus.candidate,
      );

      // 39 Minuten passen besser zum geplanten 40-Minuten-Training.
      expect(
        matched.scheduledWorkout.workout.totalDuration,
        const Duration(minutes: 40),
      );

      expect(matched.candidate!.activity.id, 1053);
    });

    test('verwendet bereits verknüpfte Aktivität nicht erneut', () {
      final linkedWorkout = workout(
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

      final openWorkout = workout(
        description: '''
[PIROWFLO]
work=40m,120-130w
[/PIROWFLO]
''',
      );

      final linkedActivity = activity(id: 1053);

      final result = RecentWorkoutMatcher.resolve(
        [linkedWorkout, openWorkout],
        [linkedActivity],
      );

      expect(result[0].status, RecentWorkoutMatchStatus.linked);
      expect(result[0].linkedActivity?.id, 1053);

      expect(result[1].status, RecentWorkoutMatchStatus.waiting);
      expect(result[1].candidate, isNull);
    });

    test('findet Kandidaten für noch nicht verknüpftes Training', () {
      final scheduled = workout(
        description: '''
[PIROWFLO]
work=40m,120-130w
[/PIROWFLO]
''',
      );

      final candidate = activity(
        id: 1053,
        duration: const Duration(minutes: 42),
      );

      final result = RecentWorkoutMatcher.resolve([scheduled], [candidate]);

      expect(result, hasLength(1));
      expect(result.first.status, RecentWorkoutMatchStatus.candidate);
      expect(result.first.result, isNull);
      expect(result.first.linkedActivity, isNull);
      expect(result.first.candidate?.activity.id, 1053);
    });

    test('wartet wenn noch keine Endurain-Aktivität vorhanden ist', () {
      final scheduled = workout(
        description: '''
[PIROWFLO]
work=40m,120-130w
[/PIROWFLO]
''',
      );

      final result = RecentWorkoutMatcher.resolve([scheduled], []);

      expect(result, hasLength(1));
      expect(result.first.status, RecentWorkoutMatchStatus.waiting);
      expect(result.first.result, isNull);
      expect(result.first.linkedActivity, isNull);
      expect(result.first.candidate, isNull);
    });
  });
}
