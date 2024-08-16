## 1.0.1
- Updated dependencies:
  - `sdk` to `>=3.4.0 <4.0.0`
  - `chopper` to `8.0.1+1`
  - `http` to `1.2.2`
  - `mocktail` to `1.0.4`
  - `test` to `1.25.7`
  - `very_good_analysis` to `6.0.0`

## 1.0.0
 - Updated chopper to v8.0.0
 - **BREAKING** Removed oauth_chopper authenticator. Now only the interceptor is needed.

## 0.4.0
 - ✨ Add very good analysis by @Guldem in https://github.com/DutchCodingCompany/oauth_chopper/pull/17
 - ✨ Add custom client by @Guldem in https://github.com/DutchCodingCompany/oauth_chopper/pull/18
 - ⬆️ Upgraded some dependencies by @Guldem in https://github.com/DutchCodingCompany/oauth_chopper/pull/12

## 0.3.0
- Fixed issues where credentials where cleared when refreshing token failed on other errors than authorization errors. 

## 0.2.0

- Updated dependencies to latest versions. Including `chopper: 7.0.4` and `http: 1.1.0`.
- Added basic github action checks.
- Removed mockito in favor of mocktail.

## 0.1.2

- Add ID token to OAuth token

## 0.1.1

- Export OauthToken class

## 0.1.0

- Add support for AuthorizationCodeGrant

## 0.0.5

- Update Chopper

## 0.0.4

- Removed import for HttpStatus because platform support

## 0.0.3

- Changed import for HttpStatus
- Added export for oauth2 package exceptions

## 0.0.2

- Fixed dart formatting


## 0.0.1

- Initial version.
