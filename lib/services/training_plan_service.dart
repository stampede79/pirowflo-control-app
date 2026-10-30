import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/training_plan_draft.dart';
import '../models/training_plan_review.dart';
import '../utils/server_url.dart';

class TrainingPlanService {
  final String server;
  final String apiKey;

  const TrainingPlanService({required this.server, required this.apiKey});

  String get _server => normalizeServerUrl(server);

  Future<TrainingPlanReview?> getReview() async {
    final response = await http
        .get(
          Uri.parse('$_server/api/training-plan/review'),
          headers: {'X-API-Key': apiKey},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Trainingsplan-Review konnte nicht '
        'geladen werden '
        '(HTTP ${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Trainingsplan-Review-Antwort');
    }

    if (json['available'] != true) {
      return null;
    }

    final review = json['review'];

    if (review is! Map<String, dynamic>) {
      throw const FormatException('Ungültiger Trainingsplan-Review');
    }

    return TrainingPlanReview.fromJson(review);
  }

  Future<TrainingPlanDraft?> getDraft() async {
    final response = await http
        .get(
          Uri.parse('$_server/api/training-plan/draft'),
          headers: {'X-API-Key': apiKey},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Trainingsplan konnte nicht geladen werden '
        '(HTTP ${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Trainingsplan-Antwort');
    }

    if (json['available'] != true) {
      return null;
    }

    final draft = json['draft'];

    if (draft is! Map<String, dynamic>) {
      throw const FormatException('Ungültiger Trainingsplan-Draft');
    }

    return TrainingPlanDraft.fromJson(draft);
  }

  Future<void> applyReview() async {
    final response = await http
        .post(
          Uri.parse('$_server/api/training-plan/review/apply'),
          headers: {'X-API-Key': apiKey},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String detail = response.body;

    try {
      final json = jsonDecode(response.body);

      if (json is Map<String, dynamic> && json['detail'] != null) {
        detail = json['detail'].toString();
      }
    } catch (_) {
      // Kein JSON.
    }

    throw Exception(
      'Plananpassung konnte nicht übernommen werden '
      '(HTTP ${response.statusCode}): $detail',
    );
  }

  Future<void> applyDraft() async {
    final response = await http
        .post(
          Uri.parse('$_server/api/training-plan/draft/apply'),
          headers: {'X-API-Key': apiKey},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String detail = response.body;

    try {
      final json = jsonDecode(response.body);

      if (json is Map<String, dynamic> && json['detail'] != null) {
        detail = json['detail'].toString();
      }
    } catch (_) {
      // Kein JSON.
    }

    throw Exception(
      'Trainingsplan konnte nicht übernommen werden '
      '(HTTP ${response.statusCode}): $detail',
    );
  }
}
