import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/rowing_metrics.dart';

class MetricsService {
  final String server;
  final String apiKey;

  const MetricsService({required this.server, required this.apiKey});

  Future<RowingMetrics> getMetrics() async {
    final response = await http
        .get(Uri.parse('$server/api/metrics'), headers: {'X-API-Key': apiKey})
        .timeout(const Duration(seconds: 2));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    return RowingMetrics.fromJson(json as Map<String, dynamic>);
  }
}
