import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_workout.dart';
import '../models/scheduled_workout.dart';

class WorkoutService {
  final String server;
  final String apiKey;

  const WorkoutService({required this.server, required this.apiKey});

  Map<String, String> get _headers => {'X-API-Key': apiKey};

  Future<List<ScheduledWorkout>> getScheduledWorkouts({
    required DateTime start,
    required DateTime end,
  }) async {
    final apiWorkouts = await getWorkouts(start: start, end: end);

    return apiWorkouts
        .map((apiWorkout) => apiWorkout.toScheduledWorkout())
        .whereType<ScheduledWorkout>()
        .toList();
  }

  Future<List<ApiWorkout>> getWorkouts({
    required DateTime start,
    required DateTime end,
  }) async {
    final startDate = _formatDate(start);
    final endDate = _formatDate(end);

    final response = await http
        .get(
          Uri.parse(
            '$server/api/workouts'
            '?start=$startDate'
            '&end=$endDate',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: '
        '${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final rows = data['workouts'] as List<dynamic>? ?? const [];

    return rows
        .whereType<Map<String, dynamic>>()
        .map(ApiWorkout.fromJson)
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
