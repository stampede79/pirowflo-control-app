import '../models/endurain_activity.dart';
import '../models/scheduled_workout.dart';

class WorkoutActivityMatch {
  final EndurainActivity activity;
  final Duration startDifference;
  final Duration durationDifference;
  final int score;

  const WorkoutActivityMatch({
    required this.activity,
    required this.startDifference,
    required this.durationDifference,
    required this.score,
  });
}

class WorkoutActivityMatcher {
  static WorkoutActivityMatch? findBestMatch(
    ScheduledWorkout workout,
    List<EndurainActivity> activities,
  ) {
    final candidates = activities
        .where((activity) => _sameLocalDay(workout.start, activity.startTime))
        .map((activity) => _evaluate(workout, activity))
        .where(
          (match) =>
              workout.calendarEvent.allDay ||
              match.startDifference <= const Duration(hours: 3),
        )
        .toList();

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    return candidates.first;
  }

  static WorkoutActivityMatch _evaluate(
    ScheduledWorkout workout,
    EndurainActivity activity,
  ) {
    final startDifference = workout.calendarEvent.allDay
        ? Duration.zero
        : _absoluteDuration(
            workout.start.difference(activity.startTime.toLocal()),
          );

    final actualDuration = Duration(seconds: activity.duration.round());

    final durationDifference = Duration(
      seconds:
          (workout.workout.totalDuration.inSeconds - actualDuration.inSeconds)
              .abs(),
    );
    final startMinutes = startDifference.inMinutes;
    final durationMinutes = durationDifference.inMinutes;

    // Start time is more important than duration.
    final score = 1000 - (startMinutes * 4) - (durationMinutes * 2);

    return WorkoutActivityMatch(
      activity: activity,
      startDifference: startDifference,
      durationDifference: durationDifference,
      score: score,
    );
  }

  static bool _sameLocalDay(DateTime a, DateTime b) {
    final first = a.toLocal();
    final second = b.toLocal();

    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static Duration _absoluteDuration(Duration duration) {
    return duration.isNegative ? -duration : duration;
  }
}
