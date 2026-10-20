import 'package:flutter_test/flutter_test.dart';
import 'package:pirowflo_control/models/rowing_metrics.dart';
import 'package:pirowflo_control/models/workout.dart';
import 'package:pirowflo_control/services/workout_step_recorder.dart';

void main() {
  test('berechnet Leistungswerte und Zielbereich korrekt', () {
    const step = WorkoutStep(
      type: WorkoutStepType.work,
      title: 'Intervall 1 / 5',
      duration: Duration(minutes: 3),
      targetPowerMin: 135,
      targetPowerMax: 145,
    );

    final recorder = WorkoutStepRecorder(step);

    RowingMetrics metrics({
      required int power,
      required double spm,
      required int pace,
      required int distance,
    }) {
      return RowingMetrics(
        smartRowConnected: true,
        smartRowReady: true,
        rowing: power > 0,
        powerW: power,
        strokeRateSpm: spm,
        pace500mSeconds: pace,
        distanceM: distance,
        elapsedSeconds: 0,
        heartRateBpm: 0,
        averagePowerW: 0,
        averagePace500mSeconds: 0,
      );
    }

    recorder.addSample(metrics(power: 120, spm: 22, pace: 150, distance: 100));

    recorder.addSample(metrics(power: 138, spm: 24, pace: 145, distance: 105));

    recorder.addSample(metrics(power: 142, spm: 26, pace: 140, distance: 110));

    recorder.addSample(metrics(power: 151, spm: 28, pace: 135, distance: 115));

    // Stillstand soll die Leistungsdurchschnitte
    // und Zielbereichsauswertung nicht beeinflussen.
    recorder.addSample(metrics(power: 0, spm: 0, pace: 0, distance: 115));

    final result = recorder.finish(const Duration(minutes: 3));

    expect(result.sampleCount, 5);

    expect(result.samplesBelowTarget, 1);
    expect(result.samplesInTarget, 2);
    expect(result.samplesAboveTarget, 1);

    expect(result.averagePowerW, closeTo(137.75, 0.01));
    expect(result.averageStrokeRateSpm, closeTo(25.0, 0.01));
    expect(result.averagePace500mSeconds, closeTo(142.5, 0.01));

    expect(result.distanceM, 15);

    expect(result.targetPercentage, closeTo(50.0, 0.01));
    expect(result.activePowerSamples, 4);
  });

  test('ignoriert Nullwerte bei Durchschnittswerten', () {
    const step = WorkoutStep(
      type: WorkoutStepType.warmup,
      title: 'Einrudern',
      duration: Duration(minutes: 7),
    );

    final recorder = WorkoutStepRecorder(step);

    const stopped = RowingMetrics(
      smartRowConnected: true,
      smartRowReady: true,
      rowing: false,
      powerW: 0,
      strokeRateSpm: 0,
      pace500mSeconds: 0,
      distanceM: 50,
      elapsedSeconds: 0,
      heartRateBpm: 0,
      averagePowerW: 0,
      averagePace500mSeconds: 0,
    );

    recorder.addSample(stopped);

    final result = recorder.finish(const Duration(seconds: 10));

    expect(result.averagePowerW, 0);
    expect(result.averageStrokeRateSpm, 0);
    expect(result.averagePace500mSeconds, 0);
    expect(result.targetPercentage, isNull);
  });
}
