class RowingMetrics {
  final bool smartRowConnected;
  final bool smartRowReady;
  final bool rowing;
  final int powerW;
  final double strokeRateSpm;
  final int pace500mSeconds;
  final int distanceM;
  final int elapsedSeconds;
  final int heartRateBpm;
  final double averagePowerW;
  final int averagePace500mSeconds;

  const RowingMetrics({
    required this.smartRowConnected,
    required this.smartRowReady,
    required this.rowing,
    required this.powerW,
    required this.strokeRateSpm,
    required this.pace500mSeconds,
    required this.distanceM,
    required this.elapsedSeconds,
    required this.heartRateBpm,
    required this.averagePowerW,
    required this.averagePace500mSeconds,
  });

  factory RowingMetrics.fromJson(Map<String, dynamic> json) {
    return RowingMetrics(
      smartRowConnected: json['smartrow_connected'] == true,
      smartRowReady: json['smartrow_ready'] == true,
      rowing: json['rowing'] == true,
      powerW: (json['power_w'] as num?)?.toInt() ?? 0,
      strokeRateSpm: (json['stroke_rate_spm'] as num?)?.toDouble() ?? 0,
      pace500mSeconds: (json['pace_500m_seconds'] as num?)?.toInt() ?? 0,
      distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
      heartRateBpm: (json['heart_rate_bpm'] as num?)?.toInt() ?? 0,
      averagePowerW: (json['power_avg_w'] as num?)?.toDouble() ?? 0,
      averagePace500mSeconds:
          (json['pace_avg_500m_seconds'] as num?)?.toInt() ?? 0,
    );
  }
}
