import 'package:oauth2/oauth2.dart' as oauth;

abstract class OAuthGrant {
  const OAuthGrant();

  Future<String> handle(
      Uri authorizationEndpoint, String identifier, String secret);
}

/// Obtains credentials using a [resource owner password grant](https://tools.ietf.org/html/rfc6749#section-1.3.3).
class ResourceOwnerPasswordGrant extends OAuthGrant {
  final String username;
  final String password;

  const ResourceOwnerPasswordGrant(
      {required this.username, required this.password});

  @override
  Future<String> handle(
      Uri authorizationEndpoint, String identifier, String secret) async {
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
  Future<String> handle(
      Uri authorizationEndpoint, String identifier, String secret) async {
    final client = await oauth.clientCredentialsGrant(
      authorizationEndpoint,
      identifier,
      secret,
    );
    return client.credentials.toJson();
  }
}

//TODO: Add AuthorizationCodeGrant
