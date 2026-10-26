import 'calendar_event.dart';
import 'workout.dart';

enum WorkoutPlanStatus { active, skipped }

class ScheduledWorkout {
  final DateTime start;
  final Workout workout;
  final CalendarEvent calendarEvent;
  final WorkoutPlanStatus planStatus;
  final String? planStatusReason;

  const ScheduledWorkout({
    required this.start,
    required this.workout,
    required this.calendarEvent,
    this.planStatus = WorkoutPlanStatus.active,
    this.planStatusReason,
  });

  bool get isSkipped => planStatus == WorkoutPlanStatus.skipped;
}
