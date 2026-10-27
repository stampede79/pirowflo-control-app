import 'package:flutter_test/flutter_test.dart';

import 'package:pirowflo_control/models/api_workout.dart';
import 'package:pirowflo_control/models/endurain_activity.dart';
import 'package:pirowflo_control/models/recent_workout_match.dart';
import 'package:pirowflo_control/models/scheduled_workout.dart';
import 'package:pirowflo_control/models/training_history_entry.dart';
import 'package:pirowflo_control/models/workout.dart';
import 'package:pirowflo_control/services/training_history_merger.dart';

void main() {
  ScheduledWorkout workout({
    DateTime? start,
    Duration duration = const Duration(minutes: 40),
    int? linkedActivityId,
  }) {
    final workoutStart = start ?? DateTime(2026, 10, 24);

    return ScheduledWorkout(
      id: 1,
      start: workoutStart,
      allDay: true,
      status: linkedActivityId != null ? 'completed' : 'planned',
      activity: linkedActivityId != null
          ? ApiWorkoutActivity(
              id: linkedActivityId,
              endurainActivityId: linkedActivityId,
              startTime: workoutStart,
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

  group('TrainingHistoryMerger', () {
    test('zeigt verknüpfte Aktivität nicht '
        'zusätzlich als freies Training', () {
      final scheduled = workout(linkedActivityId: 1053);

      final linkedActivity = activity(id: 1053);

      final result = TrainingHistoryMerger.merge([scheduled], [linkedActivity]);

      expect(result, hasLength(1));

      expect(result.first.type, TrainingHistoryEntryType.planned);

      expect(result.first.match?.status, RecentWorkoutMatchStatus.linked);

      expect(result.first.match?.linkedActivity?.id, 1053);
    });

    test('zeigt unverplante Endurain-Aktivität '
        'als freies Training', () {
      final freeActivity = activity(
        id: 1060,
        start: DateTime(2026, 10, 23, 18),
      );

      final result = TrainingHistoryMerger.merge([], [freeActivity]);

      expect(result, hasLength(1));

      expect(result.first.type, TrainingHistoryEntryType.free);

      expect(result.first.activity?.id, 1060);

      expect(result.first.match, isNull);
    });

    test('mischt geplante und freie '
        'Trainings chronologisch', () {
      final linkedWorkout = workout(
        start: DateTime(2026, 10, 24),
        linkedActivityId: 1053,
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

    test('Kandidat erscheint nicht zusätzlich '
        'als freies Training', () {
      final scheduled = workout(start: DateTime(2026, 10, 24));

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
