import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:oauth_chopper/src/extensions/request.dart';

/// Callback for error handling.
typedef OnErrorCallback = void Function(Object, StackTrace);

/// {@template oauth_interceptor}
/// OAuthInterceptor is responsible for adding 'Authorization' header to
/// requests.
/// The header is only added if there is a token available. When no token is
/// available no header is added.
/// Its added as a Bearer token.
///
/// When the token is expired it tries to proactively refresh before making the
/// request. When the server responds with 401 it also tries to refresh once.
/// Can throw a exceptions if no [onError] is passed. When [onError] is passed
/// exception will be passed to [onError]
/// {@endtemplate}
class OAuthInterceptor implements Interceptor {
  /// {@macro oauth_interceptor}
  OAuthInterceptor(this.oauthChopper, this.onError);

  /// Callback for error handling.
  final OnErrorCallback? onError;

  /// The [OAuthChopper] instance to get the token from.
  final OAuthChopper oauthChopper;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    // Get the current token.
    var token = await oauthChopper.token;

    // If the token is expired, proactively refresh before making the request.
    if (token != null && token.isExpired) {
      try {
        final refreshed = await oauthChopper.refresh();
        if (refreshed != null) {
          token = refreshed;
        }
      } catch (e, s) {
        if (onError != null) {
          onError!(e, s);
        } else {
          rethrow;
        }
      }
    }

    // Add oauth token to the request.
    final Request request;
    if (token == null) {
      request = chain.request;
    } else {
      request = chain.request.addAuthorizationHeader(token.accessToken);
    }

    final response = await chain.proceed(request);

    // If the response is unauthorized and a token is available try to
    // refresh 1 time.
    if (response.statusCode == 401 && token != null) {
      try {
        final credentials = await oauthChopper.refresh();
        if (credentials != null) {
          final retryRequest = chain.request.addAuthorizationHeader(
            credentials.accessToken,
          );
          return chain.proceed(retryRequest);
        }
      } catch (e, s) {
        if (onError != null) {
          onError!(e, s);
        } else {
          rethrow;
        }
      }
    }

    return response;
  }
}
