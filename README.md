

<!--     
This README describes the package. If you publish this package to pub.dev,    
this README's contents appear on the landing page for your package.    
    
For information about how to write a good package README, see the guide for    
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).     
    
For general information about developing packages, see the Dart guide for    
[creating packages](https://dart.dev/guides/libraries/create-library-packages)    
and the Flutter guide for    
[developing packages and plugins](https://flutter.dev/developing-packages).     
-->    

Add and manage OAuth2 authentication for your Chopper client

## Features

Offers a `oauth_chopper` client to help manage your OAuth2 authentication with [Choppper](https://pub.dev/packages/chopper). The `oauth_chopper` client uses [oauth2](https://pub.dev/packages/oauth2) package from the dart team and combines this with Chopper. It offers a Chopper Authenticator and HeaderInterceptor to manage the OAuth2 authorizations.

By default it doesn't persist any credential information. It uses an in memory storage by default. This can be override by providing a custom storage implementation.

**Currently it supports the following grants:**
- ✅ ResourceOwnerPasswordGrant
- ✅ ClientCredentialsGrant
- ❌ AuthorizationCodeGrant (*TODO*)

## Usage

Create a `oauth_chopper` client with the needed authorizationEndpoint, identifier and secret.  
Add the `oauth_chopper_authenticator` + `oauth_chopper_interceptor` to your chopper client.  
Request a OAuthGrant on the `oauth_chopper` client.

Example:

```dart    
 /// Create OAuthChopper instance.  
 final oauthChopper = OAuthChopper(    authorizationEndpoint: authorizationEndpoint,   
    identifier: identifier,   
    secret: secret,  
 ); /// Add the oauth authenticator and interceptor to the chopper client. final chopperClient = ChopperClient(    
    baseUrl: 'https://example.com',   
    authenticator: oauthChopper.authenticator(),  
 interceptors: [ oauthChopper.interceptor, ], ); /// Request grant oauthChopper.requestGrant(    
   ResourceOwnerPasswordGrant(    
      username: 'username',    
      password: 'password',    
), ); 
```   

If you want to persist the OAuth2 credential information you can provide a custom OAuthStorage implementation for example with [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage):

```dart  
const _storageKey = 'storage_key';  
  
class OAuthCredentialsStorage implements OAuthStorage {    
  final FlutterSecureStorage _storage;    
    
 const OAuthCredentialsStorage(this._storage);    
    
  @override    
  FutureOr<void> clear() async {    
    await _storage.delete(key: _storageKey);    
  }    
    
  @override    
  FutureOr<String?> fetchCredentials() async {    
    final credentialsJson = await _storage.read(key: _storageKey);    
 return credentialsJson;    
  }    
    
  @override    
  FutureOr<void> saveCredentials(String? credentialsJson) async {    
    await _storage.write(key: _storageKey, value: credentialsJson);    
} }  
```  

## Additional information

- [OAuth2](https://oauth.net/2/)
- [OAuth2 package](https://pub.dev/packages/oauth2)
- [Chopper package](https://pub.dev/packages/chopper)

Feel free to give me any feedback to improve this package.