import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:oauth_chopper/src/extensions/request.dart';

typedef OnErrorCallback = void Function(Object, StackTrace);

/// OAuthAuthenticator provides a authenticator that handles OAuth authorizations.
/// When the provided credentials are invalid it tries to refresh them.
/// Can throw a exceptions if no [onError] is passed. When [onError] is passed exception will be passed to [onError]
class OAuthAuthenticator extends Authenticator {
  OAuthAuthenticator(this.oauthChopper, this.onError);

  final OnErrorCallback? onError;
  final OAuthChopper oauthChopper;

  @override
  FutureOr<Request?> authenticate(Request request, Response<dynamic> response, [Request? originalRequest]) async {
    final token = await oauthChopper.token;
    if (response.statusCode == HttpStatus.unauthorized && token != null) {
      try {
        final credentials = await oauthChopper.refresh();
        if (credentials != null) {
          return request.addAuthorizationHeader(credentials.accessToken);
        }
      } catch (e, s) {
        if (onError != null) {
          onError?.call(e, s);
        } else {
          rethrow;
        }
      }
    }
    return null;
  }
}
