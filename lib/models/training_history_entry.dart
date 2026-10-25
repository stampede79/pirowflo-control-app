import 'endurain_activity.dart';
import 'recent_workout_match.dart';

enum TrainingHistoryEntryType { planned, free }

class TrainingHistoryEntry {
  final TrainingHistoryEntryType type;
  final RecentWorkoutMatch? match;
  final EndurainActivity? activity;

  const TrainingHistoryEntry._({required this.type, this.match, this.activity});

  const TrainingHistoryEntry.planned({required RecentWorkoutMatch match})
    : this._(
        type: TrainingHistoryEntryType.planned,
        match: match,
        activity: null,
      );

  const TrainingHistoryEntry.free({required EndurainActivity activity})
    : this._(type: TrainingHistoryEntryType.free, activity: activity);

  DateTime get date =>
      match?.scheduledWorkout.start ?? activity!.startTime.toLocal();
}
