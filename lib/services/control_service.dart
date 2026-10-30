import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pirowflo_status.dart';

class ControlService {
  final String server;
  final String apiKey;

  const ControlService({required this.server, required this.apiKey});

  String get _server =>
      server.endsWith('/') ? server.substring(0, server.length - 1) : server;

  Map<String, String> get _headers => {'X-API-Key': apiKey};

  Future<PiRowFloStatus> getStatus({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final response = await http
        .get(Uri.parse('$_server/api/status'), headers: _headers)
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Ungültige PiRowFlo-Status-Antwort');
    }

    return PiRowFloStatus.fromJson(decoded);
  }

  Future<void> post(
    String path, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await http
        .post(Uri.parse('$_server$path'), headers: _headers)
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
