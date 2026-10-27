import 'endurain_activity.dart';
import 'scheduled_workout.dart';
import '../services/workout_activity_matcher.dart';

enum RecentWorkoutMatchStatus { waiting, candidate, linked, missed, skipped }

class RecentWorkoutMatch {
  final ScheduledWorkout scheduledWorkout;
  final bool isLinked;
  final EndurainActivity? linkedActivity;
  final WorkoutActivityMatch? candidate;

  const RecentWorkoutMatch({
    required this.scheduledWorkout,
    this.isLinked = false,
    this.linkedActivity,
    this.candidate,
  });

  RecentWorkoutMatchStatus get status {
    if (isLinked) {
      return RecentWorkoutMatchStatus.linked;
    }

    if (scheduledWorkout.isMissed) {
      return RecentWorkoutMatchStatus.missed;
    }

    if (scheduledWorkout.isSkipped) {
      return RecentWorkoutMatchStatus.skipped;
    }

    if (candidate != null) {
      return RecentWorkoutMatchStatus.candidate;
    }

    return RecentWorkoutMatchStatus.waiting;
  }
}
