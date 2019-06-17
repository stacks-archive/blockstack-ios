# Blockstack iOS SDK

[![License](https://img.shields.io/cocoapods/l/Blockstack.svg?style=flat)](http://cocoapods.org/pods/Blockstack)
[![Version](https://img.shields.io/cocoapods/v/Blockstack.svg?style=flat)](http://cocoapods.org/pods/Blockstack)
[![Platform](https://img.shields.io/cocoapods/p/Blockstack.svg?style=flat)](http://cocoapods.org/pods/Blockstack)

Blockstack is a platform for developing a new, decentralized internet, where
users control and manage their own information. Interested developers can create
applications for this new internet using the Blockstack platform.

This repository contains:
- The Blockstack iOS SDK ([`/blockstack-sdk`](Blockstack/))
- A sample iOS app + web component ([`/Tools`](Tools/Blockstack-webapp/))
- A tutorial that teaches you [how to use the SDK](docs/tutorial.md)


if you encounter an issue please feel free to log it [on this
repository](https://github.com/blockstack/blockstack-ios/issues).

## Requirements

iOS 11.0+

## Getting started

Clone this repo and play around with the included sample app, available at ([`/Example`](Example/)). To add Blockstack functionality to your own project, read below.

## Adding the SDK to a project

Blockstack is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile and run `pod install`:

```ruby
pod 'Blockstack'
```

Add `import Blockstack` to the top of any file you wish to
invoke the SDK's functionality.

## How to use

Utilize Blockstack functionality in your app via the shared instance:
`Blockstack.shared.*some_method()*`.

Some of the essentials are described below, but have a look at the documentation for the `Blockstack` class to get a better understanding of what's possible. Happy coding!

### Authentication

Authenticate users using their Blockstack ID by calling  `Blockstack.shared.signIn`. 
A web view will pop up to request their credentials and grant access to your app.

### Storage

Store content to the user's Gaia hub as a file, via the `putFile` method:

```
Blockstack.shared.putFile(to: "testFile", text: "Testing 123") {
    publicURL, error in
    // publicURL points to the file in Gaia storage
}
```

Retreive files from the user's Gaia hub with the `getFile` method.

```
Blockstack.shared.getFile(at: "testFile") {
    response, error in
    print(response as! String) // "Testing 123"
}
```

## Contributing
Please see the [contribution guidelines](CONTRIBUTING.md).

## License

Please see the [license](LICENSE.md) file..
