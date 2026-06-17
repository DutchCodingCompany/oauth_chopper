import 'package:oauth2/oauth2.dart';
import 'package:oauth_chopper/oauth_chopper.dart';
import 'package:test/test.dart';

void main() {
  group('OAuthToken equality', () {
    final expiration = DateTime(2024);

    test('== returns true for tokens with identical fields', () {
      final a = OAuthToken.fromCredentials(
        Credentials(
          'access',
          refreshToken: 'refresh',
          expiration: expiration,
          idToken: 'id',
        ),
      );
      final b = OAuthToken.fromCredentials(
        Credentials(
          'access',
          refreshToken: 'refresh',
          expiration: expiration,
          idToken: 'id',
        ),
      );

      expect(a, equals(b));
    });

    test('== returns false for tokens with different accessToken', () {
      final a = OAuthToken.fromCredentials(
        Credentials('access1', expiration: expiration),
      );
      final b = OAuthToken.fromCredentials(
        Credentials('access2', expiration: expiration),
      );

      expect(a, isNot(equals(b)));
    });

    test('== returns false for tokens with different refreshToken', () {
      final a = OAuthToken.fromCredentials(
        Credentials('access', refreshToken: 'refresh1', expiration: expiration),
      );
      final b = OAuthToken.fromCredentials(
        Credentials('access', refreshToken: 'refresh2', expiration: expiration),
      );

      expect(a, isNot(equals(b)));
    });

    test('== returns false for tokens with different expiration', () {
      final a = OAuthToken.fromCredentials(
        Credentials('access', expiration: DateTime(2024)),
      );
      final b = OAuthToken.fromCredentials(
        Credentials('access', expiration: DateTime(2025)),
      );

      expect(a, isNot(equals(b)));
    });

    test('== returns false for tokens with different idToken', () {
      final a = OAuthToken.fromCredentials(
        Credentials('access', idToken: 'id1', expiration: expiration),
      );
      final b = OAuthToken.fromCredentials(
        Credentials('access', idToken: 'id2', expiration: expiration),
      );

      expect(a, isNot(equals(b)));
    });

    test('== returns false when compared to non-OAuthToken', () {
      final a = OAuthToken.fromCredentials(Credentials('access'));

      expect(a, isNot(equals('not a token')));
    });
  });

  group('OAuthToken hashCode', () {
    test('hashCode is consistent with ==', () {
      final expiration = DateTime(2024);
      final a = OAuthToken.fromCredentials(
        Credentials(
          'access',
          refreshToken: 'refresh',
          expiration: expiration,
          idToken: 'id',
        ),
      );
      final b = OAuthToken.fromCredentials(
        Credentials(
          'access',
          refreshToken: 'refresh',
          expiration: expiration,
          idToken: 'id',
        ),
      );

      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for different tokens', () {
      final a = OAuthToken.fromCredentials(Credentials('access1'));
      final b = OAuthToken.fromCredentials(Credentials('access2'));

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('OAuthToken toString', () {
    test('toString() contains all fields', () {
      final token = OAuthToken.fromCredentials(
        Credentials(
          'myAccess',
          refreshToken: 'myRefresh',
          idToken: 'myId',
          expiration: DateTime(2024),
        ),
      );
      final str = token.toString();

      expect(str, contains('myAccess'));
      expect(str, contains('myRefresh'));
      expect(str, contains('myId'));
      expect(str, contains('2024'));
    });

    test('toString() handles null fields', () {
      final token = OAuthToken.fromCredentials(Credentials('access'));
      final str = token.toString();

      expect(str, contains('access'));
      expect(str, contains('null'));
    });
  });

  group('OAuthToken isExpired', () {
    test('isExpired returns true for past expiration', () {
      final token = OAuthToken.fromCredentials(
        Credentials('access', expiration: DateTime(2020)),
      );

      expect(token.isExpired, isTrue);
    });

    test('isExpired returns false for future expiration', () {
      final token = OAuthToken.fromCredentials(
        Credentials(
          'access',
          expiration: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      expect(token.isExpired, isFalse);
    });

    test('isExpired returns false when expiration is null', () {
      final token = OAuthToken.fromCredentials(Credentials('access'));

      expect(token.isExpired, isFalse);
    });
  });

  group('OAuthToken fromJson', () {
    test('fromJson creates token from valid JSON', () {
      const json = '''
      {
        "accessToken": "access123",
        "refreshToken": "refresh123",
        "idToken": "id123",
        "tokenEndpoint": "https://example.com/token",
        "scopes": [],
        "expiration": 1700000000000
      }
      ''';

      final token = OAuthToken.fromJson(json);

      expect(token.accessToken, 'access123');
      expect(token.refreshToken, 'refresh123');
      expect(token.idToken, 'id123');
    });
  });
}
