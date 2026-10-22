class EndurainSession {
  final String accessToken;
  final String refreshToken;
  final String sessionId;
  final int expiresIn;
  final int refreshTokenExpiresIn;

  const EndurainSession({
    required this.accessToken,
    required this.refreshToken,
    required this.sessionId,
    required this.expiresIn,
    required this.refreshTokenExpiresIn,
  });

  factory EndurainSession.fromJson(Map<String, dynamic> json) {
    return EndurainSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      sessionId: json['session_id'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      refreshTokenExpiresIn: (json['refresh_token_expires_in'] as num).toInt(),
    );
  }
}
