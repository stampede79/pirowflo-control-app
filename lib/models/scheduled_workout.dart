import 'api_workout.dart';
import 'workout.dart';

class ScheduledWorkout {
  final int? id;
  final int? trainingPlanId;

  final DateTime start;
  final Workout workout;

  final String status;
  final ApiWorkoutActivity? activity;

  final bool allDay;
  final String? planStatusReason;

  const ScheduledWorkout({
    this.id,
    this.trainingPlanId,
    required this.start,
    required this.workout,
    this.status = 'planned',
    this.activity,
    this.allDay = false,
    this.planStatusReason,
  });

  bool get isSkipped => status == 'skipped';

  bool get isCompleted => status == 'completed';

  bool get isMissed => status == 'missed';
}
