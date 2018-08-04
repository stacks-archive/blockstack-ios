# Blockstack iOS SDK

[![Version](https://img.shields.io/cocoapods/v/Blockstack.svg?style=flat)](http://cocoapods.org/pods/Blockstack)
[![License](https://img.shields.io/cocoapods/l/Blockstack.svg?style=flat)](http://cocoapods.org/pods/Blockstack)
[![Platform](https://img.shields.io/cocoapods/p/Blockstack.svg?style=flat)](http://cocoapods.org/pods/Blockstack)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
iOS 11.0+

## Installation

Blockstack is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Blockstack'
```
## Setup

#### Step 1 - Choose a custom protocol handler

You'll need to choose a custom protocol handler that is unique to your app.

This is so that your app's web-based authentication redirect endpoint can redirect the user
back to your iOS app.

In this example, we use `myblockstackapp://`.

Register your URL scheme in Xcode from the info tab of your project settings.

#### Step 2 - Create redirect endpoint on web app

Blockstack apps are identified by their domain names. You'll need to
create an endpoint on the web version of your app that redirects users back
to your mobile app.

The endpoint will receive a get request with the query parameter `authResponse=XXXX`
and should redirect the browser to `myblockstackapp://XXXX`.

See the [example in the example web app in this repository](Tools/Blockstack-webapp/public/redirect.html).

You can run the example webapp to test out redirects by running `npm install && npm start` from the webapp directory.

*Note: in production make sure you're using https with cors enabled.*

## Usage

Import the Blockstack framework.

```swift
import Blockstack
```

#### Sign in using Blockstack authentication

In this example, your web app would be located at `http://localhost:8080`

```swift
Blockstack.shared.signIn(redirectURI: "[yourWebAppAddress]/redirect.html",
                                   appDomain: URL(string: "[yourWebAppAddress]")!) { authResult in
    switch authResult {
        case .success(let userData):
            print("sign in success")
            self.handleSignInSuccess(userData: userData)
        case .cancelled:
            print("sign in cancelled")
        case .failed(let error):
            print("sign in failed")
            print(error!)
    }
    
}
```

#### Check if user is currently signed in


```swift
if Blockstack.shared.isSignedIn() {
    print("currently signed in")
} else {
    print("not signed in")
}
```

#### Sign out

```swift
Blockstack.shared.signOut()
```

#### Retrieve user profile data

```swift
let retrievedUserData = Blockstack.shared.loadUserData()
print(retrievedUserData?.profile?.name as Any)
```

#### Storage

Store data as json on Gaia

```swift
Blockstack.shared.putFile(path: "myFile.json", content: content) { (publicURL, error) in
    if error != nil {
        print("put file error")
    } else {
        print("put file success \(publicURL!)")
    }
}
```

Read json data from Gaia

```swift
Blockstack.shared.getFile(path: "myFile.json", completion: { (response, error) in
    if error != nil {
        print("get file error")
    } else {
        print("get file success")
        print(response as Any)
    }
})
```

## Author

Blockstack PBC


