import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:oauth_chopper/src/oauth_authenticator.dart';
import 'package:oauth_chopper/src/oauth_grant.dart';
import 'package:oauth_chopper/src/oauth_interceptor.dart';
import 'package:oauth_chopper/src/oauth_token.dart';
import 'package:oauth_chopper/src/storage/memory_storage.dart';
import 'package:oauth_chopper/src/storage/oauth_storage.dart';

/// OAuthChopper client for configuring OAuth authentication with [Chopper].
///
/// For example:
/// ```dart
///   final oauthChopper = OAuthChopper(
///     authorizationEndpoint: authorizationEndpoint,
///     identifier: identifier,
///     secret: secret,
///   );
/// ```
class OAuthChopper {
  /// OAuth authorization endpoint.
  final Uri authorizationEndpoint;

  /// OAuth endpoint to end session.
  final Uri? endSessionEndpoint;

  /// OAuth identifier
  final String identifier;

  /// OAuth secret.
  final String secret;

  /// OAuth storage for storing credentials.
  /// By default it will use a in memory storage. For persisting the credentials implement a custom [OAuthStorage].
  /// See [OAuthStorage] for more information.
  final OAuthStorage _storage;

  /// Provide a custom [http.Client] which will be passed to [oauth2] and used for making new requests.
  final http.Client? httpClient;

  OAuthChopper({
    required this.authorizationEndpoint,
    required this.identifier,
    required this.secret,
    this.endSessionEndpoint,
    this.httpClient,

    /// OAuth storage for storing credentials.
    /// By default it will use a in memory storage [MemoryStorage]. For persisting the credentials implement a custom [OAuthStorage].
    /// See [OAuthStorage] for more information.
    OAuthStorage? storage,
  }) : _storage = storage ?? MemoryStorage();

  /// Get stored [OAuthToken].
  Future<OAuthToken?> get token async {
    final credentialsJson = await _storage.fetchCredentials();
    return credentialsJson != null ? OAuthToken.fromJson(credentialsJson) : null;
  }

  /// Provides an [OAuthAuthenticator] instance.
  /// The authenticator can throw exceptions when OAuth authentication fails. If [onError] is provided exceptions will be passed to [onError] and not be thrown.
  OAuthAuthenticator authenticator({
    /// When provided [onError] handles exceptions if thrown.
    OnErrorCallback? onError,
  }) =>
      OAuthAuthenticator(this, onError);

  /// Provides an [OAuthInterceptor] instance.
  OAuthInterceptor get interceptor => OAuthInterceptor(this);

  /// Tries to refresh the available credentials and returns a new [OAuthToken] instance.
  /// Throws an exception when refreshing fails. If the exception is a [AuthorizationException] it clears the storage.
  /// See [Credentials.refresh]
  Future<OAuthToken?> refresh() async {
    final credentialsJson = await _storage.fetchCredentials();
    if (credentialsJson == null) return null;
    final credentials = oauth2.Credentials.fromJson(credentialsJson);
    try {
      final newCredentials = await credentials.refresh(
        identifier: identifier,
        secret: secret,
        httpClient: httpClient,
      );
      await _storage.saveCredentials(newCredentials.toJson());
      return OAuthToken.fromCredentials(newCredentials);
    } on oauth2.AuthorizationException {
      _storage.clear();
      rethrow;
    }
  }

  /// Request an [OAuthGrant] and stores the credentials in the [storage].
  /// Currently supported grants:
  ///  - [ResourceOwnerPasswordGrant]
  ///  - [ClientCredentialsGrant]
  ///  - [AuthorizationCodeGrant]
  /// Throws an exception if the grant fails.
  Future<OAuthToken> requestGrant(OAuthGrant grant) async {
    final credentials = await grant.handle(authorizationEndpoint, identifier, secret, httpClient);

    await _storage.saveCredentials(credentials);

    return OAuthToken.fromJson(credentials);
  }
}
