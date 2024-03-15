import 'package:chopper/chopper.dart';

/// Helper extension to easily apply a authorization header to a request.
extension ChopperRequest on Request {
  /// Adds a authorization header with a bearer [token] to the request.
  Request addAuthorizationHeader(String token) => applyHeader(
        this,
        'Authorization',
        'Bearer $token',
      );
}
