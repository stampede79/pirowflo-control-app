import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/endurain_stream.dart';

class ActivityStreamService {
  final String server;
  final String apiKey;

  const ActivityStreamService({required this.server, required this.apiKey});

  Future<List<EndurainStream>> getActivityStreams(int activityId) async {
    final response = await http
        .get(
          Uri.parse('$server/api/activities/$activityId/streams'),
          headers: {'X-API-Key': apiKey},
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception(
        'Aktivitätsdaten konnten nicht geladen werden '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Stream-Antwort');
    }

    final rawStreams = json['streams'];

    if (rawStreams is! List) {
      throw const FormatException('Streams fehlen in der API-Antwort');
    }

    return rawStreams
        .whereType<Map<String, dynamic>>()
        .map(EndurainStream.fromJson)
        .where(
          (stream) =>
              stream.type == EndurainStreamType.heartRate ||
              stream.type == EndurainStreamType.power ||
              stream.type == EndurainStreamType.cadence,
        )
        .toList();
  }
}
