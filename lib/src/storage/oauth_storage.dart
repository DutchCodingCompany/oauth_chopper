import 'dart:async';

abstract class OAuthStorage {
  const OAuthStorage();

  /// Fetch stored credentials.
  FutureOr<String?> fetchCredentials();

  /// Save newly obtained credentials. This is called when authentication or refreshing tokens succeeds.
  FutureOr<void> saveCredentials(String? credentialsJson);

  /// Clear any stored credential. This is called when authentication fails.
  FutureOr<void> clear();
}
