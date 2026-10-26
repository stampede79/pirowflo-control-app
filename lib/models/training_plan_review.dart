class TrainingPlanReviewChange {
  final String action;
  final DateTime originalDate;
  final DateTime? newDate;
  final String reason;
  final String? name;
  final String? description;
  final String? warmup;
  final int? repeat;
  final String? work;
  final String? recovery;
  final String? cooldown;

  const TrainingPlanReviewChange({
    required this.action,
    required this.originalDate,
    required this.newDate,
    required this.reason,
    required this.name,
    required this.description,
    required this.warmup,
    required this.repeat,
    required this.work,
    required this.recovery,
    required this.cooldown,
  });

  factory TrainingPlanReviewChange.fromJson(Map<String, dynamic> json) {
    return TrainingPlanReviewChange(
      action: json['action'] as String,
      originalDate: DateTime.parse(json['original_date'] as String),
      newDate: json['new_date'] == null
          ? null
          : DateTime.parse(json['new_date'] as String),
      reason: json['reason'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      warmup: json['warmup'] as String?,
      repeat: json['repeat'] as int?,
      work: json['work'] as String?,
      recovery: json['recovery'] as String?,
      cooldown: json['cooldown'] as String?,
    );
  }
}

class TrainingPlanReview {
  final String status;
  final String targetMonth;
  final DateTime generatedAt;
  final bool planStillSuitable;
  final String summary;
  final List<TrainingPlanReviewChange> changes;

  const TrainingPlanReview({
    required this.status,
    required this.targetMonth,
    required this.generatedAt,
    required this.planStillSuitable,
    required this.summary,
    required this.changes,
  });

  factory TrainingPlanReview.fromJson(Map<String, dynamic> json) {
    final review = json['review'];

    if (review is! Map<String, dynamic>) {
      throw const FormatException('Ungültiger Trainingsplan-Review');
    }

    return TrainingPlanReview(
      status: json['status'] as String,
      targetMonth: json['target_month'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      planStillSuitable: review['plan_still_suitable'] as bool,
      summary: review['summary'] as String,
      changes: (review['changes'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(TrainingPlanReviewChange.fromJson)
          .toList(),
    );
  }
}
