import '../services/workout_parser.dart';
import 'workout.dart';
import 'scheduled_workout.dart';

class ApiWorkoutActivity {
  final int id;
  final int endurainActivityId;
  final DateTime startTime;
  final double? durationMinutes;
  final double? distanceKm;
  final double? averagePower;
  final double? normalizedPower;
  final double? averageHr;
  final double? maxHr;
  final double? averageSpm;
  final String linkStatus;

  const ApiWorkoutActivity({
    required this.id,
    required this.endurainActivityId,
    required this.startTime,
    required this.durationMinutes,
    required this.distanceKm,
    required this.averagePower,
    required this.normalizedPower,
    required this.averageHr,
    required this.maxHr,
    required this.averageSpm,
    required this.linkStatus,
  });

  factory ApiWorkoutActivity.fromJson(Map<String, dynamic> json) {
    return ApiWorkoutActivity(
      id: (json['id'] as num).toInt(),
      endurainActivityId: (json['endurain_activity_id'] as num).toInt(),
      startTime: DateTime.parse(json['start_time'] as String),
      durationMinutes: (json['duration_minutes'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      averagePower: (json['average_power'] as num?)?.toDouble(),
      normalizedPower: (json['normalized_power'] as num?)?.toDouble(),
      averageHr: (json['average_hr'] as num?)?.toDouble(),
      maxHr: (json['max_hr'] as num?)?.toDouble(),
      averageSpm: (json['average_spm'] as num?)?.toDouble(),
      linkStatus: json['link_status'] as String,
    );
  }
}

class ApiWorkout {
  final int id;
  final int trainingPlanId;
  final DateTime scheduledDate;
  final String name;
  final String description;
  final String status;

  final String? warmup;
  final int repeat;
  final String work;
  final String? recovery;
  final String? cooldown;

  final ApiWorkoutActivity? activity;
  final String? calendarSyncStatus;

  const ApiWorkout({
    required this.id,
    required this.trainingPlanId,
    required this.scheduledDate,
    required this.name,
    required this.description,
    required this.status,
    required this.warmup,
    required this.repeat,
    required this.work,
    required this.recovery,
    required this.cooldown,
    required this.activity,
    required this.calendarSyncStatus,
  });

  bool get completed => status == 'completed';
  bool get planned => status == 'planned';
  bool get skipped => status == 'skipped';

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

  ScheduledWorkout? toScheduledWorkout() {
    final parsedWorkout = toWorkout();

    if (parsedWorkout == null) {
      return null;
    }

    return ScheduledWorkout(
      id: id,
      trainingPlanId: trainingPlanId,
      start: scheduledDate,
      workout: parsedWorkout,
      status: status,
      activity: activity,
      allDay: true,
    );
  }

  factory ApiWorkout.fromJson(Map<String, dynamic> json) {
    final activityJson = json['activity'];
    final syncJson = json['calendar_sync'];

    return ApiWorkout(
      id: (json['id'] as num).toInt(),
      trainingPlanId: (json['training_plan_id'] as num).toInt(),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      status: json['status'] as String,
      warmup: json['warmup'] as String?,
      repeat: json['repeat'] as int? ?? 1,
      work: json['work'] as String,
      recovery: json['recovery'] as String?,
      cooldown: json['cooldown'] as String?,
      activity: activityJson is Map<String, dynamic>
          ? ApiWorkoutActivity.fromJson(activityJson)
          : null,
      calendarSyncStatus: syncJson is Map<String, dynamic>
          ? syncJson['status'] as String?
          : null,
    );
  }
}
