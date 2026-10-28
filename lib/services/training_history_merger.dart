import '../models/endurain_activity.dart';
import '../models/scheduled_workout.dart';
import '../models/training_history_entry.dart';
import '../models/workout_analysis.dart';
import 'recent_workout_matcher.dart';

class TrainingHistoryMerger {
  static List<TrainingHistoryEntry> merge(
    List<ScheduledWorkout> workouts,
    List<EndurainActivity> activities, {
    Map<int, WorkoutAnalysis> analyses = const {},
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();

    final currentDate = DateTime(now.year, now.month, now.day);

    final matches = RecentWorkoutMatcher.resolve(workouts, activities);

    final entries = <TrainingHistoryEntry>[];
    final assignedActivityIds = <int>{};

    for (final match in matches) {
      final scheduled = match.scheduledWorkout;

      final activity = match.linkedActivity ?? match.candidate?.activity;

      // Eine bereits zugeordnete bzw. als Kandidat erkannte
      // Aktivität darf später nicht zusätzlich als freies
      // Training in der Historie erscheinen.
      if (activity != null) {
        assignedActivityIds.add(activity.id);
      }

      final scheduledDate = DateTime(
        scheduled.start.year,
        scheduled.start.month,
        scheduled.start.day,
      );

      // Ein für heute geplantes, aber noch nicht
      // abgeschlossenes Training gehört noch nicht in
      // die Historie.
      //
      // Sobald es abgeschlossen wurde, darf es auch am
      // selben Tag in der Historie erscheinen.
      if (scheduledDate == currentDate && !scheduled.isCompleted) {
        continue;
      }

      entries.add(
        TrainingHistoryEntry.planned(
          match: match,
          analysis: activity == null ? null : analyses[activity.id],
        ),
      );
    }

    // Endurain-Aktivitäten, die keinem geplanten Training
    // zugeordnet wurden, erscheinen als freie/spontane
    // Trainings.
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

    // Neueste Einträge zuerst.
    entries.sort((a, b) => b.date.compareTo(a.date));

    return entries;
  }
}
