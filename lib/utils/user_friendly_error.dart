import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

class UserFriendlyError {
  static String nextcloud(Object error) {
    return _networkError(
      error,
      service: 'Nextcloud',
      fallback: 'Der Trainingskalender konnte nicht geladen werden.',
    );
  }

  static String endurain(Object error) {
    return _networkError(
      error,
      service: 'Endurain',
      fallback: 'Endurain-Daten konnten nicht geladen werden.',
    );
  }

  static String piRowFlo(Object error) {
    return _networkError(
      error,
      service: 'PiRowFlo',
      fallback: 'PiRowFlo ist momentan nicht erreichbar.',
    );
  }

  static String _networkError(
    Object error, {
    required String service,
    required String fallback,
  }) {
    if (error is TimeoutException) {
      return '$service antwortet momentan nicht.';
    }

    if (error is SocketException) {
      return '$service ist momentan nicht erreichbar.';
    }

    if (error is HandshakeException) {
      return 'Die sichere Verbindung zu $service konnte nicht '
          'hergestellt werden.';
    }

    if (error is http.ClientException) {
      return '$service ist momentan nicht erreichbar.';
    }

    final message = error.toString();

    if (message.contains('HTTP 401') || message.contains('HTTP 403')) {
      return 'Die Anmeldung bei $service ist fehlgeschlagen.';
    }

    if (RegExp(r'HTTP 5\d\d').hasMatch(message)) {
      return '$service meldet momentan einen Serverfehler.';
    }

    return fallback;
  }
}
