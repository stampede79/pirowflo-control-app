import '../models/endurain_activity.dart';
import '../models/recent_workout_match.dart';
import '../models/scheduled_workout.dart';
import 'workout_activity_matcher.dart';

class RecentWorkoutMatcher {
  static List<RecentWorkoutMatch> resolve(
    List<ScheduledWorkout> workouts,
    List<EndurainActivity> activities,
  ) {
    final resolved = <ScheduledWorkout, RecentWorkoutMatch>{};
    final usedActivityIds = <int>{};

    // Bereits bestehende Verknüpfungen haben immer Vorrang.
    // Bereits in SQLite bestehende Verknüpfungen
    // haben immer Vorrang.
    for (final workout in workouts) {
      final linked = workout.activity;

      if (linked == null) {
        continue;
      }

      EndurainActivity? linkedActivity;

      for (final activity in activities) {
        if (activity.id == linked.endurainActivityId) {
          linkedActivity = activity;
          break;
        }
      }

      usedActivityIds.add(linked.endurainActivityId);

      resolved[workout] = RecentWorkoutMatch(
        scheduledWorkout: workout,
        isLinked: true,
        linkedActivity: linkedActivity,
      );
    }

    final openWorkouts = workouts
        .where(
          (workout) =>
              !resolved.containsKey(workout) &&
              !workout.isSkipped &&
              !workout.isCompleted,
        )
        .toList();
    for (final workout in workouts) {
      if (resolved.containsKey(workout)) {
        continue;
      }

      if (workout.isSkipped) {
        resolved[workout] = RecentWorkoutMatch(scheduledWorkout: workout);
      }
    }

    final availableActivities = activities
        .where((activity) => !usedActivityIds.contains(activity.id))
        .toList();

    // Alle möglichen Workout/Activity-Kombinationen sammeln.
    final candidates = <_CandidatePair>[];

    for (final workout in openWorkouts) {
      for (final activity in availableActivities) {
        final match = WorkoutActivityMatcher.findBestMatch(workout, [activity]);

        if (match != null) {
          candidates.add(_CandidatePair(workout: workout, match: match));
        }
      }
    }

    // Die plausibelsten Kombinationen zuerst vergeben.
    candidates.sort((a, b) => b.match.score.compareTo(a.match.score));

    final matchedWorkouts = <ScheduledWorkout>{};
    final matchedActivityIds = <int>{};

    for (final pair in candidates) {
      if (matchedWorkouts.contains(pair.workout) ||
          matchedActivityIds.contains(pair.match.activity.id)) {
        continue;
      }

      resolved[pair.workout] = RecentWorkoutMatch(
        scheduledWorkout: pair.workout,
        candidate: pair.match,
      );

      matchedWorkouts.add(pair.workout);
      matchedActivityIds.add(pair.match.activity.id);
    }

    // Offene Trainings ohne passenden Kandidaten bleiben im Waiting-Status.
    for (final workout in openWorkouts) {
      resolved.putIfAbsent(
        workout,
        () => RecentWorkoutMatch(scheduledWorkout: workout),
      );
    }

    // Reihenfolge der ursprünglichen Workout-Liste beibehalten.
    return workouts.map((workout) => resolved[workout]!).toList();
  }
}

class _CandidatePair {
  final ScheduledWorkout workout;
  final WorkoutActivityMatch match;

  const _CandidatePair({required this.workout, required this.match});
}
