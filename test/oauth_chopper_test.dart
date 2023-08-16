import 'package:mocktail/mocktail.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:test/test.dart';

class MockOAuthStorage extends Mock implements OAuthStorage {}

class MockOAuthGrant extends Mock implements OAuthGrant {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('test'));
  });

  final storageMock = MockOAuthStorage();
  final grantMock = MockOAuthGrant();
  final testJson = '''
   {
 	"accessToken": "accesToken",
 	"refreshToken": "refreshToken",
 	"idToken": null,
 	"tokenEndpoint": "https://test.test/oauth/token",
 	"scopes": [],
 	"expiration": 1664359530234
 }
 ''';

  test('oauth_chopper returns interceptor which contains oauth_chopper', () {
    // arrange
    final oauthChopper =
        OAuthChopper(authorizationEndpoint: Uri.parse('endpoint'), identifier: 'identifier', secret: 'secret');

    // act
    final inteceptor = oauthChopper.interceptor;

    // assert
    expect(oauthChopper, inteceptor.oauthChopper);
  });

  test('oauth_chopper returns authenticator which contains oauth_chopper', () {
    // arrange
    final oauthChopper =
        OAuthChopper(authorizationEndpoint: Uri.parse('endpoint'), identifier: 'identifier', secret: 'secret');

    // act
    final authenticator = oauthChopper.authenticator();

    // assert
    expect(oauthChopper, authenticator.oauthChopper);
  });

  test('Returns token from storage', () async {
    // arrange
    when(() => storageMock.fetchCredentials()).thenAnswer((_) => testJson);
    final oauthChopper = OAuthChopper(
        authorizationEndpoint: Uri.parse('endpoint'), identifier: 'identifier', secret: 'secret', storage: storageMock);

    // act
    final token = await oauthChopper.token;

    // assert
    expect(token?.accessToken, 'accesToken');
    expect(token?.refreshToken, 'refreshToken');
  });

  test('Returns no token if not in storage', () async {
    // arrange
    when(() => storageMock.fetchCredentials()).thenAnswer((_) => null);
    final oauthChopper = OAuthChopper(
        authorizationEndpoint: Uri.parse('endpoint'), identifier: 'identifier', secret: 'secret', storage: storageMock);

    // act
    final token = await oauthChopper.token;

    // assert
    expect(token, null);
  });

  test("Successful grant is stored", () async {
    // arrange
    when(() => storageMock.saveCredentials(any())).thenAnswer((_) => null);
    when(() => grantMock.handle(any(), any(), any())).thenAnswer((_) async => testJson);
    final oauthChopper = OAuthChopper(
        authorizationEndpoint: Uri.parse('endpoint'), identifier: 'identifier', secret: 'secret', storage: storageMock);

    // act
    final token = await oauthChopper.requestGrant(grantMock);

    // assert
    verify(() => grantMock.handle(any(), 'identifier', 'secret')).called(1);
    verify(() => storageMock.saveCredentials(testJson)).called(1);
    expect(token.accessToken, 'accesToken');
    expect(token.refreshToken, 'refreshToken');
  });
}
