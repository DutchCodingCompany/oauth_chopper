import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:oauth2/oauth2.dart';

/// {@template oauth_grant}
/// Interface for a OAuth grant.
/// Grants are used to obtain credentials from an authorization server.
///
/// Currently available grants:
/// - [ResourceOwnerPasswordGrant]
/// - [ClientCredentialsGrant]
/// - [AuthorizationCodeGrant]
///
/// {@endtemplate}
// ignore because we need this interface.
// ignore: one_member_abstracts
abstract interface class OAuthGrant {
  /// {@macro oauth_grant}
  const OAuthGrant();

  /// Obtains credentials from an authorization server.
  Future<String> handle(
    Uri authorizationEndpoint,
    String identifier, {
    String? secret,
    http.Client? httpClient,
    Iterable<String>? scopes,
    bool basicAuth = true,
    String? delimiter,
    Map<String, dynamic> Function(MediaType? contentType, String body)?
        getParameters,
  });
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
    this.onCredentialsRefreshed,
  });

  /// Username used for obtaining credentials.
  final String username;

  /// Password used for obtaining credentials.
  final String password;

  /// Callback to be invoked whenever the credentials are refreshed.
  ///
  /// This will be passed as-is to the constructed [Client].
  /// Will be passed to [oauth2].
  final CredentialsRefreshedCallback? onCredentialsRefreshed;

  @override
  Future<String> handle(
    Uri authorizationEndpoint,
    String identifier, {
    String? secret,
    http.Client? httpClient,
    Iterable<String>? scopes,
    bool basicAuth = true,
    String? delimiter,
    Map<String, dynamic> Function(MediaType? contentType, String body)?
        getParameters,
  }) async {
    final client = await oauth2.resourceOwnerPasswordGrant(
      authorizationEndpoint,
      username,
      password,
      secret: secret,
      identifier: identifier,
      scopes: scopes,
      basicAuth: basicAuth,
      delimiter: delimiter,
      httpClient: httpClient,
      getParameters: getParameters,
      onCredentialsRefreshed: onCredentialsRefreshed,
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
  Future<String> handle(
    Uri authorizationEndpoint,
    String identifier, {
    String? secret,
    http.Client? httpClient,
    Iterable<String>? scopes,
    bool basicAuth = true,
    String? delimiter,
    Map<String, dynamic> Function(MediaType? contentType, String body)?
        getParameters,
  }) async {
    final client = await oauth2.clientCredentialsGrant(
      authorizationEndpoint,
      identifier,
      secret,
      scopes: scopes,
      basicAuth: basicAuth,
      delimiter: delimiter,
      httpClient: httpClient,
      getParameters: getParameters,
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
    required this.redirectUrl,
    required this.redirect,
    required this.listen,
    this.onCredentialsRefreshed,
    this.codeVerifier,
  });

  /// A URL provided by the authorization server that this library uses to
  /// obtain long-lasting credentials.
  ///
  /// This will usually be listed in the authorization server's OAuth2 API
  /// documentation.
  final Uri tokenEndpoint;

  /// The redirect URL where the resource owner will redirect to.
  final Uri redirectUrl;

  /// Callback to be invoked whenever the credentials are refreshed.
  ///
  /// This will be passed as-is to the constructed [Client].
  /// Will be passed to [oauth2].
  final CredentialsRefreshedCallback? onCredentialsRefreshed;

  /// The PKCE code verifier. Will be generated if one is not provided in the
  /// constructor.
  /// Will be passed to [oauth2].
  final String? codeVerifier;

  /// Callback used for redirect the authorizationUrl given by the authorization
  /// server.
  final Future<void> Function(Uri authorizationUri) redirect;

  /// Callback used for listening for the redirectUrl.
  final Future<Uri> Function(Uri redirectUri) listen;

  @override
  Future<String> handle(
    Uri authorizationEndpoint,
    String identifier, {
    String? secret,
    http.Client? httpClient,
    Iterable<String>? scopes,
    bool basicAuth = true,
    String? delimiter,
    Map<String, dynamic> Function(MediaType? contentType, String body)?
        getParameters,
  }) async {
    final grant = oauth2.AuthorizationCodeGrant(
      identifier,
      authorizationEndpoint,
      tokenEndpoint,
      basicAuth: basicAuth,
      delimiter: delimiter,
      getParameters: getParameters,
      secret: secret,
      httpClient: httpClient,
      onCredentialsRefreshed: onCredentialsRefreshed,
      codeVerifier: codeVerifier,
    );

    final authorizationUrl = grant.getAuthorizationUrl(
      redirectUrl,
      scopes: scopes,
    );

    await redirect(authorizationUrl);
    final responseUrl = await listen(redirectUrl);

    final client = await grant.handleAuthorizationResponse(
      responseUrl.queryParameters,
    );

    return client.credentials.toJson();
  }
}
