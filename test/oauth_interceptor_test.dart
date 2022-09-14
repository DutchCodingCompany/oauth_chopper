import 'package:chopper/chopper.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:oauth2/oauth2.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:oauth_chopper/src/oauth_interceptor.dart';
import 'package:oauth_chopper/src/oauth_token.dart';
import 'package:test/test.dart';

@GenerateMocks([OAuthChopper])
import 'oauth_interceptor_test.mocks.dart';

void main() {
  final mockOAuthChopper = MockOAuthChopper();
  final testToken = OAuthToken.fromCredentials(
    Credentials(
      'token',
      refreshToken: 'refresh',
      expiration: DateTime(2022, 9, 1),
    ),
  );

  final testRequest = Request('GET', 'test', 'test');

  test('HeaderInterceptor adds available token to headers', () async {
    // arrange
    when(mockOAuthChopper.token).thenAnswer((_) async => testToken);
    final interceptor = OAuthInterceptor(mockOAuthChopper);
    final expected = {'Authorization': 'Bearer token'};

    // act
    final result = await interceptor.onRequest(testRequest);

    // assert
    expect(result.headers, expected);
  });
  test('HeaderInterceptor adds no token to headers', () async {
    // arrange
    when(mockOAuthChopper.token).thenAnswer((_) async => null);
    final interceptor = OAuthInterceptor(mockOAuthChopper);
    final expected = {};

    // act
    final result = await interceptor.onRequest(testRequest);

    // assert
    expect(result.headers, expected);
  });
}
