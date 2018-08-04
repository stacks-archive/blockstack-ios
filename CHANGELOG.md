# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

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
