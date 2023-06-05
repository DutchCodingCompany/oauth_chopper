import 'package:oauth2/oauth2.dart' as oauth;

abstract class OAuthGrant {
  const OAuthGrant();

  Future<String> handle(Uri authorizationEndpoint, String identifier, String secret);
}

/// Obtains credentials using a [resource owner password grant](https://tools.ietf.org/html/rfc6749#section-1.3.3).
class ResourceOwnerPasswordGrant extends OAuthGrant {
  final String username;
  final String password;

  const ResourceOwnerPasswordGrant({required this.username, required this.password});

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

/// Obtains credentials using a [client credentials grant](https://tools.ietf.org/html/rfc6749#section-1.3.4).
class ClientCredentialsGrant extends OAuthGrant {
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

/// Obtains credentials using a [authorization code grant](https://tools.ietf.org/html/rfc6749#section-1.3.1).
class AuthorizationCodeGrant extends OAuthGrant {
  const AuthorizationCodeGrant(
    this.tokenEndpoint,
    this.scopes,
    this.redirectUrl,
    this.redirect,
    this.listen,
  );

  final Uri tokenEndpoint;
  final Uri redirectUrl;
  final List<String> scopes;
  final Future<void> Function(Uri authorizationUri) redirect;
  final Future<Uri> Function(Uri redirectUri) listen;

  @override
  Future<String> handle(Uri authorizationEndpoint, String identifier, String secret) async {
    final grant = oauth.AuthorizationCodeGrant(
      identifier,
      authorizationEndpoint,
      tokenEndpoint,
    );
    var authorizationUrl = grant.getAuthorizationUrl(redirectUrl, scopes: scopes);
    await redirect(authorizationUrl);
    var responseUrl = await listen(redirectUrl);
    oauth.Client client = await grant.handleAuthorizationResponse(responseUrl.queryParameters);

    return client.credentials.toJson();
  }
}
