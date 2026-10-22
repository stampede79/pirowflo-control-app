enum EndurainSummaryPeriod { week, month, year, lifetime }

extension EndurainSummaryPeriodLabel on EndurainSummaryPeriod {
  String get label => switch (this) {
    EndurainSummaryPeriod.week => 'Woche',
    EndurainSummaryPeriod.month => 'Monat',
    EndurainSummaryPeriod.year => 'Jahr',
    EndurainSummaryPeriod.lifetime => 'Gesamt',
  };

  String get apiValue => switch (this) {
    EndurainSummaryPeriod.week => 'week',
    EndurainSummaryPeriod.month => 'month',
    EndurainSummaryPeriod.year => 'year',
    EndurainSummaryPeriod.lifetime => 'lifetime',
  };
}

class EndurainSummaryBreakdown {
  final int period;
  final double distance;
  final double duration;
  final int activityCount;
  final double calories;

  const EndurainSummaryBreakdown({
    required this.period,
    required this.distance,
    required this.duration,
    required this.activityCount,
    required this.calories,
  });

  factory EndurainSummaryBreakdown.fromJson(Map<String, dynamic> json) {
    final period =
        json['day_of_week'] ??
        json['week_number'] ??
        json['month_number'] ??
        json['year_number'];

    if (period is! num) {
      throw const FormatException('Ungültiger Endurain Summary-Zeitraum');
    }

    return EndurainSummaryBreakdown(
      period: period.toInt(),
      distance: (json['total_distance'] as num).toDouble(),
      duration: (json['total_duration'] as num).toDouble(),
      activityCount: (json['activity_count'] as num).toInt(),
      calories: (json['total_calories'] as num).toDouble(),
    );
  }
}

class EndurainSummary {
  final double distance;
  final double duration;
  final int activityCount;
  final double calories;
  final List<EndurainSummaryBreakdown> breakdown;

  const EndurainSummary({
    required this.distance,
    required this.duration,
    required this.activityCount,
    required this.calories,
    required this.breakdown,
  });

  factory EndurainSummary.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'];

    return EndurainSummary(
      distance: (json['total_distance'] as num).toDouble(),
      duration: (json['total_duration'] as num).toDouble(),
      activityCount: (json['activity_count'] as num).toInt(),
      calories: (json['total_calories'] as num).toDouble(),
      breakdown: rawBreakdown is List
          ? rawBreakdown
                .whereType<Map<String, dynamic>>()
                .map(EndurainSummaryBreakdown.fromJson)
                .toList()
          : const [],
    );
  }
}
