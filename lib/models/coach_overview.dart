class CoachWeeklyReview {
  final int year;
  final int isoWeek;
  final String assessment;
  final String trend;
  final String loadAssessment;
  final String recoveryAssessment;
  final String consistency;
  final List<String> keyObservations;
  final String summary;
  final String recommendation;

  const CoachWeeklyReview({
    required this.year,
    required this.isoWeek,
    required this.assessment,
    required this.trend,
    required this.loadAssessment,
    required this.recoveryAssessment,
    required this.consistency,
    required this.keyObservations,
    required this.summary,
    required this.recommendation,
  });

  factory CoachWeeklyReview.fromJson(Map<String, dynamic> json) {
    return CoachWeeklyReview(
      year: (json['year'] as num).toInt(),
      isoWeek: (json['iso_week'] as num).toInt(),
      assessment: json['assessment']?.toString() ?? 'unknown',
      trend: json['trend']?.toString() ?? 'unknown',
      loadAssessment: json['load_assessment']?.toString() ?? 'unknown',
      recoveryAssessment: json['recovery_assessment']?.toString() ?? 'unknown',
      consistency: json['consistency']?.toString() ?? 'unknown',
      keyObservations: (json['key_observations'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      summary: json['summary']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }
}

class CoachRecommendation {
  final int id;
  final String type;
  final String action;
  final int? workoutId;
  final String reason;
  final Map<String, dynamic> payload;

  const CoachRecommendation({
    required this.id,
    required this.type,
    required this.action,
    required this.workoutId,
    required this.reason,
    required this.payload,
  });

  factory CoachRecommendation.fromJson(Map<String, dynamic> json) {
    return CoachRecommendation(
      id: (json['id'] as num).toInt(),
      type: json['type'].toString(),
      action: json['action'].toString(),
      workoutId: (json['workout_id'] as num?)?.toInt(),
      reason: json['reason']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}

class CoachWorkoutAnalysis {
  final DateTime date;
  final String name;
  final int endurainActivityId;
  final String execution;
  final String loadAssessment;
  final String effort;
  final String progression;
  final bool recoveryConcern;
  final String summary;
  final String recommendation;

  const CoachWorkoutAnalysis({
    required this.date,
    required this.name,
    required this.endurainActivityId,
    required this.execution,
    required this.loadAssessment,
    required this.effort,
    required this.progression,
    required this.recoveryConcern,
    required this.summary,
    required this.recommendation,
  });

  factory CoachWorkoutAnalysis.fromJson(Map<String, dynamic> json) {
    return CoachWorkoutAnalysis(
      date: DateTime.parse(json['date'].toString()),
      name: json['name']?.toString() ?? '',
      endurainActivityId: (json['endurain_activity_id'] as num).toInt(),
      execution: json['execution']?.toString() ?? 'unknown',
      loadAssessment: json['load_assessment']?.toString() ?? 'unknown',
      effort: json['effort']?.toString() ?? 'unknown',
      progression: json['progression']?.toString() ?? 'unknown',
      recoveryConcern: json['recovery_concern'] == true,
      summary: json['summary']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }
}

class CoachMonthlyReview {
  final int year;
  final int month;
  final String? assessment;
  final String? trend;
  final String? loadAssessment;
  final String? recoveryAssessment;
  final String? consistency;
  final String? progression;
  final List<String> keyObservations;
  final List<String> strengths;
  final List<String> focusAreas;
  final String summary;
  final String recommendation;

  const CoachMonthlyReview({
    required this.year,
    required this.month,
    required this.assessment,
    required this.trend,
    required this.loadAssessment,
    required this.recoveryAssessment,
    required this.consistency,
    required this.progression,
    required this.keyObservations,
    required this.strengths,
    required this.focusAreas,
    required this.summary,
    required this.recommendation,
  });

  factory CoachMonthlyReview.fromJson(Map<String, dynamic> json) {
    List<String> stringList(String key) {
      return (json[key] as List? ?? const [])
          .map((value) => value.toString())
          .toList();
    }

    return CoachMonthlyReview(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      assessment: json['assessment']?.toString(),
      trend: json['trend']?.toString(),
      loadAssessment: json['load_assessment']?.toString(),
      recoveryAssessment: json['recovery_assessment']?.toString(),
      consistency: json['consistency']?.toString(),
      progression: json['progression']?.toString(),
      keyObservations: stringList('key_observations'),
      strengths: stringList('strengths'),
      focusAreas: stringList('focus_areas'),
      summary: json['summary']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }
}

class CoachOverview {
  final CoachWeeklyReview? weeklyReview;
  final CoachWorkoutAnalysis? latestWorkoutAnalysis;
  final List<CoachRecommendation> pendingRecommendations;
  final CoachMonthlyReview? monthlyReview;

  const CoachOverview({
    required this.weeklyReview,
    required this.latestWorkoutAnalysis,
    required this.pendingRecommendations,
    required this.monthlyReview,
  });

  factory CoachOverview.fromJson(Map<String, dynamic> json) {
    final weekly = json['weekly_review'];
    final workout = json['latest_workout_analysis'];
    final monthly = json['monthly_review'];

    return CoachOverview(
      weeklyReview: weekly is Map<String, dynamic>
          ? CoachWeeklyReview.fromJson(weekly)
          : null,
      latestWorkoutAnalysis: workout is Map<String, dynamic>
          ? CoachWorkoutAnalysis.fromJson(workout)
          : null,
      pendingRecommendations:
          (json['pending_recommendations'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(CoachRecommendation.fromJson)
              .toList(),
      monthlyReview: monthly is Map<String, dynamic>
          ? CoachMonthlyReview.fromJson(monthly)
          : null,
    );
  }
}
