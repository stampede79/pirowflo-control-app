import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/rowing_metrics.dart';
import '../utils/server_url.dart';

class MetricsService {
  final String server;
  final String apiKey;

  const MetricsService({required this.server, required this.apiKey});

  String get _server => normalizeServerUrl(server);

  Future<RowingMetrics> getMetrics() async {
    final response = await http
        .get(Uri.parse('$_server/api/metrics'), headers: {'X-API-Key': apiKey})
        .timeout(const Duration(seconds: 2));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Metrik-Antwort');
    }

    return RowingMetrics.fromJson(decoded);
  }

  Future<void> resetSmartRow() async {
    final response = await http
        .post(Uri.parse('$_server/api/reset'), headers: {'X-API-Key': apiKey})
        .timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
  }
}
