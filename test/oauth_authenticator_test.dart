import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oauth2/oauth2.dart';
import 'package:oauth_chopper/src/oauth_authenticator.dart';
import 'package:oauth_chopper/src/oauth_chopper.dart';
import 'package:oauth_chopper/src/oauth_token.dart';
import 'package:test/test.dart';

class MockOAuthChopper extends Mock implements OAuthChopper {}

void main() {
  final mockOAuthChopper = MockOAuthChopper();
  final testToken = OAuthToken.fromCredentials(
    Credentials(
      'token',
      refreshToken: 'refresh',
      expiration: DateTime(2022, 9, 1),
    ),
  );
  final testRequest = Request('GET', Uri.parse('test'), Uri.parse('test'));
  final unauthorizedResponse =
      Response(http.Response('body', HttpStatus.unauthorized), 'body');
  final authorizedResponse =
      Response(http.Response('body', HttpStatus.accepted), 'body');

  test('only refresh on unauthorized and token', () async {
    // arrange
    when(() => mockOAuthChopper.refresh()).thenAnswer((_) async => testToken);
    when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
    final authenticator = OAuthAuthenticator(mockOAuthChopper, null);
    final expected = {'Authorization': 'Bearer token'};

    // act
    final result =
        await authenticator.authenticate(testRequest, unauthorizedResponse);

    // assert
    verify(() => mockOAuthChopper.refresh()).called(1);
    expect(result?.headers, expected);
  });

  test("Don't refresh on authorized", () async {
    // arrange
    when(() => mockOAuthChopper.refresh()).thenAnswer((_) async => testToken);
    when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
    final authenticator = OAuthAuthenticator(mockOAuthChopper, null);

    // act
    final result =
        await authenticator.authenticate(testRequest, authorizedResponse);

    // assert
    verifyNever(() => mockOAuthChopper.refresh());
    expect(result, null);
  });

  test("Don't refresh on token not available", () async {
    // arrange
    when(() => mockOAuthChopper.refresh()).thenAnswer((_) async => testToken);
    when(() => mockOAuthChopper.token).thenAnswer((_) async => null);
    final authenticator = OAuthAuthenticator(mockOAuthChopper, null);

    // act
    final result =
        await authenticator.authenticate(testRequest, unauthorizedResponse);

    // assert
    verifyNever(() => mockOAuthChopper.refresh());
    expect(result, null);
  });

  test("Don't add headers on failed refresh", () async {
    // arrange
    when(() => mockOAuthChopper.refresh()).thenAnswer((_) async => null);
    when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
    final authenticator = OAuthAuthenticator(mockOAuthChopper, null);

    // act
    final result =
        await authenticator.authenticate(testRequest, unauthorizedResponse);

    // assert
    verify(() => mockOAuthChopper.refresh()).called(1);
    expect(result, null);
  });

  test("Exception thrown if onError is null", () async {
    // arrange
    when(() => mockOAuthChopper.refresh()).thenThrow(FormatException('failed'));
    when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
    final authenticator = OAuthAuthenticator(mockOAuthChopper, null);

    // act
    // assert
    expect(
        () async =>
            await authenticator.authenticate(testRequest, unauthorizedResponse),
        throwsFormatException);
  });

  test("Exception not thrown if onError is supplied", () async {
    // arrange
    FormatException? result;
    when(() => mockOAuthChopper.refresh()).thenThrow(FormatException('failed'));
    when(() => mockOAuthChopper.token).thenAnswer((_) async => testToken);
    final authenticator = OAuthAuthenticator(
        mockOAuthChopper, (e, s) => result = e as FormatException);

    // act
    final responseResult =
        await authenticator.authenticate(testRequest, unauthorizedResponse);

    // assert
    expect(result?.message, 'failed');
    expect(responseResult, null);
  });
}
