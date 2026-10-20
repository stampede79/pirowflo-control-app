import 'workout.dart';

class WorkoutStepResult {
  final WorkoutStep step;
  final Duration duration;

  final double averagePowerW;
  final double averageStrokeRateSpm;
  final double averagePace500mSeconds;

  final int distanceM;
  final int sampleCount;

  final int samplesInTarget;
  final int samplesBelowTarget;
  final int samplesAboveTarget;

  final int activePowerSamples;

  const WorkoutStepResult({
    required this.step,
    required this.duration,
    required this.averagePowerW,
    required this.averageStrokeRateSpm,
    required this.averagePace500mSeconds,
    required this.distanceM,
    required this.sampleCount,
    required this.samplesInTarget,
    required this.samplesBelowTarget,
    required this.samplesAboveTarget,
    required this.activePowerSamples,
  });

  bool get hasPowerTarget =>
      step.targetPowerMin != null && step.targetPowerMax != null;

  double? get targetPercentage {
    if (!hasPowerTarget || activePowerSamples == 0) {
      return null;
    }

    return samplesInTarget / activePowerSamples * 100;
  }
}
