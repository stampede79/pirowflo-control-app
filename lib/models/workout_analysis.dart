class WorkoutAnalysis {
  final String? execution;
  final String? loadAssessment;
  final String? effort;
  final String? progression;
  final bool? recoveryConcern;
  final String summary;
  final String? recommendation;

  const WorkoutAnalysis({
    required this.execution,
    required this.loadAssessment,
    required this.effort,
    required this.progression,
    required this.recoveryConcern,
    required this.summary,
    required this.recommendation,
  });

  factory WorkoutAnalysis.fromJson(Map<String, dynamic> json) {
    return WorkoutAnalysis(
      execution: json['execution'] as String?,
      loadAssessment: json['load_assessment'] as String?,
      effort: json['effort'] as String?,
      progression: json['progression'] as String?,
      recoveryConcern: json['recovery_concern'] as bool?,
      summary: json['summary'] as String? ?? '',
      recommendation: json['recommendation'] as String?,
    );
  }
}
