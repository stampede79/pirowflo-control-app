import 'package:flutter_test/flutter_test.dart';
import 'package:pirowflo_control/models/rowing_metrics.dart';
import 'package:pirowflo_control/services/workout_split_recorder.dart';

RowingMetrics metrics({
  required int distanceM,
  required int elapsedSeconds,
  int powerW = 100,
  double spm = 18,
  int heartRateBpm = 130,
}) {
  return RowingMetrics(
    smartRowConnected: true,
    smartRowReady: true,
    rowing: true,
    powerW: powerW,
    strokeRateSpm: spm,
    pace500mSeconds: 150,
    distanceM: distanceM,
    elapsedSeconds: elapsedSeconds,
    heartRateBpm: heartRateBpm,
    averagePowerW: powerW.toDouble(),
    averagePace500mSeconds: 150,
  );
}

void main() {
  test('does not create split before 500 meters', () {
    final recorder = WorkoutSplitRecorder();

    expect(
      recorder.addSample(metrics(distanceM: 0, elapsedSeconds: 0)),
      isNull,
    );

    expect(
      recorder.addSample(metrics(distanceM: 499, elapsedSeconds: 149)),
      isNull,
    );
  });

  test('creates split at exactly 500 meters', () {
    final recorder = WorkoutSplitRecorder();

    recorder.addSample(metrics(distanceM: 0, elapsedSeconds: 0));

    final split = recorder.addSample(
      metrics(distanceM: 500, elapsedSeconds: 150),
    );

    expect(split, isNotNull);
    expect(split!.distanceM, 500);
    expect(split.durationSeconds, 150);
  });

  test('interpolates crossing of 500 meter boundary', () {
    final recorder = WorkoutSplitRecorder();

    recorder.addSample(metrics(distanceM: 0, elapsedSeconds: 0));

    recorder.addSample(metrics(distanceM: 499, elapsedSeconds: 149));

    final split = recorder.addSample(
      metrics(distanceM: 501, elapsedSeconds: 150),
    );

    expect(split, isNotNull);

    expect(split!.durationSeconds, closeTo(149.5, 0.001));
  });

  test('creates consecutive 500 meter splits', () {
    final recorder = WorkoutSplitRecorder();

    recorder.addSample(metrics(distanceM: 0, elapsedSeconds: 0));

    final first = recorder.addSample(
      metrics(distanceM: 500, elapsedSeconds: 150),
    );

    final second = recorder.addSample(
      metrics(distanceM: 1000, elapsedSeconds: 298),
    );

    expect(first, isNotNull);
    expect(second, isNotNull);

    expect(first!.distanceM, 500);
    expect(first.durationSeconds, 150);

    expect(second!.distanceM, 1000);
    expect(second.durationSeconds, 148);
  });

  test('calculates average split values', () {
    final recorder = WorkoutSplitRecorder();

    recorder.addSample(
      metrics(
        distanceM: 0,
        elapsedSeconds: 0,
        powerW: 100,
        spm: 16,
        heartRateBpm: 120,
      ),
    );

    recorder.addSample(
      metrics(
        distanceM: 250,
        elapsedSeconds: 75,
        powerW: 110,
        spm: 18,
        heartRateBpm: 130,
      ),
    );

    final split = recorder.addSample(
      metrics(
        distanceM: 500,
        elapsedSeconds: 150,
        powerW: 120,
        spm: 20,
        heartRateBpm: 140,
      ),
    );

    expect(split, isNotNull);

    expect(split!.averagePowerW, closeTo(110, 0.001));

    expect(split.averageSpm, closeTo(18, 0.001));

    expect(split.averageHeartRateBpm, closeTo(130, 0.001));
  });

  test('resets safely after distance goes backwards', () {
    final recorder = WorkoutSplitRecorder();

    recorder.addSample(metrics(distanceM: 0, elapsedSeconds: 0));

    recorder.addSample(metrics(distanceM: 400, elapsedSeconds: 120));

    final resetResult = recorder.addSample(
      metrics(distanceM: 37, elapsedSeconds: 0),
    );

    expect(resetResult, isNull);

    final split = recorder.addSample(
      metrics(distanceM: 537, elapsedSeconds: 150),
    );

    expect(split, isNotNull);
    expect(split!.distanceM, 500);
    expect(split.durationSeconds, 150);
  });

  test('splits are relative to workout start distance', () {
    final recorder = WorkoutSplitRecorder();

    recorder.addSample(metrics(distanceM: 238, elapsedSeconds: 20));

    expect(
      recorder.addSample(metrics(distanceM: 737, elapsedSeconds: 169)),
      isNull,
    );

    final first = recorder.addSample(
      metrics(distanceM: 739, elapsedSeconds: 170),
    );

    expect(first, isNotNull);
    expect(first!.distanceM, 500);

    final second = recorder.addSample(
      metrics(distanceM: 1238, elapsedSeconds: 318),
    );

    expect(second, isNotNull);
    expect(second!.distanceM, 1000);
  });
}
