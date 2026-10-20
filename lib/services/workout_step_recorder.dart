import '../models/rowing_metrics.dart';
import '../models/workout.dart';
import '../models/workout_step_result.dart';

class WorkoutStepRecorder {
  final WorkoutStep step;

  int sampleCount = 0;

  double powerSum = 0;
  double strokeRateSum = 0;
  double paceSum = 0;

  int powerSamples = 0;
  int strokeRateSamples = 0;
  int paceSamples = 0;

  int samplesInTarget = 0;
  int samplesBelowTarget = 0;
  int samplesAboveTarget = 0;

  int? startDistanceM;
  int? lastDistanceM;

  WorkoutStepRecorder(this.step);

  void addSample(RowingMetrics metrics) {
    sampleCount++;

    startDistanceM ??= metrics.distanceM;

    lastDistanceM = metrics.distanceM;

    if (metrics.powerW > 0) {
      powerSum += metrics.powerW;
      powerSamples++;

      final min = step.targetPowerMin;
      final max = step.targetPowerMax;

      if (min != null && max != null) {
        if (metrics.powerW < min) {
          samplesBelowTarget++;
        } else if (metrics.powerW > max) {
          samplesAboveTarget++;
        } else {
          samplesInTarget++;
        }
      }
    }

    if (metrics.strokeRateSpm > 0) {
      strokeRateSum += metrics.strokeRateSpm;
      strokeRateSamples++;
    }

    if (metrics.pace500mSeconds > 0) {
      paceSum += metrics.pace500mSeconds;
      paceSamples++;
    }
  }

  WorkoutStepResult finish(Duration duration) {
    final distance = startDistanceM == null || lastDistanceM == null
        ? 0
        : lastDistanceM! - startDistanceM!;

    return WorkoutStepResult(
      step: step,
      duration: duration,
      averagePowerW: powerSamples == 0 ? 0 : powerSum / powerSamples,
      averageStrokeRateSpm: strokeRateSamples == 0
          ? 0
          : strokeRateSum / strokeRateSamples,
      averagePace500mSeconds: paceSamples == 0 ? 0 : paceSum / paceSamples,
      distanceM: distance < 0 ? 0 : distance,
      sampleCount: sampleCount,
      activePowerSamples: powerSamples,
      samplesInTarget: samplesInTarget,
      samplesBelowTarget: samplesBelowTarget,
      samplesAboveTarget: samplesAboveTarget,
    );
  }
}
