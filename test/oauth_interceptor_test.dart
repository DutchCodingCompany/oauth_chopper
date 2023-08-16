import 'package:chopper/chopper.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oauth2/oauth2.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:oauth_chopper/src/oauth_interceptor.dart';
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

  final testIDtoken = OAuthToken.fromCredentials(
    Credentials(
      'token',
      refreshToken: 'refresh',
      idToken: 'idToken',
      expiration: DateTime(2022, 9, 1),
    ),
  );

  final testRequest = Request('GET', Uri(host: 'test'), Uri(host: 'test'));

  test('HeaderInterceptor adds available token to headers', () async {
    // arrange
    when(()=>mockOAuthChopper.token).thenAnswer((_) async => testToken);
    final interceptor = OAuthInterceptor(mockOAuthChopper);
    final expected = {'Authorization': 'Bearer token'};

    // act
    final result = await interceptor.onRequest(testRequest);

    // assert
    expect(result.headers, expected);
  });

  test('HeaderInterceptor does not add IDToken when available to headers', () async {
    // arrange
    when(()=>mockOAuthChopper.token).thenAnswer((_) async => testIDtoken);
    final interceptor = OAuthInterceptor(mockOAuthChopper);
    final expected = {'Authorization': 'Bearer token'};

    // act
    final result = await interceptor.onRequest(testRequest);

    // assert
    expect(result.headers, expected);
  });

  test('HeaderInterceptor adds no token to headers', () async {
    // arrange
    when(()=>mockOAuthChopper.token).thenAnswer((_) async => null);
    final interceptor = OAuthInterceptor(mockOAuthChopper);
    final expected = {};

    // act
    final result = await interceptor.onRequest(testRequest);

    // assert
    expect(result.headers, expected);
  });
}
