import '../models/scheduled_workout.dart';

class PiRowFloPlanStatus {
  final WorkoutPlanStatus status;
  final String? reason;

  const PiRowFloPlanStatus({required this.status, this.reason});
}

PiRowFloPlanStatus parsePiRowFloPlanStatus(String description) {
  final match = RegExp(
    r'\[PIROWFLO_PLAN_STATUS\](.*?)\[/PIROWFLO_PLAN_STATUS\]',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(description);

  if (match == null) {
    return const PiRowFloPlanStatus(status: WorkoutPlanStatus.active);
  }

  final block = match.group(1) ?? '';

  String? value(String key) {
    final match = RegExp(
      '^${RegExp.escape(key)}=(.*)\$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(block);

    return match?.group(1)?.trim();
  }

  final status = value('status');
  final reason = value('reason');

  return PiRowFloPlanStatus(
    status: status?.toLowerCase() == 'skipped'
        ? WorkoutPlanStatus.skipped
        : WorkoutPlanStatus.active,
    reason: reason?.isEmpty == true ? null : reason,
  );
}
