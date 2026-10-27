import 'endurain_activity.dart';
import 'recent_workout_match.dart';
import 'workout_analysis.dart';

enum TrainingHistoryEntryType { planned, free }

class TrainingHistoryEntry {
  final TrainingHistoryEntryType type;
  final RecentWorkoutMatch? match;
  final EndurainActivity? activity;
  final WorkoutAnalysis? analysis;

  const TrainingHistoryEntry._({
    required this.type,
    this.match,
    this.activity,
    this.analysis,
  });

  const TrainingHistoryEntry.planned({
    required RecentWorkoutMatch match,
    WorkoutAnalysis? analysis,
  }) : this._(
         type: TrainingHistoryEntryType.planned,
         match: match,
         activity: null,
         analysis: analysis,
       );

  const TrainingHistoryEntry.free({
    required EndurainActivity activity,
    WorkoutAnalysis? analysis,
  }) : this._(
         type: TrainingHistoryEntryType.free,
         activity: activity,
         analysis: analysis,
       );

  DateTime get date =>
      match?.scheduledWorkout.start ?? activity!.startTime.toLocal();
}
