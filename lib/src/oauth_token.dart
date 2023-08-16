import 'package:oauth2/oauth2.dart';

class OAuthToken {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiration;
  final String? idToken;

  bool get isExpired =>
      expiration != null && DateTime.now().isAfter(expiration!);

  const OAuthToken._(
    this.accessToken,
    this.refreshToken,
    this.expiration,
    this.idToken,
  );

  factory OAuthToken.fromJson(String json) {
    final credentials = Credentials.fromJson(json);
    return OAuthToken.fromCredentials(credentials);
  }

  factory OAuthToken.fromCredentials(Credentials credentials) => OAuthToken._(
        credentials.accessToken,
        credentials.refreshToken,
        credentials.expiration,
        credentials.idToken,
      );
}
