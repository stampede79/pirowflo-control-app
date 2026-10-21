import 'package:flutter_test/flutter_test.dart';
import 'package:pirowflo_control/services/workout_parser.dart';
import 'package:pirowflo_control/models/workout.dart';

void main() {
  test('parst das Intervalltraining vom 20. Oktober', () {
    const description = '''
7 min locker. Dann 5 x: 3 min bei 135–145 W + 2 min bei 90–100 W.
Danach 5 min locker.

[PIROWFLO]
warmup=7m
repeat=5
work=3m,135-145w
recovery=2m,90-100w
cooldown=5m
[/PIROWFLO]
''';

    final workout = WorkoutParser.parse(
      name: 'Rudern – Intervalle',
      description: description,
    );

    expect(workout, isNotNull);
    expect(workout!.name, 'Rudern – Intervalle');
    expect(workout.steps.length, 12);

    expect(workout.steps.first.duration.inMinutes, 7);

    final firstInterval = workout.steps[1];
    expect(firstInterval.duration.inMinutes, 3);
    expect(firstInterval.targetPowerMin, 135);
    expect(firstInterval.targetPowerMax, 145);

    final firstRecovery = workout.steps[2];
    expect(firstRecovery.duration.inMinutes, 2);
    expect(firstRecovery.targetPowerMin, 90);
    expect(firstRecovery.targetPowerMax, 100);

    expect(workout.steps.last.duration.inMinutes, 5);
  });

  test('parst ein Grundlagentraining mit SPM', () {
    const description = '''
5 min locker. Dann 40 min bei 105–110 W und 16–18 spm.
Danach 5 min locker.

[PIROWFLO]
warmup=5m
work=40m,105-110w,16-18spm
cooldown=5m
[/PIROWFLO]
''';

    final workout = WorkoutParser.parse(
      name: 'Rudern – Grundlage',
      description: description,
    );

    expect(workout, isNotNull);

    final mainPart = workout!.steps[1];

    expect(mainPart.targetPowerMin, 105);
    expect(mainPart.targetPowerMax, 110);
    expect(mainPart.targetSpmMin, 16);
    expect(mainPart.targetSpmMax, 18);

    expect(workout.totalDuration.inMinutes, 50);
  });

  test(
    'parst Regenerationstraining mit Wattzielen in Warm-up und Cool-down',
    () {
      const description = '''
Kleine regenerative Einheit passend zum Oktober-Trainingsplan.

[PIROWFLO]
warmup=5m,80-90w
repeat=1
work=20m,95-105w
recovery=0m
cooldown=5m,80-90w
[/PIROWFLO]
''';

      final workout = WorkoutParser.parse(
        name: 'Regeneration',
        description: description,
      );

      expect(workout, isNotNull);
      expect(workout!.steps.length, 3);
      expect(workout.totalDuration, const Duration(minutes: 30));

      final warmup = workout.steps[0];

      expect(warmup.type, WorkoutStepType.warmup);
      expect(warmup.duration, const Duration(minutes: 5));
      expect(warmup.targetPowerMin, 80);
      expect(warmup.targetPowerMax, 90);

      final work = workout.steps[1];

      expect(work.type, WorkoutStepType.work);
      expect(work.duration, const Duration(minutes: 20));
      expect(work.targetPowerMin, 95);
      expect(work.targetPowerMax, 105);

      final cooldown = workout.steps[2];

      expect(cooldown.type, WorkoutStepType.cooldown);
      expect(cooldown.duration, const Duration(minutes: 5));
      expect(cooldown.targetPowerMin, 80);
      expect(cooldown.targetPowerMax, 90);

      // recovery=0m darf keinen eigenen Schritt erzeugen.
      expect(
        workout.steps.any((step) => step.type == WorkoutStepType.recovery),
        isFalse,
      );
    },
  );

  test('ignoriert normale Kalendertermine ohne PiRowFlo-Daten', () {
    final workout = WorkoutParser.parse(
      name: 'Erholung',
      description: 'Kein Rudern. Regeneration.',
    );

    expect(workout, isNull);
  });
}
