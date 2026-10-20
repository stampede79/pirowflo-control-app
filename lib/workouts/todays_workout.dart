import '../models/workout.dart';
import '../services/workout_parser.dart';

Workout? buildTodaysWorkout() {
  const description = '''
7 min locker. Dann 5 x: 3 min bei 135–145 W + 2 min bei 90–100 W.
Danach 5 min locker. Belastungsintervalle möglichst gleichmäßig fahren,
nicht sprinten.

[PIROWFLO]
warmup=7m
repeat=5
work=3m,135-145w
recovery=2m,90-100w
cooldown=5m
[/PIROWFLO]
''';

  return WorkoutParser.parse(
    name: 'Rudern – Intervalle',
    description: description,
  );
}
