class EndurainActivity {
  final int id;
  final String name;
  final int activityType;
  final DateTime startTime;

  final double distance;
  final double duration;
  final double averagePower;
  final double maxPower;
  final double averageHeartRate;
  final double maxHeartRate;
  final double averageCadence;
  final double maxCadence;
  final double calories;
  final double normalizedPower;
  final int totalCycles;

  const EndurainActivity({
    required this.id,
    required this.name,
    required this.activityType,
    required this.startTime,
    required this.distance,
    required this.duration,
    required this.averagePower,
    required this.maxPower,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.averageCadence,
    required this.maxCadence,
    required this.calories,
    required this.normalizedPower,
    required this.totalCycles,
  });

  factory EndurainActivity.fromJson(Map<String, dynamic> json) {
    double number(String key) {
      final value = json[key];

      if (value is num) {
        return value.toDouble();
      }

      return 0;
    }

    return EndurainActivity(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? 'Indoor-Rudern',
      activityType: (json['activity_type'] as num).toInt(),
      startTime: DateTime.parse(json['start_time'].toString()),
      distance: number('distance'),
      duration: number('total_timer_time'),
      averagePower: number('average_power'),
      maxPower: number('max_power'),
      averageHeartRate: number('average_hr'),
      maxHeartRate: number('max_hr'),
      averageCadence: number('average_cad'),
      maxCadence: number('max_cad'),
      calories: number('calories'),
      normalizedPower: number('normalized_power'),
      totalCycles: (json['total_cycles'] as num?)?.toInt() ?? 0,
    );
  }
  double get pace500mSeconds {
    if (distance <= 0 || duration <= 0) {
      return 0;
    }

    return duration / distance * 500;
  }

  double get distanceKm => distance / 1000;
}
