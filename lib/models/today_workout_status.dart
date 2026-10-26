class TodayWorkoutActivity {
  final int endurainActivityId;
  final double? durationMinutes;
  final double? distanceKm;
  final double? averagePower;
  final double? averageHr;
  final double? averageSpm;

  const TodayWorkoutActivity({
    required this.endurainActivityId,
    required this.durationMinutes,
    required this.distanceKm,
    required this.averagePower,
    required this.averageHr,
    required this.averageSpm,
  });

  factory TodayWorkoutActivity.fromJson(Map<String, dynamic> json) {
    return TodayWorkoutActivity(
      endurainActivityId: (json['endurain_activity_id'] as num).toInt(),
      durationMinutes: (json['duration_minutes'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      averagePower: (json['average_power'] as num?)?.toDouble(),
      averageHr: (json['average_hr'] as num?)?.toDouble(),
      averageSpm: (json['average_spm'] as num?)?.toDouble(),
    );
  }
}

class TodayWorkoutStatus {
  final int id;
  final DateTime date;
  final String name;
  final String status;
  final TodayWorkoutActivity? activity;

  const TodayWorkoutStatus({
    required this.id,
    required this.date,
    required this.name,
    required this.status,
    required this.activity,
  });

  bool get completed => status == 'completed';

  factory TodayWorkoutStatus.fromJson(Map<String, dynamic> json) {
    final activity = json['activity'];

    return TodayWorkoutStatus(
      id: (json['id'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      name: json['name'] as String,
      status: json['status'] as String,
      activity: activity is Map<String, dynamic>
          ? TodayWorkoutActivity.fromJson(activity)
          : null,
    );
  }
}
