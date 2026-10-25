import 'calendar_event.dart';
import 'workout.dart';

class ScheduledWorkout {
  final DateTime start;
  final Workout workout;
  final CalendarEvent calendarEvent;

  const ScheduledWorkout({
    required this.start,
    required this.workout,
    required this.calendarEvent,
  });
}
