import 'endurain_activity.dart';
import 'pirowflo_result.dart';
import 'scheduled_workout.dart';
import '../services/workout_activity_matcher.dart';

enum RecentWorkoutMatchStatus { waiting, candidate, linked }

class RecentWorkoutMatch {
  final ScheduledWorkout scheduledWorkout;
  final PiRowFloResult? result;
  final EndurainActivity? linkedActivity;
  final WorkoutActivityMatch? candidate;

  const RecentWorkoutMatch({
    required this.scheduledWorkout,
    this.result,
    this.linkedActivity,
    this.candidate,
  });

  RecentWorkoutMatchStatus get status {
    if (result != null) {
      return RecentWorkoutMatchStatus.linked;
    }

    if (candidate != null) {
      return RecentWorkoutMatchStatus.candidate;
    }

    return RecentWorkoutMatchStatus.waiting;
  }
}
