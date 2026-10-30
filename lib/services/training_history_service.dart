import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/workout_analysis.dart';
import '../utils/server_url.dart';

class TrainingHistoryService {
  final String server;
  final String apiKey;

  const TrainingHistoryService({required this.server, required this.apiKey});

  String get _server => normalizeServerUrl(server);

  Future<Map<int, WorkoutAnalysis>> getAnalyses({
    required DateTime start,
    required DateTime end,
  }) async {
    final startDate = _formatDate(start);
    final endDate = _formatDate(end);

    final response = await http
        .get(
          Uri.parse(
            '$_server/api/training-history'
            '?start=$startDate'
            '&end=$endDate',
          ),
          headers: {'X-API-Key': apiKey},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Trainingshistorie-Antwort');
    }

    final entries = decoded['entries'] as List<dynamic>? ?? const [];

    final result = <int, WorkoutAnalysis>{};

    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      final activity = entry['activity'];
      final analysis = entry['analysis'];

      if (activity is! Map<String, dynamic> ||
          analysis is! Map<String, dynamic>) {
        continue;
      }

      final endurainActivityId = (activity['endurain_activity_id'] as num?)
          ?.toInt();

      if (endurainActivityId == null) {
        continue;
      }

      result[endurainActivityId] = WorkoutAnalysis.fromJson(analysis);
    }

    return result;
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
