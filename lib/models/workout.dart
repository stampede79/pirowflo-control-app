enum WorkoutStepType { warmup, work, recovery, cooldown }

class WorkoutStep {
  final WorkoutStepType type;
  final String title;
  final Duration duration;

  final int? targetPaceMinSeconds;
  final int? targetPaceMaxSeconds;
  final int? targetSpmMin;
  final int? targetSpmMax;
  final int? targetPowerMin;
  final int? targetPowerMax;

  const WorkoutStep({
    required this.type,
    required this.title,
    required this.duration,
    this.targetPaceMinSeconds,
    this.targetPaceMaxSeconds,
    this.targetSpmMin,
    this.targetSpmMax,
    this.targetPowerMin,
    this.targetPowerMax,
  });

  bool get hasTargetPace =>
      targetPaceMinSeconds != null && targetPaceMaxSeconds != null;
}

class Workout {
  final String name;
  final String description;
  final List<WorkoutStep> steps;
  final bool isFree;

  const Workout({
    required this.name,
    required this.description,
    required this.steps,
    this.isFree = false,
  });

  factory Workout.free() {
    return const Workout(
      name: 'Freies Training',
      description: 'Freies Rudern ohne Trainingsvorgabe.',
      steps: [
        WorkoutStep(
          type: WorkoutStepType.work,
          title: 'Freies Training',
          duration: Duration.zero,
        ),
      ],
      isFree: true,
    );
  }

  Duration get totalDuration =>
      steps.fold(Duration.zero, (total, step) => total + step.duration);
}
