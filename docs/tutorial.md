
This tutorial teaches you how to create a decentralized application using
Blockstack's iOS SDK using the following content:

- [Understand the sample application flow](#understand-the-sample-application-flow)
- [Set up your environment](#set-up-your-environment)
	- [Install XCode](#install-xcode)
	- [Do you have npm?](#do-you-have-npm)
	- [Install the CocoaPods 1.6.0.beta.1 dependency manager](#install-the-cocoapods-160beta1-dependency-manager)
	- [Use npm to install Yeoman and the Blockstack App Generator](#use-npm-to-install-yeoman-and-the-blockstack-app-generator)
- [Build the Blockstack hello-world](#build-the-blockstack-hello-world)
	- [Generate and launch your hello-blockstack application](#generate-and-launch-your-hello-blockstack-application)
	- [Add a redirect end point to your application](#add-a-redirect-end-point-to-your-application)
- [Build the hello-blockstack-ios](#build-the-hello-blockstack-ios)
	- [Create an XCode Project](#create-an-xcode-project)
	- [Add and edit a Podfile](#add-and-edit-a-podfile)
	- [Install Blockstack SDK and open the pod project](#install-blockstack-sdk-and-open-the-pod-project)
	- [Choose a custom protocol handler](#choose-a-custom-protocol-handler)
	- [Add a splash screen](#add-a-splash-screen)
	- [Add a Main.storyboard](#add-a-mainstoryboard)
  - [Add the UI variables to the ViewController file.](#add-the-ui-variables-to-the-viewcontroller-file)
	- [Edit the ViewController.swift file](#edit-the-viewcontrollerswift-file)

This tutorial was extensively tested using XCode 9.3 on a MacBook Air
running High Sierra 10.13.4. If your environment is different, you may encounter
slight or even major discrepancies when performing the procedures in this
tutorial. Please [join the Blockstack community Slack](https://slofile.com/slack/blockstack) and post questions or comments to
the `#support` channel.

Finally, this tutorial is written for all levels from the beginner to the most
experienced. For best results, beginners should follow the guide as written. It
is expected that the fast or furiously brilliant will skip ahead and improvise
on this material at will. God speed one and all.

If you prefer, you can skip working through the tutorial all together. Instead,
you can [download the final project code](#) and import it
into XCode to review it.

## Understand the sample application flow

When complete, the sample application is a simple `hello-world` display. It is
intended for user on an iOS phone.

![](images/final-app.png)

Only users with an existing `blockstack.id` can run your
final sample application. When complete, users interact with the sample
application by doing the following:

![](images/app-flow.png)

## Set up your environment

This sample application requires two code bases, a BlockStack `hello-blockstack` web
application and a `hello-ios` iOS application. You use the iOS application to run the
web application on an iOS device.

Before you start developing the sample, there are a few elements you need in
your environment.

### Install XCode

If you are an experienced iOS developer and already have an iOS
development environment on your workstation, you can use that and skip this
step. However, you may need to adjust the remaining instructions for your
environment.

Follow the installation instructions to [download and XCode](https://developer.apple.com/xcode/) for your operating system.
Depending on your network connection, this can take between 15-30 minutes.

### Do you have npm?

The Blockstack code in this tutorial relies on the `npm` dependency manager.
Before you begin, verify you have installed `npm` using the `which` command to
verify.

```bash
$ which npm
/usr/local/bin/npm
```

If you don't find `npm` in your system, [install
it](https://www.npmjs.com/get-npm).

### Install the CocoaPods 1.6.0.beta.1 dependency manager

The sample application only runs on devices with iOS 11.0 or higher. You install
the Blockstack iOS SDK through the CocoaPods dependency manager. You must use
the `1.6.0.beta.1` version of CocoaPods or newer to avoid an incapability
between Cocoapods and XCode.

Before starting the tutorial, confirm you have installed CocoaPods.

```bash
$ pod --version
1.6.0.beta.1
```

If you don't have the CocoaPods beta version, install it:

```bash
sudo gem install cocoapods -v 1.6.0.beta.1
```

### Use npm to install Yeoman and the Blockstack App Generator

You use `npm` to install Yeoman. Yeoman is a generic scaffolding system that
helps users rapidly start new projects and streamline the maintenance of
existing projects.


1. Install Yeoman.

    ```bash
    npm install -g yo
    ```
2. Install the Blockstack application generator.

    ```bash
    npm install -g generator-blockstack
    ```
## Build the Blockstack hello-world

In this section, you build a Blockstack `hello-world` application. Then, you
modify the `hello-world` to interact with the iOS app via a redirect.

### Generate and launch your hello-blockstack application

In this section, you build an initial React.js application called
`hello-blockstack`.

1. Create a `hello-blockstack` directory.

    ```bash
    mkdir hello-blockstack
    ```

2. Change into your new directory.

    ```bash
    cd hello-blockstack
    ```

3. Use Yeoman and the Blockstack application generator to create your initial `hello-blockstack` application.

    ```bash
    yo blockstack:react
    ```

    You should see several interactive prompts.

    ```bash
    $ yo blockstack:react
    ==========================================================================
    We are constantly looking for ways to make yo better!
    May we anonymously report usage statistics to improve the tool over time?
    More info: https://github.com/yeoman/insight & http://yeoman.io
    ========================================================================== No

         _-----_     ╭──────────────────────────╮
        |       |    │      Welcome to the      │
        |--(o)--|    │      Blockstack app      │
       `---------´   │        generator!        │
        ( _´U`_ )    ╰──────────────────────────╯
        /___A___\   /
         |  ~  |
       __'.___.'__
     ´   `  |° ´ Y `

    ? Are you ready to build a Blockstack app in React? (Y/n)
    ```

4. Respond to the prompts to populate the initial app.

    After the process completes successfully, you see a prompt similar to the following:

    ```bash
    [fsevents] Success:
    "/Users/theuser/repos/hello-blockstack/node_modules/fsevents/lib/binding/Release/node-v59-darwin-x64/fse.node"
    is installed via remote npm notice created a lockfile as package-lock.json.
    You should commit this file. added 1060 packages in 26.901s
    ```

5. Run the initial application.

    ```bash
    npm start

    > hello-blockstack@0.0.0 start /Users/moxiegirl/repos/hello-blockstack
    > webpack-dev-server

    Project is running at http://localhost:8080/
    webpack output is served from /
    404s will fallback to /index.html
    Hash: 4d2312ba236a4b95dc3a
    Version: webpack 2.7.0
    Time: 2969ms
                                     Asset       Size  Chunks                    Chunk Names
    ....
      Child html-webpack-plugin for "index.html":
         chunk    {0} index.html 541 kB [entry] [rendered]
             [0] ./~/lodash/lodash.js 540 kB {0} [built]
             [1] ./~/html-webpack-plugin/lib/loader.js!./src/index.html 533 bytes {0} [built]
             [2] (webpack)/buildin/global.js 509 bytes {0} [built]
             [3] (webpack)/buildin/module.js 517 bytes {0} [built]
     webpack: Compiled successfully.
     ```

   The system opens a browser displaying your running application.

  ![](images/blockstack-signin.png)

   At this point, the browser is running a Blockstack server on your local host.
   This is for testing your applications only.

6. Choose **Sign in with Blockstack**

   The system displays a prompt allowing you to create a new Blockstack ID or restore an existing one.

    ![](images/create-restore.png)

7. Follow the prompts appropriate to your situation.

    If you are restoring an existing ID, you may see a prompt about your user
    being nameless, ignore it. At this point you have only a single application
    on your test server.  So, you should see this single application, with your
    own `blockstack.id` display name, once you are signed in:

    ![](images/running-app.png)


### Add a redirect end point to your application

When a user opens the webapp from the Blockstack browser on an iOS phone,
you want the web app to redirect the user to your iOS application. The work
you do here will allow it.

1. From the terminal command line, change directory to the root of your web
application directory.

2. Use the `touch` command to add a redirect endpoint to your application.

   This endpoint on the web version of your app will redirect iOS users back
   to your mobile app.

    ```bash
    $ touch public/redirect.html
    ```

3. Open `redirect.html` and add code to the endpoint.

    ```
    <!DOCTYPE html>
    <html>
    <head>
      <title>Hello, Blockstack!</title>
      <script>
      function getParameterByName(name) {
        var match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
        return match && decodeURIComponent(match[1].replace(/\+/g, ' '));
      }

      var authResponse = getParameterByName('authResponse')
      window.location="myblockstackapp:" + authResponse
      </script>
    <body>
    </body>
    </html>
    ```

    Blockstack apps are identified by their domain names.  The endpoint will
    receive a get request with the query parameter `authResponse=XXXX` and
    should redirect the browser to `myblockstackapp:XXXX`.

    `myblockstackapp:` is custom protocol handler. The handler should be unique
    to your application. Your app's web-based authentication uses this handler
    to redirect the user back to your iOS app. Later, you'll add a reference
    to this handler in your iOS application.

5. Close and save the `redirect.html` file.
6. Ensure your Blockstack compiles successfully.

## Build the hello-blockstack-ios

Now, you build an iOS application that can access and run your Blockstack web
application on a mobile device.

### Create an XCode Project

This tutorial uses XCode 9.3, you can use another version but be aware that some
menu items and therefore these procedures may be differœent on your version.

1. Launch the XCode interface.
2. Choose **Create new XCode project**.
3. Select **iOS**.
4. Select **Single View Page**.

   ![](images/single-view-app.png)

5. **Choose options for your new project** for your project.

	 ![](images/choose-new-options.png)

6. Press **Next**.

   The system prompts you for a location to store your code.

7. Save your project.
8. Close XCode.


### Add and edit a Podfile

To use CocoaPods you need to define the XCode target to link them to.
So for example if you are writing an iOS app, it would be the name of your app.
Create a target section by writing target '$TARGET_NAME' do and an end a few
lines after.

1. Open a terminal window on your workstation.
2. Navigate to and change directory into the root of your project directory.

	 ```swift
	 $ cd hello-blockstack-ios
	 ```
3. Create a Podfile.

	 ```bash
	 $ pod init
	 ```

	 The command creates a `Podfile` in the directory.

4. Open the `Podfile` for editing.
5. Add a line stating the Blockstack dependency.

   ```
   # Uncomment the next line to define a global platform for your project
   # platform :ios, '9.0'

   target 'hello-blockstack-ios' do
		 # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
		 use_frameworks!

		 # Pods for hello-blockstack-ios
		 pod 'Blockstack'

		 target 'hello-blockstack-iosTests' do
		   inherit! :search_paths
		   # Pods for testing
		 end
   end
   ```

8. Save and close the `Podfile`.

### Install Blockstack SDK and open the pod project

1. Close your new XCode project.
2. Change to the root of your `hello-blockstack-is` project.
3. Initialize the project with Cocoapods.

	 ```
	 $ pod install
	 Analyzing dependencies
	 Downloading dependencies
	 Installing Blockstack (0.2.0)
	 Installing CryptoSwift (0.11.0)
	 Generating Pods project
	 Integrating client project

	 [!] Please close any current XCode sessions and use `hello-blockstack-ios.xcworkspace` for this project from now on.
	 Sending stats
	 Pod installation complete! There is 1 dependency from the Podfile and 2 total pods installed.

	 [!] Automatically assigning platform `ios` with version `11.4` on target `hello-blockstack-ios` because no platform was specified. Please specify a platform for this target in your Podfile. See `https://guides.cocoapods.org/syntax/podfile.html#platform`.
	 ```

	This command creates a number of files

4. Review the files that the `pod` installation created:

   ```bash
   $ ls
   Podfile                hello-blockstack-ios                    hello-blockstack-iosTests
   Podfile.lock           hello-blockstack-ios.xcodeproj
   Pods                   hello-blockstack-ios.xcworkspace
   ```
5. Start XCode and choose **Open another project**.
6. Choose the `.xcworkspace` file created in your project folder.

	 ![](images/open-xcworkspace.png)

	 When you open the workspace you'll see a warning indicator at the top in the
	 project title.

7. Click the signal to reveal the warning.
8. Click **Update to recommented settings**.

	 ![](images/indicator.png)

9. Choose **Perform Changes** and **Continue** when prompted.

	 The indicator disappears.

### Choose a custom protocol handler

You'll need to choose a custom protocol handler that is unique to your app. This
is so that your app's web-based authentication `redirect.html` endpoint can redirect
the user back to your iOS app. In this example, you use `myblockstackapp://`.

1. Open the `.xcworkspace` file in XCode if it isn't open already.
2. Select the top node of your project.
1. Select the **Info** tab in XCode.
2. Scroll to **URL Types** and press **+** (plus) sign.
3. Enter an **Identifier** and **URL Schemes** value.
4. Set the **Role** to **Editor**.

   When you are done the type appears as follows:

	 ![](images/url-type.png)

### Add a splash screen

All iOS applications require a splash page.

1. Select `Assets.xcassets`
2. Move your cursor into the area below Appicon.
3. Right click and choose **New Image Set**

   ![](images/image-set-0.png)

4. Download the Blockstack icon.

   ![](images/blockstack-icon.png)

5. Drag the downloaded file into the **3X** position in your new Images folder.

    ![](images/image-set-1.png)

6. Select the `LaunchScreen.storyboard`.
7. Choose **Open As > Source Code**.

	![](images/open-as.png)

8. Replace the content of the `<scenes>` element with the following:

   ```
   <scenes>
       <!--View Controller-->
       <scene sceneID="EHf-IW-A2E">
           <objects>
               <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                   <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                       <rect key="frame" x="0.0" y="0.0" width="375" height="667"/>
                       <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                       <subviews>
                           <imageView userInteractionEnabled="NO" contentMode="scaleToFill" horizontalHuggingPriority="251" verticalHuggingPriority="251" image="Image" translatesAutoresizingMaskIntoConstraints="NO" id="SpU-hA-y2f">
                               <rect key="frame" x="155.5" y="273" width="64" height="64"/>
                           </imageView>
                           <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Hello Blockstack iOS" textAlignment="natural" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="Wfj-A6-BZM">
                               <rect key="frame" x="108" y="432" width="158" height="21"/>
                               <fontDescription key="fontDescription" type="system" pointSize="17"/>
                               <nil key="textColor"/>
                               <nil key="highlightedColor"/>
                           </label>
                       </subviews>
                       <color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                       <constraints>
                           <constraint firstItem="Wfj-A6-BZM" firstAttribute="centerX" secondItem="6Tk-OE-BBY" secondAttribute="centerX" id="AZy-qf-xHq"/>
                           <constraint firstItem="Wfj-A6-BZM" firstAttribute="top" secondItem="6Tk-OE-BBY" secondAttribute="top" constant="412" id="SwP-qV-1RP"/>
                           <constraint firstItem="SpU-hA-y2f" firstAttribute="centerX" secondItem="6Tk-OE-BBY" secondAttribute="centerX" id="XdI-Db-fDo"/>
                           <constraint firstItem="SpU-hA-y2f" firstAttribute="top" secondItem="6Tk-OE-BBY" secondAttribute="top" constant="253" id="xc5-po-W1E"/>
                       </constraints>
                       <viewLayoutGuide key="safeArea" id="6Tk-OE-BBY"/>
                   </view>
               </viewController>
               <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
           </objects>
           <point key="canvasLocation" x="52" y="374.66266866566718"/>
       </scene>
   </scenes>
   ```

9. Immediately after scenes but before the close of the `</document>` tag add the following `<resources>`.

   ```xml
		   <resources>
         <image name="Image" width="64" height="64"/>
		   </resources>
		</document>
   ```

10. Choose **Run > Run app** in the emulator.

	  The emulator now contains a new splash screen.

	  ![](images/splash.png)


### Add a Main.storyboard

Rather than have you build up your own UI, this section has you copy and paste a layout into the XML file source code for the **Main.storyboard** file.

1.  Select the `Main.storyboard` file.
2.  Chooose **Open As > Source Code**

    The `blockstack-example/blockstack-example/Base.lproj/Main.storyboard` file
    defines the graphical elements. Some elements are required before you can
    functionality to your  code.

3. Replace the <view> element with the following:

   ```xml
   <view key="view" contentMode="scaleToFill" id="8bC-Xf-vdC">
        <rect key="frame" x="0.0" y="0.0" width="375" height="667"/>
        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
        <subviews>
            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="hello-blockstack-ios" textAlignment="center" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="9eE-ZS-LU9">
                <rect key="frame" x="0.0" y="101" width="375" height="50"/>
                <color key="backgroundColor" red="0.44735813140000003" green="0.1280144453" blue="0.57268613580000005" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                <constraints>
                    <constraint firstAttribute="height" constant="50" id="U5v-13-4Ux"/>
                </constraints>
                <fontDescription key="fontDescription" type="system" pointSize="17"/>
                <color key="textColor" white="1" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                <nil key="highlightedColor"/>
            </label>
            <button opaque="NO" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="roundedRect" lineBreakMode="middleTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="Lfp-KX-BDb">
                <rect key="frame" x="100" y="382" width="175" height="40"/>
                <color key="backgroundColor" red="0.1215686275" green="0.12941176469999999" blue="0.14117647059999999" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                <constraints>
                    <constraint firstAttribute="height" constant="40" id="8fN-Ro-Krn"/>
                </constraints>
                <color key="tintColor" white="0.0" alpha="1" colorSpace="calibratedWhite"/>
                <state key="normal" title="Sign into Blocksack">
                    <color key="titleColor" white="1" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                </state>
                <connections>
                    <action selector="signIn:" destination="BYZ-38-t0r" eventType="touchUpInside" id="nV7-rt-euZ"/>
                </connections>
            </button>
            <button hidden="YES" opaque="NO" contentMode="scaleToFill" contentHorizontalAlignment="center" contentVerticalAlignment="center" buttonType="roundedRect" lineBreakMode="middleTruncation" translatesAutoresizingMaskIntoConstraints="NO" id="k0H-mY-bo5">
                <rect key="frame" x="100" y="382" width="175" height="40"/>
                <color key="backgroundColor" red="0.1215686275" green="0.12941176469999999" blue="0.14117647059999999" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                <constraints>
                    <constraint firstAttribute="height" constant="40" id="lI1-yb-ABZ"/>
                </constraints>
                <color key="tintColor" white="0.0" alpha="1" colorSpace="calibratedWhite"/>
                <state key="normal" title="Sign out">
                    <color key="titleColor" white="1" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                </state>
                <connections>
                    <action selector="signOut:" destination="BYZ-38-t0r" eventType="touchUpInside" id="hJe-os-Oph"/>
                </connections>
            </button>
        </subviews>
        <color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
        <constraints>
            <constraint firstItem="9eE-ZS-LU9" firstAttribute="leading" secondItem="6Tk-OE-BBY" secondAttribute="leading" id="2ZP-tU-h9Y"/>
            <constraint firstItem="k0H-mY-bo5" firstAttribute="centerY" secondItem="Lfp-KX-BDb" secondAttribute="centerY" id="3fo-sm-8bL"/>
            <constraint firstItem="k0H-mY-bo5" firstAttribute="width" secondItem="Lfp-KX-BDb" secondAttribute="width" id="ChB-0E-BpP"/>
            <constraint firstItem="9eE-ZS-LU9" firstAttribute="top" secondItem="6Tk-OE-BBY" secondAttribute="top" constant="81" id="DBh-q0-pAV"/>
            <constraint firstItem="6Tk-OE-BBY" firstAttribute="trailing" secondItem="Lfp-KX-BDb" secondAttribute="trailing" constant="100" id="MHO-ew-4Bd"/>
            <constraint firstItem="k0H-mY-bo5" firstAttribute="centerX" secondItem="Lfp-KX-BDb" secondAttribute="centerX" id="Rlk-ua-puu"/>
            <constraint firstItem="Lfp-KX-BDb" firstAttribute="leading" secondItem="6Tk-OE-BBY" secondAttribute="leading" constant="100" id="Rsm-LP-ya7"/>
            <constraint firstItem="Lfp-KX-BDb" firstAttribute="top" secondItem="6Tk-OE-BBY" secondAttribute="top" constant="362" id="chE-B7-ya6"/>
            <constraint firstItem="6Tk-OE-BBY" firstAttribute="trailing" secondItem="9eE-ZS-LU9" secondAttribute="trailing" id="j0x-8j-04u"/>
        </constraints>
        <viewLayoutGuide key="safeArea" id="6Tk-OE-BBY"/>
    </view>
	 ```

### Add the UI variables to the ViewController file.

In this section, you edit the `ViewController.swift` file using the storyboard as a starting point.

1. Select the **Main.storyboard** and choose **Open As > Interface Builder - storyboard**.

	 ![](images/main-storyboard.png)

2. With the interface builder open, display the `ViewController.swift` file in the rigth panel.

   ![](images/view-editors.gif)

4. In the storyboard, select the **Sign into Blockstack** button.

5. Control-drag from the button to the code display in the editor on the right, stopping the drag at the line below controller's opening statement.

   ![](images/add-action.gif)

6. Repeat this process with the storyboard's purple **hello-blockstack-ios** label, and the **Sign out** button.

    When you are done, your ViewController file contains the following variables:

    ```swift
    class ViewController: UIViewController {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var signOutButton: UIButton!
    ```

    And XCode has added two outlines to the `Main.storyboard` source.

    ```xml
    <connections>
    <outlet property="nameLabel" destination="9eE-ZS-LU9" id="Ahv-Te-ZZo"/>
    <outlet property="signInButton" destination="Lfp-KX-BDb" id="yef-Jj-uPt"/>
    <outlet property="signOutButton" destination="k0H-mY-bo5" id="Y47-Za-lSc"/>
    </connections>
    ```

    Your connectors will have their own `destination` and `id` values.


### Edit the ViewController.swift file

Now, you are ready to connect your applicaiton with your Blockstack Web
Application. Normally, after building your Web application you would have
registred it with Blockstack and the app would be available on the Web. This
example skips this registroation step and uses an example application we've
already created for you:

`https://heuristic-brown-7a88f8.netlify.com/redirect.html`

This web application already has a redirect in place for you. You'll reference
this application in your mobile add for now. In XCode, do the following;


1. Open the `ViewController.swift` file.
2. Add an import both for `Blockstack` and for `SafariServices`.

   ```
	 import UIKit
	 import Blockstack
	 import SafariServices
	 ```

4. Just before the `didReceiveMemoryWarning` function a private `updateUI` function.

   This function takes care of loading the user data from Blockstack.

   ```
   private func updateUI() {
     DispatchQueue.main.async {
    		if Blockstack.shared.isSignedIn() {
    			// Read user profile data
    			let retrievedUserData = Blockstack.shared.loadUserData()
    			print(retrievedUserData?.profile?.name as Any)
    			let name = retrievedUserData?.profile?.name ?? "Nameless Person"
    			self.nameLabel.text = "Hello, \(name)"
    			self.nameLabel.isHidden = false
            self.signInButton.isHidden = true
            self.signOutButton.isHidden = false
    		} else {
            self.signInButton.isHidden = false
            self.signOutButton.isHidden = true
            self.nameLabel.isHidden = true
    		}
    	}
    }
    ```

5. Replace the content of the `viewDidLoad()` function so that it calls this private function.

   ```
	 override func viewDidLoad() {
		self.updateUI()
   }
	 ```

6. Add a `handleSignInSuccess()` function to handle sign in.

   ```
	 func handleSignInSuccess(userData: UserData) {
		 print(userData.profile?.name as Any)

		 self.updateUI()

		 // Check if signed in
		 // checkIfSignedIn()
	 }
   ```

7. Add a `signOut()` action to handle signOut

   ```
    @IBAction func signOut(_ sender: Any) {
        // Sign user out
        Blockstack.shared.signOut()
        self.updateUI()
    }
    ```

8. Add a function to check if a user is signed in

   ```swift
	 func checkIfSignedIn() {
		 Blockstack.shared.isSignedIn() ? print("currently signed in") : print("not signed in")
	 }
	 ```

9. Put it all together with a `signIn` action

   ```swift
	 @IBAction func signIn(_ sender: UIButton) {
     // Address of deployed example web app
     Blockstack.shared.signIn(redirectURI: "https://heuristic-brown-7a88f8.netlify.com/redirect.html",
        appDomain: URL(string: "https://heuristic-brown-7a88f8.netlify.com")!) { authResult in
        switch authResult {
        case .success(let userData):
          print("sign in success")
          self.handleSignInSuccess(userData: userData)
        case .cancelled:
          print("sign in cancelled")
        case .failed(let error):
          print("sign in failed, error: ", error ?? "n/a")
        }
	     }
	   }
     ```
