import '../models/workout.dart';

Workout buildIntervalWorkout() {
  final steps = <WorkoutStep>[
    const WorkoutStep(
      type: WorkoutStepType.warmup,
      title: 'Einrudern',
      duration: Duration(minutes: 7),
    ),
  ];

  for (var interval = 1; interval <= 5; interval++) {
    steps.add(
      WorkoutStep(
        type: WorkoutStepType.work,
        title: 'Intervall $interval / 5',
        duration: const Duration(minutes: 3),
        targetPowerMin: 135,
        targetPowerMax: 145,
      ),
    );

    steps.add(
      WorkoutStep(
        type: WorkoutStepType.recovery,
        title: 'Locker rudern $interval / 5',
        duration: const Duration(minutes: 2),
        targetPowerMin: 90,
        targetPowerMax: 100,
      ),
    );
  }

  steps.add(
    const WorkoutStep(
      type: WorkoutStepType.cooldown,
      title: 'Ausrudern',
      duration: Duration(minutes: 5),
    ),
  );

  return Workout(
    name: 'Rudern – Intervalle',
    description: '5 × 3 min Belastung / 2 min locker',
    steps: steps,
  );
}

Workout buildShortIntervalTestWorkout() {
  final steps = <WorkoutStep>[
    const WorkoutStep(
      type: WorkoutStepType.warmup,
      title: 'Einrudern',
      duration: Duration(seconds: 30),
    ),
  ];

  for (var interval = 1; interval <= 5; interval++) {
    steps.add(
      WorkoutStep(
        type: WorkoutStepType.work,
        title: 'Intervall $interval / 5',
        duration: const Duration(seconds: 30),
        targetPowerMin: 135,
        targetPowerMax: 145,
      ),
    );

    steps.add(
      WorkoutStep(
        type: WorkoutStepType.recovery,
        title: 'Locker rudern $interval / 5',
        duration: const Duration(seconds: 20),
        targetPowerMin: 90,
        targetPowerMax: 100,
      ),
    );
  }

  steps.add(
    const WorkoutStep(
      type: WorkoutStepType.cooldown,
      title: 'Ausrudern',
      duration: Duration(seconds: 30),
    ),
  );

  return Workout(
    name: 'TEST – Intervalle',
    description: 'UI-Test: 5 × 30 s Belastung / 20 s locker',
    steps: steps,
  );
}
