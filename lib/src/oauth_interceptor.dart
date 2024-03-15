import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:oauth_chopper/src/extensions/request.dart';

/// {@template oauth_interceptor}
/// OAuthInterceptor is responsible for adding 'Authorization' header to
/// requests.
/// The header is only added if there is a token available. When no token is
/// available no header is added.
/// Its added as a Bearer token.
/// {@endtemplate}
class OAuthInterceptor implements RequestInterceptor {
  /// {@macro oauth_interceptor}
  OAuthInterceptor(this.oauthChopper);

  /// The [OAuthChopper] instance to get the token from.
  final OAuthChopper oauthChopper;

  @override
  FutureOr<Request> onRequest(Request request) async {
    final token = await oauthChopper.token;
    if (token == null) return request;
    return request.addAuthorizationHeader(token.accessToken);
  }
}
