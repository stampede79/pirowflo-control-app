import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/coach_overview.dart';

class CoachService {
  final String server;
  final String apiKey;

  const CoachService({required this.server, required this.apiKey});

  String get _server =>
      server.endsWith('/') ? server.substring(0, server.length - 1) : server;

  Map<String, String> get _headers => {'X-API-Key': apiKey};

  Map<String, String> get _jsonHeaders => {
    ..._headers,
    'Content-Type': 'application/json',
  };

  Future<CoachOverview> getOverview() async {
    final response = await http
        .get(Uri.parse('$_server/api/coach/overview'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Coach-Übersicht konnte nicht geladen werden '
        '(HTTP ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Coach-Antwort');
    }

    return CoachOverview.fromJson(decoded);
  }

  Future<void> decideRecommendation(
    int recommendationId,
    String decision,
  ) async {
    final response = await http
        .post(
          Uri.parse(
            '$_server/api/coach/recommendations/'
            '$recommendationId/decision',
          ),
          headers: _jsonHeaders,
          body: jsonEncode({'decision': decision}),
        )
        .timeout(const Duration(seconds: 20));

    _requireSuccess(
      response,
      'Coach-Entscheidung konnte nicht gespeichert werden',
    );
  }

  Future<void> answerAvailability(int recommendationId, String status) async {
    final response = await http
        .post(
          Uri.parse(
            '$_server/api/coach/recommendations/'
            '$recommendationId/availability',
          ),
          headers: _jsonHeaders,
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 10));

    _requireSuccess(response, 'Verfügbarkeit konnte nicht gespeichert werden');
  }

  void _requireSuccess(http.Response response, String message) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      '$message '
      '(HTTP ${response.statusCode}): '
      '${response.body}',
    );
  }
}
