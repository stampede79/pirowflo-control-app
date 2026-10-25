import '../models/endurain_activity.dart';
import '../models/scheduled_workout.dart';
import '../models/training_history_entry.dart';
import 'recent_workout_matcher.dart';

class TrainingHistoryMerger {
  static List<TrainingHistoryEntry> merge(
    List<ScheduledWorkout> workouts,
    List<EndurainActivity> activities,
  ) {
    final matches = RecentWorkoutMatcher.resolve(workouts, activities);

    final entries = <TrainingHistoryEntry>[];
    final assignedActivityIds = <int>{};

    for (final match in matches) {
      final activity = match.linkedActivity ?? match.candidate?.activity;

      if (activity != null) {
        assignedActivityIds.add(activity.id);
      }

      entries.add(TrainingHistoryEntry.planned(match: match));
    }

    // Endurain-Aktivitäten, die keinem Kalendertraining zugeordnet
    // wurden, erscheinen als freie/spontane Trainings.
    for (final activity in activities) {
      if (assignedActivityIds.contains(activity.id)) {
        continue;
      }

      entries.add(TrainingHistoryEntry.free(activity: activity));
    }

    entries.sort((a, b) => b.date.compareTo(a.date));

    return entries;
  }
}
