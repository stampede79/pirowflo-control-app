import 'package:flutter_test/flutter_test.dart';
import 'package:pirowflo_control/services/workout_parser.dart';

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

  test('ignoriert normale Kalendertermine ohne PiRowFlo-Daten', () {
    final workout = WorkoutParser.parse(
      name: 'Erholung',
      description: 'Kein Rudern. Regeneration.',
    );

    expect(workout, isNull);
  });
}
