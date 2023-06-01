// ignore_for_file: unused_local_variable

import 'package:chopper/chopper.dart';
import 'package:oauth_chopper/oauth_chopper.dart';

void main() {
  final authorizationEndpoint = Uri.parse('https://example.com/oauth');
  final identifier = 'id';
  final secret = 'secret';

  /// Create OAuthChopper instance.
  final oauthChopper = OAuthChopper(
    authorizationEndpoint: authorizationEndpoint,
    identifier: identifier,
    secret: secret,
  );

  /// Add the oauth authenticator and interceptor to the chopper client.
  final chopperClient = ChopperClient(
    baseUrl: Uri(host: 'https://example.com'),
    authenticator: oauthChopper.authenticator(),
    interceptors: [
      oauthChopper.interceptor,
    ],
  );

  /// Request grant
  oauthChopper.requestGrant(
    ResourceOwnerPasswordGrant(
      username: 'username',
      password: 'password',
    ),
  );
}
