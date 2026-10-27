import '../models/endurain_activity.dart';
import '../models/scheduled_workout.dart';
import '../models/training_history_entry.dart';
import 'recent_workout_matcher.dart';
import '../models/workout_analysis.dart';

class TrainingHistoryMerger {
  static List<TrainingHistoryEntry> merge(
    List<ScheduledWorkout> workouts,
    List<EndurainActivity> activities, {
    Map<int, WorkoutAnalysis> analyses = const {},
  }) {
    final matches = RecentWorkoutMatcher.resolve(workouts, activities);

    final entries = <TrainingHistoryEntry>[];
    final assignedActivityIds = <int>{};

    for (final match in matches) {
      final activity = match.linkedActivity ?? match.candidate?.activity;

      if (activity != null) {
        assignedActivityIds.add(activity.id);
      }

      entries.add(
        TrainingHistoryEntry.planned(
          match: match,
          analysis: activity == null ? null : analyses[activity.id],
        ),
      );
    }

    // Endurain-Aktivitäten, die keinem Kalendertraining zugeordnet
    // wurden, erscheinen als freie/spontane Trainings.
    for (final activity in activities) {
      if (assignedActivityIds.contains(activity.id)) {
        continue;
      }

      entries.add(
        TrainingHistoryEntry.free(
          activity: activity,
          analysis: analyses[activity.id],
        ),
      );
    }

    entries.sort((a, b) => b.date.compareTo(a.date));

    return entries;
  }
}
