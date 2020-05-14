# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.4] - 2020-05-12
- Replaced Blockstack browser with the new Blockstack authenticator 
- Disabled beta browser mode
- Disabled reset device keychain

## [1.0.3] - 2019-11-26
- Fix LICENSE error on build

## [1.0.1] - 2019-10-22

### Changed
- Make `AuthScope.fromString` method public (for use in  React Native)

## [1.0.0] - 2019-10-11

### Added
- `Blockstack.getNameInfo`
- `Blockstack.getNamespaceInfo`
- `Blockstack.getNamePrice`
- `Blockstack.getNamespacePrice`
- `Blockstack.getNamesOwned`
- `Blockstack.getGracePeriod`
- `Blockstack.getNamespaceBurnAddress`

### Changed
- `FileNotFoundError` -> `ItemNotFoundError`
- Fixes iOS 13 auth issue (ASWebAuthenticationSession, no provided presentation context)

## [0.7.0] - 2019-06-18

### Added
- `Blockstack.deleteFile`
-  `FileNotFoundError` for storage operations.
- `ProfileHelper.fetchCurrentUserProfile` to fetch the user's profile data at their profileURL.

### Changed
- `Blockstack.signIn` calls back on the main queue.
- Enums instead of strings for permission scopes provided at auth.

## [0.6.0] - 2019-05-25

### Added
- `Blockstack.hasSession` property added. This may fix some issues with the React Native SDK.
- Signing on `putFile` and verification on `getFile` are now supported.

### Changed
- `putFile` and `getFile` now encrypt and decrypt, respectively, by default. THis matches the behavior of blockstack.js.
    NOTE: This may break existing applications built around the previous assumption of no encryption. Please update your apps accordingly.
- Swift 3 is now supported, in addition to Swift 4. This removes the need to update your Mac OS as well as XCode prior to getting started, but it's still recommend to be updated :). 

## [0.5.4] - 2019-04-07

### Added
- Improved documentation, visible at https://blockstack.github.io/blockstack-ios/

### Changed
- Elliptic Curve key methods (generation, shared secret derivation, etc.) are now exposed via the `Keys` object.
- `ASWebAuthenticationSession` is now utilized for iOS 12 and above, with `SFAuthenticationSession` being the fallback for lower versions. This allows sign in state and cookies to be shared across apps and the Safari browser (sign in once, be authenticated everywhere).

## [0.5.2] - 2019-02-25

### Added
- `Blockstack.isBetaBrowserEnabled` option to utilize the latest beta of the Blockstack browser.

## [0.5.1] - 2019-02-15

### Changed
- Made encryption far more performant (100x) for large files.

## [0.5.0] - 2019-02-14

### Added
- `Gaia.setLocalGaiaHubConnection`
- `Blockstack.isUserSignedIn`
- `Blockstack.clearGaiaSession`
- `Blockstack.validateProofs`
- `Blockstack.getAppBucketURL`
- `Blockstack.listFiles`

### Changed
- Various fixes for compatibility with Objective-C projects.
- Appropriate errors thrown if `putFile` fails.
- Storage I/O methods are more resilient,  and retry upon failure.
- Improved documentation.
- The included sample app has been reorganized and now demonstrates more functionality.

## [0.4.1] - 2018-01-11

### Added
- `Blockstack.clearGaiaSession`

### Changed
- `Blockstack.putFile` has been modified to retry in the case of a configuration error. This may be the case if there have been any token revocations. This new logic will catch the first failed write, construct (and cache) a new Gaia token, and then attempt the write again. This allows tokens to be revoked without any hiccups from a user experience standpoint.
 
## [0.4.0] - 2018-10-29

### Added
- A lot more methods from Blockstack.js are now supported in Swift. Specifically...
- `Blockstack.encryptContent`
- `Blockstack.decryptContent`
- `Blockstack.extractProfile`
- `Blockstack.wrapProfileToken`
- `Blockstack.signProfileToken`
- `Blockstack.verifyProfileToken`
- `Blockstack.lookupProfile`
- `Blockstack.getUserAppFileURL`
- Objective-C bindings for all methods exposed by the SDK.

### Changed
- Vastly improved and much more detailed tutorial.
- Exposed key generation utilities, specifically: `Keys.getEntropy`, `Keys.getPublicKeyFromPrivate`, `Keys.makeECPrivateKey`
- The `Profile` object now supports an `image` field, which contains an object of type `Content`.
- `Blockstack.promptClearDeviceKeychain` has been simplified, no longer requiring a redirectURI or completion handler.
- `Blockstack.signOut` -> `Blockstack.signUserOut`
- `Blockstack.isSignedIn` -> `Blockstack.isUserSignedIn`
- Example app has been cleaned up, error states have been fixed, and shows off more functionality.

## [0.3.0] - 2018-08-27

### Added
- `Blockstack.getFile` with parameters username, app, and zoneFileLookupURL.
- `Blockstack.lookupProfile`
- `Gaia.getUserAppFileURL`
- `Blockstack.promptClearDeviceKeychain` to reset the user's local storage for auth.
- Descriptive comments that work with Xcode Quick Look

### Changed
- Non-JSON formats in getFile and putFile, specifically "text/plain" and "application/octet-stream" content types.
- `Profile` object now includes an "apps" property.
- Various fixes around sign in/sign out with the sample app.
- The sample app now showcases multiplayer get, along with encrypted putFile and getFile.
- `Blockstack.signOut` now just signs the user out and clears state for the current application.

## [0.2.0] - 2018-08-04

### Added
- This change log.
- Sign out functionality that allows clearing of SFAuthenticationSession browser storage. This allows users to use multiple accounts without having to reset the device/emulator. Also fixes an issue where users who get into a bad state during onboarding cannot recover.
- `EllipticJS` class which allows computing ECDH shared secret and getting a public key from private, on the secp256k1 curve.
- `Encryption.encryptECIES` and `Encryption.decryptECIES` methods which allow encryption/decryption of text or byte streams.
- Unit tests for Encryption via Quick/Nimble
- CircleCI integration for automated testing on all branches.
- `GaiaHubSession` has been added to allow multiple gaia connections. The shared `Gaia` object can hold numerous connections. It is not possible to create a `GaiaHubSession` object without a valid gaia config, fixing some error states. This object handles getting from and putting to a Gaia hub. 

### Changed
- Swift 4.0 syntax
- Removed secp256k1 pod. The functionality it was useful for is now covered by EllipticJS.
- Class extensions are all now in the "Extensions.swift" file, reducing project size.
- Crash-proofing and refactoring of code around the project for simplicity and separation.
- The included example app is functional (works for sign in and sign out)
- `Blockstack` and `BlockstackInstance` are merged.
- `Gaia` is now responsible for connecting to and managing `GaiaHubSessions`, along with saving and retrieving gaia configs, via static methods.
- `Gaia.getOrSetGaiaSession` is now `Gaia.ensureHubSession`.

## [0.1.3] - 2018-04-24
- Initial release.
