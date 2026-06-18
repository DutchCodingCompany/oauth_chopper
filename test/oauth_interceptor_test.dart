// ignore so the test is easier to read.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oauth2/oauth2.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:oauth_chopper/src/oauth_interceptor.dart';
import 'package:test/test.dart';

class MockOAuthChopper extends Mock implements OAuthChopper {}

class MockChain extends Mock implements Chain<dynamic> {}

void main() {
  final testRequest = Request('GET', Uri(host: 'test'), Uri(host: 'test'));
  final authorizedResponse = Response(
    http.Response('body', HttpStatus.accepted),
    'body',
  );
  registerFallbackValue(testRequest);
  registerFallbackValue(authorizedResponse);

  group('request tests', () {
    final mockChain = MockChain();
    final mockOAuthChopper = MockOAuthChopper();
    final testToken = OAuthToken.fromCredentials(
      Credentials(
        'token',
        refreshToken: 'refresh',
        expiration: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    final testIDtoken = OAuthToken.fromCredentials(
      Credentials(
        'token',
        refreshToken: 'refresh',
        idToken: 'idToken',
        expiration: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    when(() => mockChain.request).thenReturn(testRequest);
    when(
      () => mockChain.proceed(any()),
    ).thenAnswer((_) async => authorizedResponse);

    test('HeaderInterceptor adds available token to headers', () async {
      // arrange
      when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
      final interceptor = OAuthInterceptor(mockOAuthChopper, null);
      final expected = {'Authorization': 'Bearer token'};

      // act
      await interceptor.intercept(mockChain);

      // assert
      verify(
        () => mockChain.proceed(testRequest.copyWith(headers: expected)),
      ).called(1);
    });

    test(
      'HeaderInterceptor does not add IDToken when available to headers',
      () async {
        // arrange
        when(() => mockOAuthChopper.token).thenAnswer((_) async => testIDtoken);
        final interceptor = OAuthInterceptor(mockOAuthChopper, null);
        final expected = {'Authorization': 'Bearer token'};

        // act
        await interceptor.intercept(mockChain);

        // assert
        verify(
          () => mockChain.proceed(testRequest.copyWith(headers: expected)),
        ).called(1);
      },
    );

    test('HeaderInterceptor adds no token to headers', () async {
      // arrange
      when(() => mockOAuthChopper.token).thenAnswer((_) async => null);
      final interceptor = OAuthInterceptor(mockOAuthChopper, null);
      final expected = <String, String>{};

      // act
      await interceptor.intercept(mockChain);

      // assert
      verify(
        () => mockChain.proceed(testRequest.copyWith(headers: expected)),
      ).called(1);
    });
  });

  group('proactive refresh tests', () {
    final mockChain = MockChain();
    final mockOAuthChopper = MockOAuthChopper();
    final expiredToken = OAuthToken.fromCredentials(
      Credentials(
        'expired_token',
        refreshToken: 'refresh',
        expiration: DateTime(2022, 9, 1),
      ),
    );

    final freshToken = OAuthToken.fromCredentials(
      Credentials(
        'fresh_token',
        refreshToken: 'refresh',
        expiration: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    setUp(() {
      when(() => mockChain.request).thenReturn(testRequest);
      when(
        () => mockChain.proceed(any()),
      ).thenAnswer((_) async => authorizedResponse);
    });

    test('Proactively refreshes expired token before request', () async {
      // arrange
      when(() => mockOAuthChopper.token).thenAnswer((_) async => expiredToken);
      when(mockOAuthChopper.refresh).thenAnswer((_) async => freshToken);
      final interceptor = OAuthInterceptor(mockOAuthChopper, null);
      final expected = {'Authorization': 'Bearer fresh_token'};

      // act
      await interceptor.intercept(mockChain);

      // assert
      verify(mockOAuthChopper.refresh).called(1);
      verify(
        () => mockChain.proceed(testRequest.copyWith(headers: expected)),
      ).called(1);
    });

    test('Uses original token if proactive refresh returns null', () async {
      // arrange
      when(() => mockOAuthChopper.token).thenAnswer((_) async => expiredToken);
      when(mockOAuthChopper.refresh).thenAnswer((_) async => null);
      final interceptor = OAuthInterceptor(mockOAuthChopper, null);
      final expected = {'Authorization': 'Bearer expired_token'};

      // act
      await interceptor.intercept(mockChain);

      // assert
      verify(mockOAuthChopper.refresh).called(1);
      verify(
        () => mockChain.proceed(testRequest.copyWith(headers: expected)),
      ).called(1);
    });

    test('Calls onError when proactive refresh throws', () async {
      // arrange
      FormatException? result;
      when(() => mockOAuthChopper.token).thenAnswer((_) async => expiredToken);
      when(
        mockOAuthChopper.refresh,
      ).thenThrow(const FormatException('refresh failed'));
      final interceptor = OAuthInterceptor(
        mockOAuthChopper,
        (e, s) => result = e as FormatException,
      );

      // act
      await interceptor.intercept(mockChain);

      // assert
      expect(result?.message, 'refresh failed');
    });

    test('Throws when proactive refresh fails and onError is null', () async {
      // arrange
      when(() => mockOAuthChopper.token).thenAnswer((_) async => expiredToken);
      when(
        mockOAuthChopper.refresh,
      ).thenThrow(const FormatException('refresh failed'));
      final interceptor = OAuthInterceptor(mockOAuthChopper, null);

      // act & assert
      expect(
        () async => interceptor.intercept(mockChain),
        throwsFormatException,
      );
    });
  });

  group('response tests', () {
    final mockChain = MockChain();
    final mockOAuthChopper = MockOAuthChopper();
    final testToken = OAuthToken.fromCredentials(
      Credentials(
        'token',
        refreshToken: 'refresh',
        expiration: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    final unauthorizedResponse = Response(
      http.Response('body', HttpStatus.unauthorized),
      'body',
    );
    setUp(() {
      when(() => mockChain.request).thenReturn(testRequest);
      when(
        () => mockChain.proceed(any()),
      ).thenAnswer((_) async => unauthorizedResponse);
    });

    test('only refresh on unauthorized and token', () async {
      // arrange
      when(mockOAuthChopper.refresh).thenAnswer((_) async => testToken);
      when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
      final interceptor = OAuthInterceptor(mockOAuthChopper, null);
      final expected = {'Authorization': 'Bearer token'};

      // act
      await interceptor.intercept(mockChain);

      // assert
      verify(mockOAuthChopper.refresh).called(1);
      verify(
        () => mockChain.proceed(testRequest.copyWith(headers: expected)),
      ).called(2);
    });

    test("Don't refresh on authorized", () async {
      // arrange
      when(
        () => mockChain.proceed(any()),
      ).thenAnswer((_) async => authorizedResponse);
      when(mockOAuthChopper.refresh).thenAnswer((_) async => testToken);
      when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
      final interceptor = OAuthInterceptor(mockOAuthChopper, null);

      // act
      await interceptor.intercept(mockChain);

      // assert
      verifyNever(mockOAuthChopper.refresh);
      verify(() => mockChain.proceed(any())).called(1);
    });

    test("Don't refresh on token not available", () async {
      // arrange
      when(mockOAuthChopper.refresh).thenAnswer((_) async => testToken);
      when(() => mockOAuthChopper.token).thenAnswer((_) async => null);
      final interceptor = OAuthInterceptor(mockOAuthChopper, null);

      // act
      await interceptor.intercept(mockChain);

      // assert
      verifyNever(mockOAuthChopper.refresh);
      verify(() => mockChain.proceed(any())).called(1);
    });

    test("Don't add headers on failed refresh", () async {
      // arrange
      when(mockOAuthChopper.refresh).thenAnswer((_) async => null);
      when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
      final interceptor = OAuthInterceptor(mockOAuthChopper, null);

      // act
      await interceptor.intercept(mockChain);

      // assert
      verify(mockOAuthChopper.refresh).called(1);
    });

    test('Exception thrown if onError is null', () async {
      // arrange
      when(mockOAuthChopper.refresh).thenThrow(const FormatException('failed'));
      when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
      final interceptor = OAuthInterceptor(mockOAuthChopper, null);

      // act
      // assert
      expect(
        () async => interceptor.intercept(mockChain),
        throwsFormatException,
      );
    });

    test('Exception not thrown if onError is supplied', () async {
      // arrange
      FormatException? result;
      when(mockOAuthChopper.refresh).thenThrow(const FormatException('failed'));
      when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
      final interceptor = OAuthInterceptor(
        mockOAuthChopper,
        (e, s) => result = e as FormatException,
      );

      // act
      await interceptor.intercept(mockChain);

      // assert
      expect(result?.message, 'failed');
    });
  });
}
