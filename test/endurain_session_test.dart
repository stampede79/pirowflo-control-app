import 'package:flutter_test/flutter_test.dart';
import 'package:pirowflo_control/models/endurain_session.dart';

void main() {
  test('parst Endurain Mobile Session', () {
    final session = EndurainSession.fromJson({
      'session_id': 'session-123',
      'access_token': 'access-123',
      'refresh_token': 'refresh-123',
      'token_type': 'bearer',
      'expires_in': 900,
      'refresh_token_expires_in': 604800,
    });

    expect(session.sessionId, 'session-123');
    expect(session.accessToken, 'access-123');
    expect(session.refreshToken, 'refresh-123');
    expect(session.expiresIn, 900);
    expect(session.refreshTokenExpiresIn, 604800);
  });
}
