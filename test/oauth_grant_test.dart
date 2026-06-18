import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:test/test.dart';

void main() {
  const successfulTokenResponse = '''
  {
    "access_token": "new_access_token",
    "token_type": "bearer",
    "refresh_token": "new_refresh_token",
    "expires_in": 3600
  }
  ''';

  const errorResponse = '''
  {
    "error": "invalid_grant",
    "error_description": "The refresh token is expired."
  }
  ''';

  group('ResourceOwnerPasswordGrant', () {
    test('returns credentials JSON on successful grant', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.url.toString(), 'https://auth.example.com/oauth/token');
        expect(request.method, 'POST');
        expect(request.body, contains('grant_type=password'));
        expect(request.body, contains('username=testuser'));
        expect(request.body, contains('password=testpass'));
        return http.Response(
          successfulTokenResponse,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      const grant = ResourceOwnerPasswordGrant(
        username: 'testuser',
        password: 'testpass',
      );

      final credentialsJson = await grant.handle(
        Uri.parse('https://auth.example.com/oauth/token'),
        'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
      );

      final decoded = jsonDecode(credentialsJson) as Map<String, dynamic>;
      expect(decoded['accessToken'], 'new_access_token');
      expect(decoded['refreshToken'], 'new_refresh_token');
    });

    test('throws AuthorizationException on server error', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          errorResponse,
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      const grant = ResourceOwnerPasswordGrant(
        username: 'testuser',
        password: 'testpass',
      );

      expect(
        () => grant.handle(
          Uri.parse('https://auth.example.com/oauth/token'),
          'client_id',
          secret: 'client_secret',
          httpClient: mockHttpClient,
        ),
        throwsA(isA<AuthorizationException>()),
      );
    });

    test('passes scopes to the request', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.body, contains('scope=read+write'));
        return http.Response(
          successfulTokenResponse,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      const grant = ResourceOwnerPasswordGrant(
        username: 'testuser',
        password: 'testpass',
      );

      await grant.handle(
        Uri.parse('https://auth.example.com/oauth/token'),
        'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
        scopes: ['read', 'write'],
      );
    });
  });

  group('ClientCredentialsGrant', () {
    test('returns credentials JSON on successful grant', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.url.toString(), 'https://auth.example.com/oauth/token');
        expect(request.method, 'POST');
        expect(request.body, contains('grant_type=client_credentials'));
        return http.Response(
          successfulTokenResponse,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      const grant = ClientCredentialsGrant();

      final credentialsJson = await grant.handle(
        Uri.parse('https://auth.example.com/oauth/token'),
        'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
      );

      final decoded = jsonDecode(credentialsJson) as Map<String, dynamic>;
      expect(decoded['accessToken'], 'new_access_token');
    });

    test('throws AuthorizationException on server error', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          errorResponse,
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      const grant = ClientCredentialsGrant();

      expect(
        () => grant.handle(
          Uri.parse('https://auth.example.com/oauth/token'),
          'client_id',
          secret: 'client_secret',
          httpClient: mockHttpClient,
        ),
        throwsA(isA<AuthorizationException>()),
      );
    });

    test('works without basicAuth', () async {
      final mockHttpClient = MockClient((request) async {
        // When basicAuth is false, credentials are in the body
        expect(request.body, contains('client_id'));
        expect(request.body, contains('client_secret'));
        return http.Response(
          successfulTokenResponse,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      const grant = ClientCredentialsGrant();

      final credentialsJson = await grant.handle(
        Uri.parse('https://auth.example.com/oauth/token'),
        'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
        basicAuth: false,
      );

      final decoded = jsonDecode(credentialsJson) as Map<String, dynamic>;
      expect(decoded['accessToken'], 'new_access_token');
    });
  });

  group('AuthorizationCodeGrant', () {
    test('returns credentials JSON on successful grant', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.url.toString(), 'https://auth.example.com/oauth/token');
        expect(request.method, 'POST');
        expect(request.body, contains('grant_type=authorization_code'));
        expect(request.body, contains('code=auth_code_123'));
        return http.Response(
          successfulTokenResponse,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      Uri? capturedAuthUrl;
      final grant = AuthorizationCodeGrant(
        tokenEndpoint: Uri.parse('https://auth.example.com/oauth/token'),
        redirectUrl: Uri.parse('http://localhost:8080/callback'),
        redirect: (authorizationUri) async {
          capturedAuthUrl = authorizationUri;
        },
        listen: (redirectUri) async {
          return Uri.parse('http://localhost:8080/callback?code=auth_code_123');
        },
      );

      final credentialsJson = await grant.handle(
        Uri.parse('https://auth.example.com/oauth/authorize'),
        'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
      );

      final decoded = jsonDecode(credentialsJson) as Map<String, dynamic>;
      expect(decoded['accessToken'], 'new_access_token');
      expect(decoded['refreshToken'], 'new_refresh_token');
      expect(capturedAuthUrl, isNotNull);
      expect(capturedAuthUrl.toString(), contains('response_type=code'));
      expect(capturedAuthUrl.toString(), contains('client_id'));
    });

    test('calls redirect with correct authorization URL', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          successfulTokenResponse,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      Uri? capturedAuthUrl;
      final grant = AuthorizationCodeGrant(
        tokenEndpoint: Uri.parse('https://auth.example.com/oauth/token'),
        redirectUrl: Uri.parse('http://localhost:8080/callback'),
        redirect: (authorizationUri) async {
          capturedAuthUrl = authorizationUri;
        },
        listen: (redirectUri) async {
          return Uri.parse('http://localhost:8080/callback?code=code123');
        },
      );

      await grant.handle(
        Uri.parse('https://auth.example.com/oauth/authorize'),
        'my_client_id',
        httpClient: mockHttpClient,
        scopes: ['openid', 'profile'],
      );

      expect(capturedAuthUrl, isNotNull);
      expect(capturedAuthUrl!.host, 'auth.example.com');
      expect(capturedAuthUrl!.path, '/oauth/authorize');
      expect(capturedAuthUrl!.queryParameters['client_id'], 'my_client_id');
      expect(capturedAuthUrl!.queryParameters['scope'], 'openid profile');
    });

    test('passes PKCE code verifier', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.body, contains('code_verifier=my_custom_verifier'));
        return http.Response(
          successfulTokenResponse,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final grant = AuthorizationCodeGrant(
        tokenEndpoint: Uri.parse('https://auth.example.com/oauth/token'),
        redirectUrl: Uri.parse('http://localhost:8080/callback'),
        redirect: (authorizationUri) async {},
        listen: (redirectUri) async {
          return Uri.parse('http://localhost:8080/callback?code=code123');
        },
        codeVerifier: 'my_custom_verifier',
      );

      await grant.handle(
        Uri.parse('https://auth.example.com/oauth/authorize'),
        'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
      );
    });

    test('throws on server error during token exchange', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          errorResponse,
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final grant = AuthorizationCodeGrant(
        tokenEndpoint: Uri.parse('https://auth.example.com/oauth/token'),
        redirectUrl: Uri.parse('http://localhost:8080/callback'),
        redirect: (authorizationUri) async {},
        listen: (redirectUri) async {
          return Uri.parse('http://localhost:8080/callback?code=code123');
        },
      );

      expect(
        () => grant.handle(
          Uri.parse('https://auth.example.com/oauth/authorize'),
          'client_id',
          secret: 'client_secret',
          httpClient: mockHttpClient,
        ),
        throwsA(isA<AuthorizationException>()),
      );
    });
  });
}
