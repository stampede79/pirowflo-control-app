import 'workout.dart';
import '../services/workout_parser.dart';

class TrainingPlanDraftWorkout {
  final DateTime date;
  final String name;
  final String description;
  final String? warmup;
  final int repeat;
  final String work;
  final String? recovery;
  final String? cooldown;

  const TrainingPlanDraftWorkout({
    required this.date,
    required this.name,
    required this.description,
    required this.warmup,
    required this.repeat,
    required this.work,
    required this.recovery,
    required this.cooldown,
  });

  Workout? toWorkout() {
    final lines = <String>['[PIROWFLO]'];

    if (warmup != null && warmup!.isNotEmpty) {
      lines.add('warmup=$warmup');
    }

    if (repeat > 1) {
      lines.add('repeat=$repeat');
    }

    lines.add('work=$work');

    if (recovery != null && recovery!.isNotEmpty) {
      lines.add('recovery=$recovery');
    }

    if (cooldown != null && cooldown!.isNotEmpty) {
      lines.add('cooldown=$cooldown');
    }

    lines.add('[/PIROWFLO]');

    return WorkoutParser.parse(
      name: name,
      description:
          '''
$description

${lines.join('\n')}
''',
    );
  }

  factory TrainingPlanDraftWorkout.fromJson(Map<String, dynamic> json) {
    return TrainingPlanDraftWorkout(
      date: DateTime.parse(json['date'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
      warmup: json['warmup'] as String?,
      repeat: json['repeat'] as int? ?? 1,
      work: json['work'] as String,
      recovery: json['recovery'] as String?,
      cooldown: json['cooldown'] as String?,
    );
  }
}

class TrainingPlanDraft {
  final String status;
  final DateTime generatedAt;
  final String targetMonth;
  final int sessionsPerWeek;
  final String model;
  final List<TrainingPlanDraftWorkout> workouts;

  const TrainingPlanDraft({
    required this.status,
    required this.generatedAt,
    required this.targetMonth,
    required this.sessionsPerWeek,
    required this.model,
    required this.workouts,
  });

  factory TrainingPlanDraft.fromJson(Map<String, dynamic> json) {
    return TrainingPlanDraft(
      status: json['status'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      targetMonth: json['target_month'] as String,
      sessionsPerWeek: json['sessions_per_week'] as int,
      model: json['model'] as String,
      workouts: (json['workouts'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(TrainingPlanDraftWorkout.fromJson)
          .toList(),
    );
  }
}
