---
name: oauth-chopper-setup
description: Add and configure OAuth2 authentication for a Chopper HTTP client using `oauth_chopper`. Use when asked to "add OAuth to Chopper", "setup oauth_chopper", "integrate OAuth2 with Chopper", "add authentication to my API client", or when setting up any of the supported grant types (resource owner password, client credentials, authorization code).
---
# Setting Up OAuth2 Authentication with Chopper

## Contents
- [Package Overview](#package-overview)
- [Grant Type Selection](#grant-type-selection)
- [Interceptor Behavior](#interceptor-behavior)
- [Error Handling](#error-handling)
- [Workflow: Integrate oauth_chopper](#workflow-integrate-oauth_chopper)
- [Examples](#examples)

## Package Overview
`oauth_chopper` bridges the Chopper HTTP client with the `oauth2` package to provide turnkey OAuth2 authentication. It manages token acquisition, storage, proactive refresh of expired tokens, and automatic retry on 401 responses.

* Import the package with `import 'package:oauth_chopper/oauth_chopper.dart';`.
* The central class is `OAuthChopper`. Create an instance with the authorization server's endpoint, client identifier, and optional secret.
* Call `oauthChopper.interceptor()` to get an `OAuthInterceptor` and pass it to `ChopperClient(interceptors: [...])`.
* Call `oauthChopper.requestGrant(grant)` to authenticate and obtain an `OAuthToken`.
* Access the current token at any time with `await oauthChopper.token`.

## Grant Type Selection
Choose the correct OAuth2 grant type based on the application context.

* **Use `ResourceOwnerPasswordGrant`** for first-party apps where the user provides their username and password directly. Requires `username` and `password` parameters. Suitable for trusted mobile/desktop apps.
* **Use `ClientCredentialsGrant`** for server-to-server (machine-to-machine) communication where no user interaction is needed. Requires only the client `identifier` and `secret` on the `OAuthChopper` instance.
* **Use `AuthorizationCodeGrant`** for browser-based or redirect-based login flows. Requires a `tokenEndpoint`, `redirectUrl`, a `redirect` callback (to open the authorization URL), and a `listen` callback (to capture the redirect response). Supports PKCE via the optional `codeVerifier` parameter.

## Interceptor Behavior
Understand how the `OAuthInterceptor` manages the token lifecycle automatically.

* Before each request, the interceptor reads the current token from storage.
* If the token exists and is expired (`isExpired == true`), it proactively calls `refresh()` before sending the request.
* If no token is available, the request proceeds without an `Authorization` header.
* If the server responds with HTTP 401 and a token was present, the interceptor refreshes once and retries the request.
* Concurrent refresh calls are deduplicated internally. Multiple simultaneous 401 responses result in a single refresh request.

## Error Handling
Handle authentication errors to prevent crashes and guide the user back to login.

* `AuthorizationException` is thrown when the authorization server rejects credentials (e.g., invalid grant, revoked token). On refresh failure with this exception, storage is automatically cleared.
* `ExpirationException` is thrown on token expiration issues from the `oauth2` package.
* Pass an `onError` callback to `oauthChopper.interceptor(onError: ...)` to catch errors without throwing. Use this to redirect the user to a login screen on token failure.
* If no `onError` is provided, exceptions propagate to the caller.

## Workflow: Integrate oauth_chopper

Follow this sequential workflow to add OAuth2 authentication to an existing Chopper-based project.

**Task Progress:**
- [ ] 1. Add the dependency: run `dart pub add oauth_chopper`.
- [ ] 2. Create an `OAuthChopper` instance with the authorization server's `authorizationEndpoint`, `identifier`, and optional `secret`.
- [ ] 3. Add `oauthChopper.interceptor()` to the `ChopperClient`'s `interceptors` list. Optionally pass an `onError` callback for graceful error handling.
- [ ] 4. Choose the appropriate grant type and call `oauthChopper.requestGrant(grant)` to authenticate.
- [ ] 5. If using `AuthorizationCodeGrant`, implement the `redirect` and `listen` callbacks for the browser-based flow.
- [ ] 6. Wrap the `requestGrant` call in a try-catch to handle `AuthorizationException` and other errors.
- [ ] 7. **Feedback Loop**: Run `dart analyze` -> review for missing imports or type errors -> fix -> re-run until clean.

## Examples

### Resource Owner Password Grant
The simplest grant type for first-party apps with direct username/password input.

```dart
import 'package:chopper/chopper.dart';
import 'package:oauth_chopper/oauth_chopper.dart';

Future<void> main() async {
  // 1. Create the OAuthChopper instance.
  final oauthChopper = OAuthChopper(
    authorizationEndpoint: Uri.parse('https://auth.example.com/oauth/token'),
    identifier: 'my_client_id',
    secret: 'my_client_secret',
  );

  // 2. Wire the interceptor into the Chopper client.
  final chopperClient = ChopperClient(
    baseUrl: Uri.parse('https://api.example.com'),
    interceptors: [
      oauthChopper.interceptor(
        onError: (error, stackTrace) {
          // Handle token errors (e.g., redirect to login screen).
          print('Auth error: $error');
        },
      ),
    ],
  );

  // 3. Authenticate with username and password.
  try {
    final token = await oauthChopper.requestGrant(
      ResourceOwnerPasswordGrant(
        username: 'user@example.com',
        password: 'password123',
      ),
    );
    print('Authenticated. Access token: ${token.accessToken}');
  } on AuthorizationException catch (e) {
    print('Login failed: ${e.message}');
  }
}
```

### Client Credentials Grant
For server-to-server authentication where no user interaction is required.

```dart
import 'package:chopper/chopper.dart';
import 'package:oauth_chopper/oauth_chopper.dart';

Future<void> main() async {
  final oauthChopper = OAuthChopper(
    authorizationEndpoint: Uri.parse('https://auth.example.com/oauth/token'),
    identifier: 'service_client_id',
    secret: 'service_client_secret',
    scopes: ['read', 'write'],
  );

  final chopperClient = ChopperClient(
    baseUrl: Uri.parse('https://api.example.com'),
    interceptors: [oauthChopper.interceptor()],
  );

  try {
    final token = await oauthChopper.requestGrant(
      const ClientCredentialsGrant(),
    );
    print('Service authenticated. Expires: ${token.expiration}');
  } on AuthorizationException catch (e) {
    print('Authentication failed: ${e.message}');
  }
}
```

### Authorization Code Grant with PKCE
For browser-based login flows with redirect handling. Commonly used in mobile and web apps.

```dart
import 'package:chopper/chopper.dart';
import 'package:oauth_chopper/oauth_chopper.dart';

Future<void> main() async {
  final oauthChopper = OAuthChopper(
    authorizationEndpoint: Uri.parse('https://auth.example.com/authorize'),
    identifier: 'my_client_id',
    secret: 'my_client_secret',
    scopes: ['openid', 'profile', 'email'],
  );

  final chopperClient = ChopperClient(
    baseUrl: Uri.parse('https://api.example.com'),
    interceptors: [oauthChopper.interceptor()],
  );

  try {
    final token = await oauthChopper.requestGrant(
      AuthorizationCodeGrant(
        tokenEndpoint: Uri.parse('https://auth.example.com/oauth/token'),
        redirectUrl: Uri.parse('myapp://callback'),
        redirect: (authorizationUrl) async {
          // Open the authorization URL in a browser or webview.
          // For example, using url_launcher:
          // await launchUrl(authorizationUrl);
          print('Open in browser: $authorizationUrl');
        },
        listen: (redirectUrl) async {
          // Listen for the redirect and return the full response URI.
          // Implementation depends on your platform (e.g., uni_links,
          // app_links, or a local HTTP server for desktop).
          return Uri.parse('myapp://callback?code=auth_code&state=xyz');
        },
        // Optional: provide a PKCE code verifier for enhanced security.
        // If omitted, one is generated automatically by the oauth2 package.
        // codeVerifier: 'your_pkce_code_verifier',
      ),
    );
    print('Logged in. ID token: ${token.idToken}');
  } on AuthorizationException catch (e) {
    print('Login failed: ${e.message}');
  }
}
```
