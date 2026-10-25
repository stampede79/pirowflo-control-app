import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/endurain_session.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/endurain_summary.dart';
import '../models/endurain_activity.dart';
import '../models/endurain_stream.dart';

class EndurainService {
  final String server;
  final FlutterSecureStorage storage;

  const EndurainService({
    required this.server,
    this.storage = const FlutterSecureStorage(),
  });

  String get _baseUrl {
    final normalized = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;

    return '$normalized/api/v1';
  }

  int _userIdFromAccessToken(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        throw const FormatException('Ungültiges JWT');
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final json = jsonDecode(payload);

      if (json is! Map<String, dynamic>) {
        throw const FormatException('Ungültiger JWT-Payload');
      }

      final sub = json['sub'];

      if (sub is int) {
        return sub;
      }

      final parsed = int.tryParse(sub?.toString() ?? '');

      if (parsed == null) {
        throw const FormatException('Endurain User-ID fehlt im Access-Token');
      }

      return parsed;
    } catch (e) {
      throw FormatException(
        'Endurain User-ID konnte nicht ermittelt werden: $e',
      );
    }
  }

  Future<EndurainSession> login({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: const {
            'X-Client-Type': 'mobile',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'username': username, 'password': password},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      String detail = response.body;

      try {
        final json = jsonDecode(response.body);

        if (json is Map<String, dynamic> && json['detail'] != null) {
          detail = json['detail'].toString();
        }
      } catch (_) {
        // Antwort war kein JSON.
      }

      throw Exception(
        'Endurain Login fehlgeschlagen '
        '(HTTP ${response.statusCode}): $detail',
      );
    }

    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Endurain Login-Antwort');
    }

    return EndurainSession.fromJson(json);
  }

  Future<EndurainSession> refresh({required String refreshToken}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/refresh'),
          headers: {
            'X-Client-Type': 'mobile',
            'Authorization': 'Bearer $refreshToken',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      String detail = response.body;

      try {
        final json = jsonDecode(response.body);

        if (json is Map<String, dynamic> && json['detail'] != null) {
          detail = json['detail'].toString();
        }
      } catch (_) {
        // Antwort war kein JSON.
      }

      throw Exception(
        'Endurain Login fehlgeschlagen '
        '(HTTP ${response.statusCode}): $detail',
      );
    }

    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Endurain Refresh-Antwort');
    }

    return EndurainSession.fromJson(json);
  }

  Future<void> saveSession(EndurainSession session) async {
    await storage.write(key: 'endurainAccessToken', value: session.accessToken);

    await storage.write(
      key: 'endurainRefreshToken',
      value: session.refreshToken,
    );

    await storage.write(key: 'endurainSessionId', value: session.sessionId);
  }

  Future<bool> refreshStoredSession() async {
    final refreshToken = await storage.read(key: 'endurainRefreshToken');

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final session = await refresh(refreshToken: refreshToken);

      await saveSession(session);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> authenticatedGet(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    var accessToken = await storage.read(key: 'endurainAccessToken');

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Keine Endurain-Session vorhanden.');
    }

    Uri buildUri() {
      return Uri.parse('$_baseUrl$path')
          .replace(queryParameters: queryParameters);
    }

    Future<http.Response> request(String token) {
      return http
          .get(
            buildUri(),
            headers: {
              'Authorization': 'Bearer $token',
              'X-Client-Type': 'mobile',
            },
          )
          .timeout(const Duration(seconds: 15));
    }

    var response = await request(accessToken);

    if (response.statusCode != 401) {
      return response;
    }

    final refreshed = await refreshStoredSession();

    if (!refreshed) {
      throw Exception(
        'Endurain-Sitzung ist abgelaufen. '
        'Bitte erneut anmelden.',
      );
    }

    accessToken = await storage.read(key: 'endurainAccessToken');

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Endurain Access-Token fehlt nach dem Refresh.');
    }

    // Ursprünglichen Request genau einmal wiederholen.
    response = await request(accessToken);

    return response;
  }

  Future<EndurainSummary> getRowingSummary(EndurainSummaryPeriod period) async {
    final response = await authenticatedGet(
      '/activities_summaries/${period.apiValue}',
      queryParameters: const {'type': 'indoor_rowing'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Endurain Statistik fehlgeschlagen '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw const FormatException('Ungültige Endurain Statistik-Antwort');
    }

    return EndurainSummary.fromJson(json);
  }

  Future<List<EndurainActivity>> getRecentRowingActivities({
    int limit = 10,
  }) async {
    // Endurain liefert die Activities seitenweise.
    // Wir holen etwas mehr, weil zwischen den Rudertrainings
    // auch andere Aktivitäten liegen können.
    final accessToken = await storage.read(key: 'endurainAccessToken');

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Keine Endurain-Session vorhanden.');
    }

    final userId = _userIdFromAccessToken(accessToken);

    final response = await authenticatedGet(
      '/activities/user/$userId/page_number/1/num_records/50',
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Endurain Aktivitäten konnten nicht geladen werden '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body);

    if (json is! List) {
      throw const FormatException('Ungültige Endurain Aktivitäten-Antwort');
    }

    return json
        .whereType<Map<String, dynamic>>()
        .map(EndurainActivity.fromJson)
        .where((activity) => activity.activityType == 13)
        .take(limit)
        .toList();
  }

  Future<List<EndurainActivity>> getRowingActivitiesForRange(
    DateTime start,
    DateTime end,
  ) async {
    final accessToken = await storage.read(key: 'endurainAccessToken');

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Keine Endurain-Session vorhanden.');
    }

    final userId = _userIdFromAccessToken(accessToken);

    final rangeStart = start.toLocal();
    final rangeEnd = end.toLocal();

    const pageSize = 50;
    const maxPages = 20;

    final activities = <EndurainActivity>[];

    for (var page = 1; page <= maxPages; page++) {
      final response = await authenticatedGet(
        '/activities/user/$userId/'
        'page_number/$page/'
        'num_records/$pageSize',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Endurain Aktivitäten konnten nicht geladen werden '
          '(HTTP ${response.statusCode}): ${response.body}',
        );
      }

      final json = jsonDecode(response.body);

      if (json is! List) {
        throw const FormatException('Ungültige Endurain Aktivitäten-Antwort');
      }

      if (json.isEmpty) {
        break;
      }

      final pageActivities = json
          .whereType<Map<String, dynamic>>()
          .map(EndurainActivity.fromJson)
          .toList();

      for (final activity in pageActivities) {
        if (activity.activityType != 13) {
          continue;
        }

        final activityStart = activity.startTime.toLocal();

        if (!activityStart.isBefore(rangeStart) &&
            activityStart.isBefore(rangeEnd)) {
          activities.add(activity);
        }
      }

      // Wenn bereits irgendeine Activity dieser Seite älter als unser
      // Startdatum ist, brauchen wir keine noch älteren Seiten mehr.
      final reachedStart = pageActivities.any(
        (activity) => activity.startTime.toLocal().isBefore(rangeStart),
      );

      if (reachedStart || pageActivities.length < pageSize) {
        break;
      }
    }

    activities.sort((a, b) => b.startTime.compareTo(a.startTime));

    return activities;
  }

  Future<List<EndurainStream>> getActivityStreams(int activityId) async {
    final response = await authenticatedGet(
      '/activities_streams/activity_id/$activityId/all',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Endurain Streams konnten nicht geladen werden '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body);

    if (json is! List) {
      throw const FormatException('Ungültige Endurain Stream-Antwort');
    }

    return json
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
