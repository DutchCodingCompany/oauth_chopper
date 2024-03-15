import 'package:oauth2/oauth2.dart';

/// {@template oauth_token}
/// A wrapper around [Credentials] to provide a more convenient API.
/// {@endtemplate}
class OAuthToken {
  /// {@macro oauth_token}
  const OAuthToken._(
    this.accessToken,
    this.refreshToken,
    this.expiration,
    this.idToken,
  );

  /// Creates a new instance of [OAuthToken] from a JSON string.
  /// {@macro oauth_token}
  factory OAuthToken.fromJson(String json) {
    final credentials = Credentials.fromJson(json);
    return OAuthToken.fromCredentials(credentials);
  }

  /// Creates a new instance of [OAuthToken] from [Credentials].
  /// {@macro oauth_token}
  factory OAuthToken.fromCredentials(Credentials credentials) => OAuthToken._(
        credentials.accessToken,
        credentials.refreshToken,
        credentials.expiration,
        credentials.idToken,
      );

  /// The token that is sent to the resource server to prove the authorization
  /// of a client.
  final String accessToken;

  /// The token that is sent to the authorization server to refresh the
  /// credentials.
  ///
  /// This may be `null`, indicating that the credentials can't be refreshed.
  final String? refreshToken;

  /// The date at which these credentials will expire.
  ///
  /// This is likely to be a few seconds earlier than the server's idea of the
  /// expiration date.
  final DateTime? expiration;

  /// The token that is received from the authorization server to enable
  /// End-Users to be Authenticated, contains Claims, represented as a
  /// JSON Web Token (JWT).
  ///
  /// This may be `null`, indicating that the 'openid' scope was not
  /// requested (or not supported).
  ///
  /// [spec]: https://openid.net/specs/openid-connect-core-1_0.html#IDToken
  final String? idToken;

  /// Whether the token is expired.
  bool get isExpired =>
      expiration != null &&
      DateTime.now().isAfter(
        expiration!,
      );
}
