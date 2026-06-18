import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:test/test.dart';

class MockOAuthStorage extends Mock implements OAuthStorage {}

void main() {
  const storedCredentialsJson = '''
  {
    "accessToken": "old_access_token",
    "refreshToken": "old_refresh_token",
    "idToken": "old_id_token",
    "tokenEndpoint": "https://auth.example.com/oauth/token",
    "scopes": ["read"],
    "expiration": 1664359530234
  }
  ''';

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

  group('OAuthChopper.refresh()', () {
    late MockOAuthStorage storageMock;

    setUp(() {
      storageMock = MockOAuthStorage();
    });

    test('returns new token on successful refresh', () async {
      when(
        storageMock.fetchCredentials,
      ).thenAnswer((_) async => storedCredentialsJson);
      when(() => storageMock.saveCredentials(any())).thenAnswer((_) async {});

      final mockHttpClient = MockClient((request) async {
        expect(request.url.toString(), 'https://auth.example.com/oauth/token');
        expect(request.method, 'POST');
        return http.Response(
          successfulTokenResponse,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final oauthChopper = OAuthChopper(
        authorizationEndpoint: Uri.parse(
          'https://auth.example.com/oauth/authorize',
        ),
        identifier: 'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
        storage: storageMock,
      );

      final token = await oauthChopper.refresh();

      expect(token, isNotNull);
      expect(token!.accessToken, 'new_access_token');
      expect(token.refreshToken, 'new_refresh_token');
    });

    test('returns null when no credentials in storage', () async {
      when(storageMock.fetchCredentials).thenAnswer((_) async => null);

      final oauthChopper = OAuthChopper(
        authorizationEndpoint: Uri.parse(
          'https://auth.example.com/oauth/authorize',
        ),
        identifier: 'client_id',
        storage: storageMock,
      );

      final token = await oauthChopper.refresh();

      expect(token, isNull);
    });

    test('saves new credentials to storage', () async {
      when(
        storageMock.fetchCredentials,
      ).thenAnswer((_) async => storedCredentialsJson);
      when(() => storageMock.saveCredentials(any())).thenAnswer((_) async {});

      final mockHttpClient = MockClient((request) async {
        return http.Response(
          successfulTokenResponse,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final oauthChopper = OAuthChopper(
        authorizationEndpoint: Uri.parse(
          'https://auth.example.com/oauth/authorize',
        ),
        identifier: 'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
        storage: storageMock,
      );

      await oauthChopper.refresh();

      verify(() => storageMock.saveCredentials(any())).called(1);
    });

    test('clears storage on AuthorizationException', () async {
      when(
        storageMock.fetchCredentials,
      ).thenAnswer((_) async => storedCredentialsJson);
      when(storageMock.clear).thenAnswer((_) async {});

      final mockHttpClient = MockClient((request) async {
        return http.Response(
          errorResponse,
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final oauthChopper = OAuthChopper(
        authorizationEndpoint: Uri.parse(
          'https://auth.example.com/oauth/authorize',
        ),
        identifier: 'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
        storage: storageMock,
      );

      Object? caughtError;
      try {
        await oauthChopper.refresh();
      } on AuthorizationException catch (e) {
        caughtError = e;
      }

      expect(caughtError, isA<AuthorizationException>());
      verify(storageMock.clear).called(1);
    });

    test('deduplicates concurrent refresh calls', () async {
      var requestCount = 0;
      when(
        storageMock.fetchCredentials,
      ).thenAnswer((_) async => storedCredentialsJson);
      when(() => storageMock.saveCredentials(any())).thenAnswer((_) async {});

      final mockHttpClient = MockClient((request) async {
        requestCount++;
        // Simulate network delay
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(
          successfulTokenResponse,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final oauthChopper = OAuthChopper(
        authorizationEndpoint: Uri.parse(
          'https://auth.example.com/oauth/authorize',
        ),
        identifier: 'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
        storage: storageMock,
      );

      // Launch multiple concurrent refreshes
      final results = await Future.wait([
        oauthChopper.refresh(),
        oauthChopper.refresh(),
        oauthChopper.refresh(),
      ]);

      // Only one HTTP request should have been made
      expect(requestCount, 1);

      // All results should be the same token
      for (final token in results) {
        expect(token, isNotNull);
        expect(token!.accessToken, 'new_access_token');
      }
    });

    test(
      'resets completer after completion allowing subsequent refreshes',
      () async {
        var requestCount = 0;
        when(
          storageMock.fetchCredentials,
        ).thenAnswer((_) async => storedCredentialsJson);
        when(() => storageMock.saveCredentials(any())).thenAnswer((_) async {});

        final mockHttpClient = MockClient((request) async {
          requestCount++;
          return http.Response(
            successfulTokenResponse,
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final oauthChopper = OAuthChopper(
          authorizationEndpoint: Uri.parse(
            'https://auth.example.com/oauth/authorize',
          ),
          identifier: 'client_id',
          secret: 'client_secret',
          httpClient: mockHttpClient,
          storage: storageMock,
        );

        // First refresh
        await oauthChopper.refresh();
        expect(requestCount, 1);

        // Second refresh (should make a new request)
        await oauthChopper.refresh();
        expect(requestCount, 2);
      },
    );

    test('propagates errors to all concurrent waiters', () async {
      when(
        storageMock.fetchCredentials,
      ).thenAnswer((_) async => storedCredentialsJson);
      when(storageMock.clear).thenAnswer((_) async {});

      final mockHttpClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(
          errorResponse,
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final oauthChopper = OAuthChopper(
        authorizationEndpoint: Uri.parse(
          'https://auth.example.com/oauth/authorize',
        ),
        identifier: 'client_id',
        secret: 'client_secret',
        httpClient: mockHttpClient,
        storage: storageMock,
      );

      // Launch concurrent refreshes that should all fail
      final futures = [
        oauthChopper.refresh(),
        oauthChopper.refresh(),
        oauthChopper.refresh(),
      ];

      for (final future in futures) {
        await expectLater(future, throwsA(isA<AuthorizationException>()));
      }
    });
  });
}
