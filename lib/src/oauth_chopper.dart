import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:oauth_chopper/src/oauth_grant.dart';
import 'package:oauth_chopper/src/oauth_interceptor.dart';
import 'package:oauth_chopper/src/oauth_token.dart';
import 'package:oauth_chopper/src/storage/memory_storage.dart';
import 'package:oauth_chopper/src/storage/oauth_storage.dart';

/// {@template oauth_chopper}
/// OAuthChopper client for configuring OAuth authentication with Chopper.
///
/// For example:
/// ```dart
///   final oauthChopper = OAuthChopper(
///     authorizationEndpoint: authorizationEndpoint,
///     identifier: identifier,
///     secret: secret,
///   );
/// ```
/// {@endtemplate}
class OAuthChopper {
  /// {@macro oauth_chopper}
  OAuthChopper({
    required this.authorizationEndpoint,
    required this.identifier,
    this.secret,
    this.endSessionEndpoint,
    this.httpClient,
    this.scopes,
    this.basicAuth = true,
    this.delimiter,
    this.getParameters,

    /// OAuth storage for storing credentials.
    /// By default it will use a in memory storage [MemoryStorage].
    /// For persisting the credentials implement a custom [OAuthStorage].
    /// See [OAuthStorage] for more information.
    OAuthStorage? storage,
  }) : _storage = storage ?? MemoryStorage();

  /// OAuth authorization endpoint.
  final Uri authorizationEndpoint;

  /// OAuth endpoint to end session.
  final Uri? endSessionEndpoint;

  /// OAuth identifier
  final String identifier;

  /// OAuth secret.
  final String? secret;

  /// OAuth storage for storing credentials.
  /// By default it will use a in memory storage. For persisting the credentials
  /// implement a custom [OAuthStorage].
  /// See [OAuthStorage] for more information.
  final OAuthStorage _storage;

  /// Provide a custom [http.Client] which will be passed to [oauth2] and used
  /// for making new requests.
  final http.Client? httpClient;

  /// The scopes that the client is requesting access to.
  /// Will be passed to [oauth2].
  final Iterable<String>? scopes;

  /// Whether to use HTTP Basic authentication for authorizing the client.
  /// Will be passed to [oauth2].
  final bool basicAuth;

  /// A [String] used to separate scopes; defaults to `" "`.
  /// Will be passed to [oauth2].
  final String? delimiter;

  /// The function used to parse parameters from a host's response.
  /// Will be passed to [oauth2].
  final Map<String, dynamic> Function(MediaType? contentType, String body)?
      getParameters;

  /// Get stored [OAuthToken].
  Future<OAuthToken?> get token async {
    final credentialsJson = await _storage.fetchCredentials();
    return credentialsJson != null
        ? OAuthToken.fromJson(credentialsJson)
        : null;
  }

  /// Provides an [OAuthInterceptor] instance.
  /// If [onError] is provided exceptions will be passed to [onError] and not be
  /// thrown.
  OAuthInterceptor interceptor({
    OnErrorCallback? onError,
  }) =>
      OAuthInterceptor(this, onError);

  /// Tries to refresh the available credentials and returns a new [OAuthToken]
  /// instance.
  /// Throws an exception when refreshing fails. If the exception is a
  /// [oauth2.AuthorizationException] it clears the storage.
  ///
  /// See [oauth2.Credentials.refresh] for more information
  /// and information about [newScopes] and [basicAuth].
  Future<OAuthToken?> refresh({
    bool basicAuth = true,
    Iterable<String>? newScopes,
  }) async {
    final credentialsJson = await _storage.fetchCredentials();
    if (credentialsJson == null) return null;
    final credentials = oauth2.Credentials.fromJson(credentialsJson);
    try {
      final newCredentials = await credentials.refresh(
        identifier: identifier,
        secret: secret,
        newScopes: newScopes,
        basicAuth: basicAuth,
        httpClient: httpClient,
      );
      await _storage.saveCredentials(newCredentials.toJson());
      return OAuthToken.fromCredentials(newCredentials);
    } on oauth2.AuthorizationException {
      _storage.clear();
      rethrow;
    }
  }

  /// Request an [OAuthGrant] and stores the credentials in the
  /// [_storage].
  ///
  /// Currently supported grants:
  ///  - [ResourceOwnerPasswordGrant]
  ///  - [ClientCredentialsGrant]
  ///  - [AuthorizationCodeGrant]
  /// Throws an exception if the grant fails.
  Future<OAuthToken> requestGrant(OAuthGrant grant) async {
    final credentials = await grant.handle(
      authorizationEndpoint,
      identifier,
      secret: secret,
      httpClient: httpClient,
      scopes: scopes,
      getParameters: getParameters,
      delimiter: delimiter,
      basicAuth: basicAuth,
    );

    await _storage.saveCredentials(credentials);

    return OAuthToken.fromJson(credentials);
  }
}
