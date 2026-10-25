import 'package:flutter_test/flutter_test.dart';

import 'package:pirowflo_control/models/calendar_event.dart';
import 'package:pirowflo_control/models/endurain_activity.dart';
import 'package:pirowflo_control/models/scheduled_workout.dart';
import 'package:pirowflo_control/models/workout.dart';
import 'package:pirowflo_control/services/workout_activity_matcher.dart';

void main() {
  ScheduledWorkout scheduledWorkout({
    required DateTime start,
    Duration duration = const Duration(minutes: 40),
    bool allDay = false,
  }) {
    return ScheduledWorkout(
      start: start,
      workout: Workout(
        name: 'Rudern – Test',
        description: 'Geplantes Training',
        steps: [
          WorkoutStep(
            type: WorkoutStepType.work,
            title: 'Hauptteil',
            duration: duration,
          ),
        ],
      ),
      calendarEvent: CalendarEvent(
        summary: 'Rudern – Test',
        description: 'Geplantes Training',
        start: start,
        allDay: allDay,
        href: '/test.ics',
        etag: '"test-etag"',
        uid: 'test-uid',
        rawIcs: 'BEGIN:VCALENDAR\nEND:VCALENDAR',
      ),
    );
  }

  EndurainActivity activity({
    required int id,
    required DateTime start,
    Duration duration = const Duration(minutes: 40),
  }) {
    return EndurainActivity(
      id: id,
      name: 'Indoor-Rudern',
      activityType: 13,
      startTime: start,
      distance: 8000,
      duration: duration.inSeconds.toDouble(),
      averagePower: 130,
      maxPower: 180,
      averageHeartRate: 130,
      maxHeartRate: 155,
      averageCadence: 18,
      maxCadence: 24,
      calories: 300,
      normalizedPower: 135,
      totalCycles: 700,
    );
  }

  group('WorkoutActivityMatcher', () {
    test('findet eindeutige Aktivität', () {
      final workout = scheduledWorkout(start: DateTime(2026, 10, 24, 18));

      final candidate = activity(
        id: 1053,
        start: DateTime(2026, 10, 24, 18, 7),
        duration: const Duration(minutes: 42),
      );

      final match = WorkoutActivityMatcher.findBestMatch(workout, [candidate]);

      expect(match, isNotNull);
      expect(match!.activity.id, 1053);
      expect(match.startDifference, const Duration(minutes: 7));
      expect(match.durationDifference, const Duration(minutes: 2));
      expect(match.score, 968);
    });

    test('matched Ganztagstermin unabhängig von der Uhrzeit', () {
      final workout = scheduledWorkout(
        start: DateTime(2026, 10, 24),
        duration: const Duration(minutes: 40),
        allDay: true,
      );

      final candidate = activity(
        id: 1053,
        start: DateTime(2026, 10, 24, 18, 37),
        duration: const Duration(minutes: 42),
      );

      final match = WorkoutActivityMatcher.findBestMatch(workout, [candidate]);

      expect(match, isNotNull);
      expect(match!.activity.id, 1053);

      // Uhrzeit spielt bei Ganztagsterminen keine Rolle.
      expect(match.startDifference, Duration.zero);

      // Die Dauer wird weiterhin berücksichtigt.
      expect(match.durationDifference, const Duration(minutes: 2));
    });

    test('matched Ganztagstermin nicht mit Aktivität vom Folgetag', () {
      final workout = scheduledWorkout(
        start: DateTime(2026, 10, 24),
        allDay: true,
      );

      final candidate = activity(id: 1053, start: DateTime(2026, 10, 25, 0, 5));

      final match = WorkoutActivityMatcher.findBestMatch(workout, [candidate]);

      expect(match, isNull);
    });
    test('ignoriert Aktivität an einem anderen Tag', () {
      final workout = scheduledWorkout(start: DateTime(2026, 10, 24, 18));

      final candidate = activity(id: 1053, start: DateTime(2026, 10, 25, 18));

      final match = WorkoutActivityMatcher.findBestMatch(workout, [candidate]);

      expect(match, isNull);
    });

    test('ignoriert Aktivität mit mehr als drei Stunden Abstand', () {
      final workout = scheduledWorkout(start: DateTime(2026, 10, 24, 18));

      final candidate = activity(
        id: 1053,
        start: DateTime(2026, 10, 24, 21, 30),
      );

      final match = WorkoutActivityMatcher.findBestMatch(workout, [candidate]);

      expect(match, isNull);
    });

    test('wählt bei Ganztagstermin die Aktivität mit passender Dauer', () {
      final workout = scheduledWorkout(
        start: DateTime(2026, 10, 24),
        duration: const Duration(minutes: 40),
        allDay: true,
      );

      final shortActivity = activity(
        id: 1050,
        start: DateTime(2026, 10, 24, 10),
        duration: const Duration(minutes: 20),
      );

      final matchingActivity = activity(
        id: 1053,
        start: DateTime(2026, 10, 24, 19),
        duration: const Duration(minutes: 42),
      );

      final match = WorkoutActivityMatcher.findBestMatch(workout, [
        shortActivity,
        matchingActivity,
      ]);

      expect(match, isNotNull);
      expect(match!.activity.id, 1053);
      expect(match.durationDifference, const Duration(minutes: 2));
    });
    test('wählt den besseren Kandidaten am selben Tag', () {
      final workout = scheduledWorkout(start: DateTime(2026, 10, 24, 18));

      final poorCandidate = activity(
        id: 1050,
        start: DateTime(2026, 10, 24, 19, 30),
        duration: const Duration(minutes: 55),
      );

      final goodCandidate = activity(
        id: 1053,
        start: DateTime(2026, 10, 24, 18, 8),
        duration: const Duration(minutes: 42),
      );

      final match = WorkoutActivityMatcher.findBestMatch(workout, [
        poorCandidate,
        goodCandidate,
      ]);

      expect(match, isNotNull);
      expect(match!.activity.id, 1053);
    });

    test('berücksichtigt Dauer bei ähnlicher Startzeit', () {
      final workout = scheduledWorkout(
        start: DateTime(2026, 10, 24, 18),
        duration: const Duration(minutes: 40),
      );

      final wrongDuration = activity(
        id: 1050,
        start: DateTime(2026, 10, 24, 18, 5),
        duration: const Duration(minutes: 90),
      );

      final matchingDuration = activity(
        id: 1053,
        start: DateTime(2026, 10, 24, 18, 10),
        duration: const Duration(minutes: 41),
      );

      final match = WorkoutActivityMatcher.findBestMatch(workout, [
        wrongDuration,
        matchingDuration,
      ]);

      expect(match, isNotNull);
      expect(match!.activity.id, 1053);
    });
  });
}
