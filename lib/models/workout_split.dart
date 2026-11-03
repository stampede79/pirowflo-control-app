class WorkoutSplit {
  final int distanceM;
  final double durationSeconds;
  final double averagePowerW;
  final double averageSpm;
  final double? averageHeartRateBpm;

  const WorkoutSplit({
    required this.distanceM,
    required this.durationSeconds,
    required this.averagePowerW,
    required this.averageSpm,
    required this.averageHeartRateBpm,
  });

  double get pace500mSeconds => durationSeconds;
}
