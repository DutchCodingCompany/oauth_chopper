import 'dart:async';

import 'package:oauth_chopper/oauth_chopper.dart';

class MemoryStorage implements OAuthStorage {
  String? _credentials;

  @override
  FutureOr<void> clear() {
    _credentials = null;
  }

  @override
  FutureOr<String?> fetchCredentials() {
    return _credentials;
  }

  @override
  FutureOr<void> saveCredentials(String? credentialsJson) {
    _credentials = credentialsJson;
  }
}
