---
name: oauth-chopper-storage
description: Implement persistent token storage for `oauth_chopper` by creating a custom `OAuthStorage` class. Use when asked to "persist OAuth tokens", "save OAuth credentials", "implement OAuthStorage", "store tokens securely", or "oauth_chopper storage".
---
# Implementing Persistent OAuth Token Storage

## Contents
- [Why Custom Storage](#why-custom-storage)
- [The OAuthStorage Interface](#the-oauthstorage-interface)
- [Choosing a Storage Backend](#choosing-a-storage-backend)
- [Workflow: Implement Custom OAuthStorage](#workflow-implement-custom-oauthstorage)
- [Examples](#examples)

## Why Custom Storage
Understand when and why the default in-memory storage must be replaced.

* `oauth_chopper` uses `MemoryStorage` by default. Tokens are lost when the app restarts or the process ends.
* For any production application, implement a custom `OAuthStorage` to persist credentials across app launches.
* The storage handles raw credential JSON strings. The `oauth2` package serializes and deserializes the full credential payload (access token, refresh token, expiration, scopes, etc.).
* Storage is called automatically: `saveCredentials` on successful grant or refresh, `clear` when an `AuthorizationException` occurs during refresh.

## The OAuthStorage Interface
The `OAuthStorage` abstract interface defines three methods that must be implemented.

* **`FutureOr<String?> fetchCredentials()`** -- Return the stored credentials JSON string, or `null` if no credentials are stored. Called before every request by the interceptor.
* **`FutureOr<void> saveCredentials(String? credentialsJson)`** -- Persist the credentials JSON string. Called after a successful `requestGrant` or `refresh`. The value may be `null`.
* **`FutureOr<void> clear()`** -- Delete all stored credentials. Called when the authorization server rejects a refresh attempt.
* All methods support both synchronous and asynchronous return types via `FutureOr`.

## Choosing a Storage Backend
Select the appropriate persistence mechanism based on the platform and security requirements.

* **Mobile apps (iOS/Android):** Use `flutter_secure_storage` for encrypted storage backed by the platform keychain/keystore. This is the recommended approach for apps handling sensitive OAuth tokens.
* **Mobile/desktop apps (less sensitive):** Use `shared_preferences` for simple key-value storage. Suitable when tokens are short-lived or the threat model is low.
* **Web apps:** Use `shared_preferences_web` (backed by `localStorage`) or a secure cookie-based approach. Be aware that `localStorage` is accessible to JavaScript and vulnerable to XSS.
* **Server-side Dart:** Use file-based storage, a database, or an in-memory cache with persistence (e.g., Redis). Implement the storage interface around your preferred backend.
* Never log or print credential JSON in production.

## Workflow: Implement Custom OAuthStorage

Follow this sequential workflow to create and integrate a persistent storage implementation.

**Task Progress:**
- [ ] 1. Add the storage backend dependency (e.g., `dart pub add flutter_secure_storage` or `dart pub add shared_preferences`).
- [ ] 2. Create a new class that implements `OAuthStorage`.
- [ ] 3. Implement `fetchCredentials()` to read the stored JSON string from the backend.
- [ ] 4. Implement `saveCredentials(String? credentialsJson)` to write the JSON string. Handle `null` values by deleting the entry.
- [ ] 5. Implement `clear()` to delete the stored credentials.
- [ ] 6. Pass the custom storage to `OAuthChopper(storage: MyCustomStorage(...))`.
- [ ] 7. **Feedback Loop**: Run `dart analyze` -> review for missing imports or async issues -> fix -> re-run until clean.

## Examples

### Secure Storage with flutter_secure_storage
Recommended for mobile apps. Credentials are encrypted using the platform keychain (iOS) or keystore (Android).

```dart
import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth_chopper/oauth_chopper.dart';

/// Persists OAuth credentials using encrypted platform storage.
class SecureOAuthStorage implements OAuthStorage {
  const SecureOAuthStorage(this._storage);

  static const _key = 'oauth_credentials';
  final FlutterSecureStorage _storage;

  @override
  FutureOr<String?> fetchCredentials() async {
    return _storage.read(key: _key);
  }

  @override
  FutureOr<void> saveCredentials(String? credentialsJson) async {
    if (credentialsJson == null) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(key: _key, value: credentialsJson);
    }
  }

  @override
  FutureOr<void> clear() async {
    await _storage.delete(key: _key);
  }
}
```

Usage:

```dart
import 'package:chopper/chopper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth_chopper/oauth_chopper.dart';

void main() {
  final storage = SecureOAuthStorage(const FlutterSecureStorage());

  final oauthChopper = OAuthChopper(
    authorizationEndpoint: Uri.parse('https://auth.example.com/oauth/token'),
    identifier: 'my_client_id',
    secret: 'my_client_secret',
    storage: storage, // Credentials persist across app restarts.
  );

  final chopperClient = ChopperClient(
    baseUrl: Uri.parse('https://api.example.com'),
    interceptors: [oauthChopper.interceptor()],
  );
}
```

### Simple Storage with shared_preferences
Suitable for less sensitive scenarios or when encrypted storage is not needed.

```dart
import 'dart:async';

import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists OAuth credentials using SharedPreferences.
class PrefsOAuthStorage implements OAuthStorage {
  const PrefsOAuthStorage(this._prefs);

  static const _key = 'oauth_credentials';
  final SharedPreferences _prefs;

  @override
  FutureOr<String?> fetchCredentials() {
    // SharedPreferences is synchronous for reads.
    return _prefs.getString(_key);
  }

  @override
  FutureOr<void> saveCredentials(String? credentialsJson) async {
    if (credentialsJson == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, credentialsJson);
    }
  }

  @override
  FutureOr<void> clear() async {
    await _prefs.remove(_key);
  }
}
```

Usage:

```dart
import 'package:chopper/chopper.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  final prefs = await SharedPreferences.getInstance();
  final storage = PrefsOAuthStorage(prefs);

  final oauthChopper = OAuthChopper(
    authorizationEndpoint: Uri.parse('https://auth.example.com/oauth/token'),
    identifier: 'my_client_id',
    storage: storage, // Credentials persist across app restarts.
  );

  final chopperClient = ChopperClient(
    baseUrl: Uri.parse('https://api.example.com'),
    interceptors: [oauthChopper.interceptor()],
  );
}
```
