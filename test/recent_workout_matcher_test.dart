import 'package:flutter_test/flutter_test.dart';

import 'package:pirowflo_control/models/api_workout.dart';
import 'package:pirowflo_control/models/endurain_activity.dart';
import 'package:pirowflo_control/models/recent_workout_match.dart';
import 'package:pirowflo_control/models/scheduled_workout.dart';
import 'package:pirowflo_control/models/workout.dart';
import 'package:pirowflo_control/services/recent_workout_matcher.dart';

void main() {
  ScheduledWorkout workout({
    DateTime? start,
    Duration duration = const Duration(minutes: 40),
    int? linkedActivityId,
    String? status,
  }) {
    final workoutStart = start ?? DateTime(2026, 10, 24);

    return ScheduledWorkout(
      id: 1,
      start: workoutStart,
      allDay: true,
      status: status ?? (linkedActivityId != null ? 'completed' : 'planned'),
      activity: linkedActivityId != null
          ? ApiWorkoutActivity(
              id: linkedActivityId,
              endurainActivityId: linkedActivityId,
              startTime: DateTime(2026, 10, 24, 18),
              durationMinutes: duration.inSeconds / 60,
              distanceKm: 8.0,
              averagePower: 130,
              normalizedPower: 135,
              averageHr: 130,
              maxHr: 155,
              averageSpm: 18,
              linkStatus: 'confirmed',
            )
          : null,
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
      final scheduled = workout(linkedActivityId: 1053);

      final linkedActivity = activity(id: 1053);

      final result = RecentWorkoutMatcher.resolve(
        [scheduled],
        [linkedActivity],
      );

      expect(result, hasLength(1));

      expect(result.first.status, RecentWorkoutMatchStatus.linked);

      expect(result.first.linkedActivity?.id, 1053);

      expect(result.first.candidate, isNull);
    });

    test('vergibt eine Endurain-Aktivität nur einmal', () {
      final firstWorkout = workout(duration: const Duration(minutes: 30));

      final secondWorkout = workout(duration: const Duration(minutes: 40));

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

      expect(
        matched.scheduledWorkout.workout.totalDuration,
        const Duration(minutes: 40),
      );

      expect(matched.candidate!.activity.id, 1053);
    });

    test('verwendet bereits verknüpfte '
        'Aktivität nicht erneut', () {
      final linkedWorkout = workout(linkedActivityId: 1053);

      final openWorkout = workout();

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

    test('findet Kandidaten für noch nicht '
        'verknüpftes Training', () {
      final scheduled = workout();

      final candidate = activity(
        id: 1053,
        duration: const Duration(minutes: 42),
      );

      final result = RecentWorkoutMatcher.resolve([scheduled], [candidate]);

      expect(result, hasLength(1));

      expect(result.first.status, RecentWorkoutMatchStatus.candidate);

      expect(result.first.linkedActivity, isNull);

      expect(result.first.candidate?.activity.id, 1053);
    });

    test('wartet wenn noch keine '
        'Endurain-Aktivität vorhanden ist', () {
      final scheduled = workout();

      final result = RecentWorkoutMatcher.resolve([scheduled], []);

      expect(result, hasLength(1));

      expect(result.first.status, RecentWorkoutMatchStatus.waiting);

      expect(result.first.linkedActivity, isNull);

      expect(result.first.candidate, isNull);
    });

    test('behandelt verpasstes Training als missed', () {
      final scheduled = workout(status: 'missed');

      final result = RecentWorkoutMatcher.resolve([scheduled], []);

      expect(result, hasLength(1));
      expect(result.first.status, RecentWorkoutMatchStatus.missed);
      expect(result.first.candidate, isNull);
      expect(result.first.linkedActivity, isNull);
    });

    test('ordnet missed Training keine Aktivität mehr zu', () {
      final scheduled = workout(status: 'missed');

      final candidateActivity = activity(
        id: 1053,
        start: DateTime(2026, 10, 24, 18),
      );

      final result = RecentWorkoutMatcher.resolve(
        [scheduled],
        [candidateActivity],
      );

      expect(result, hasLength(1));
      expect(result.first.status, RecentWorkoutMatchStatus.missed);
      expect(result.first.candidate, isNull);
    });

    test('behandelt bewusst ausgesetztes Training als skipped', () {
      final scheduled = workout(status: 'skipped');

      final result = RecentWorkoutMatcher.resolve([scheduled], []);

      expect(result, hasLength(1));
      expect(result.first.status, RecentWorkoutMatchStatus.skipped);
      expect(result.first.candidate, isNull);
    });
  });
}
