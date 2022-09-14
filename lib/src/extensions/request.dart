import 'package:chopper/chopper.dart';

extension ChopperRequest on Request {
  Request addAuthorizationHeader(String token) {
    final newHeaders = Map<String, String>.from(headers);
    newHeaders['Authorization'] = 'Bearer $token';
    return copyWith(headers: newHeaders);
  }
}
