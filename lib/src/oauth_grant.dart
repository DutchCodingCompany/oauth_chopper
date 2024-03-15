import 'package:oauth2/oauth2.dart' as oauth;

/// {@template oauth_grant}
/// Interface for a OAuth grant.
/// Grants are used to obtain credentials from an authorization server.
/// {@endtemplate}
abstract interface class OAuthGrant {
  /// {@macro oauth_grant}
  const OAuthGrant();

  /// Obtains credentials from an authorization server.
  Future<String> handle(Uri authorizationEndpoint, String identifier, String secret);
}

/// {@template resource_owner_password_grant}
/// Obtains credentials using a [resource owner password grant](https://tools.ietf.org/html/rfc6749#section-1.3.3).
///
/// This grant uses the resource owner's [username] and [password] to obtain
/// credentials.
/// {@endtemplate}
class ResourceOwnerPasswordGrant implements OAuthGrant {
  /// {@macro resource_owner_password_grant}
  const ResourceOwnerPasswordGrant({
    required this.username,
    required this.password,
  });

  /// Username used for obtaining credentials.
  final String username;

  /// Password used for obtaining credentials.
  final String password;

  @override
  Future<String> handle(Uri authorizationEndpoint, String identifier, String secret) async {
    final client = await oauth.resourceOwnerPasswordGrant(
      authorizationEndpoint,
      username,
      password,
      secret: secret,
      identifier: identifier,
    );
    return client.credentials.toJson();
  }
}

/// {@template client_credentials_grant}
/// Obtains credentials using a [client credentials grant](https://tools.ietf.org/html/rfc6749#section-1.3.4).
/// {@endtemplate}
class ClientCredentialsGrant implements OAuthGrant {
  /// {@macro client_credentials_grant}
  const ClientCredentialsGrant();

  @override
  Future<String> handle(Uri authorizationEndpoint, String identifier, String secret) async {
    final client = await oauth.clientCredentialsGrant(
      authorizationEndpoint,
      identifier,
      secret,
    );
    return client.credentials.toJson();
  }
}

/// {@template authorization_code_grant}
/// Obtains credentials using a [authorization code grant](https://tools.ietf.org/html/rfc6749#section-1.3.1).
/// {@endtemplate}
class AuthorizationCodeGrant implements OAuthGrant {
  /// {@macro authorization_code_grant}
  const AuthorizationCodeGrant({
    required this.tokenEndpoint,
    required this.scopes,
    required this.redirectUrl,
    required this.redirect,
    required this.listen,
  });

  /// A URL provided by the authorization server that this library uses to
  /// obtain long-lasting credentials.
  ///
  /// This will usually be listed in the authorization server's OAuth2 API
  /// documentation.
  final Uri tokenEndpoint;

  /// The redirect URL where the resource owner will redirect to.
  final Uri redirectUrl;

  /// The specific permissions being requested from the authorization server may
  /// be specified via [scopes].
  final List<String> scopes;
  /// Callback used for redirect the authorizationUrl given by the authorization
  /// server.
  final Future<void> Function(Uri authorizationUri) redirect;
  /// Callback used for listening for the redirectUrl.
  final Future<Uri> Function(Uri redirectUri) listen;

  @override
  Future<String> handle(
    Uri authorizationEndpoint,
    String identifier,
    String secret,
  ) async {
    final grant = oauth.AuthorizationCodeGrant(
      identifier,
      authorizationEndpoint,
      tokenEndpoint,
    );

    final authorizationUrl = grant.getAuthorizationUrl(
      redirectUrl,
      scopes: scopes,
    );

    await redirect(authorizationUrl);
    final responseUrl = await listen(redirectUrl);

    final oauth.Client client = await grant.handleAuthorizationResponse(
      responseUrl.queryParameters,
    );

    return client.credentials.toJson();
  }
}
