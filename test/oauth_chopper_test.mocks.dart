// Mocks generated by Mockito 5.3.0 from annotations
// in oauth_chopper/test/oauth_chopper_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:mockito/mockito.dart' as _i1;
import 'package:oauth_chopper/src/oauth_grant.dart' as _i3;
import 'package:oauth_chopper/src/storage/oauth_storage.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [OAuthStorage].
///
/// See the documentation for Mockito's code generation for more information.
class MockOAuthStorage extends _i1.Mock implements _i2.OAuthStorage {
  MockOAuthStorage() {
    _i1.throwOnMissingStub(this);
  }
}

/// A class which mocks [OAuthGrant].
///
/// See the documentation for Mockito's code generation for more information.
class MockOAuthGrant extends _i1.Mock implements _i3.OAuthGrant {
  MockOAuthGrant() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<String> handle(
          Uri? authorizationEndpoint, String? identifier, String? secret) =>
      (super.noSuchMethod(
          Invocation.method(
              #handle, [authorizationEndpoint, identifier, secret]),
          returnValue: _i4.Future<String>.value('')) as _i4.Future<String>);
}
