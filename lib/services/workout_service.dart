import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_workout.dart';
import '../models/scheduled_workout.dart';

import 'package:flutter/foundation.dart';

import '../utils/server_url.dart';

class WorkoutService {
  final String server;
  final String apiKey;

  const WorkoutService({required this.server, required this.apiKey});

  String get _server => normalizeServerUrl(server);

  Map<String, String> get _headers => {'X-API-Key': apiKey};

  Future<List<ScheduledWorkout>> getScheduledWorkouts({
    required DateTime start,
    required DateTime end,
  }) async {
    final apiWorkouts = await getWorkouts(start: start, end: end);

    final workouts = <ScheduledWorkout>[];

    for (final apiWorkout in apiWorkouts) {
      try {
        final scheduledWorkout = apiWorkout.toScheduledWorkout();

        if (scheduledWorkout != null) {
          workouts.add(scheduledWorkout);
        }
      } catch (e, stackTrace) {
        debugPrint(
          'Failed to parse workout '
          '${apiWorkout.id} (${apiWorkout.scheduledDate}): $e',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return workouts;
  }

  Future<Map<String, dynamic>> getWorkoutsRaw({
    required DateTime start,
    required DateTime end,
  }) async {
    final startDate = _formatDate(start);
    final endDate = _formatDate(end);

    final response = await http
        .get(
          Uri.parse(
            '$_server/api/workouts'
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

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Workout-Antwort');
    }

    return decoded;
  }

  Future<List<ApiWorkout>> getWorkouts({
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await getWorkoutsRaw(start: start, end: end);

    final rows = data['workouts'] as List<dynamic>? ?? const [];

    return rows
        .whereType<Map<String, dynamic>>()
        .map(ApiWorkout.fromJson)
        .toList();
  }

  Future<void> linkActivity({
    required int workoutId,
    required int endurainActivityId,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '$_server/api/workouts/'
            '$workoutId/activity-link',
          ),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode({'endurain_activity_id': endurainActivityId}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Aktivität konnte nicht mit dem Training '
        'verknüpft werden '
        '(HTTP ${response.statusCode}): '
        '${response.body}',
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
