# SignIn-awsmhh
##### Overview
SignIn-awsmhh is an example of an AWS User Pools authentication for IOS written in Swift.  Compatible with Swift 3 now. 
- "Cognito Your User Pools" login is implemented
- Facebook and Google+ login is implemented
- Signup, Forgot Password and Update Attributes are implemented
- While some functions require entry of a verification code and that is implemented, if you terminate the app there needs to be a way to enter that code, and that is NOT implemented.
- MFA (multi-factor authentication) is not implemented.
- Supports identity linking


##### Background
This app was built to use the far superior mobile-hub-helper framework to replace earlier efforts with the ios-sdk samples.

##### What the App does
The app is written in Swift using AWS Mobile Hub Helper and AWS Mobile Client (from the AWS Mobile Hub). The app has a logged in and a not logged in state.  Both should be allowed (in your cognito console federated identity choose -allow unauthenticated identities). The app will allow login using Facebook, Google and a custom User Pool that you create in Cognito User Pools. You can switch between identities  or link identities.  The app allows you to Sign Out (which simply signs you out of one SignInProvider account, possibly leaving you logged in as the same identity on another linked account).  The app also allows you to Sign Out of ALL accounts . The app supports the latest AWS IOS SDK and currently is written in Swift 2.

##### Building SignIn-awsmhh
- Clone or download the repository using the --recursive option (this will get the correct fixed version of aws-mobile-hub-helper).
- Install cocoapods
- The Podfile is all set up with dependencies (except aws-mobile-hub-helper which is not a cocoaPod)
- Account setup
    - If you need help configuring on the console, the easiest way to do this next step may be to use AWS Mobile Hub to create configure and download an app using your google and facebook keys, and then copy the keys you need from the Info.plist in that downloaded app.   
    - Use AWS account and create a User Pool in the Cognito console.
        -   Make sure you make a User Pool not a Federated Identities Pool
        -   Configure your User Pool with email as a required field (aka Attribute) and no other required fields. If you want phone number to be required, or want more fields then you would need to change the SignupViewController.swift to require the required ones, and allow input of all attributes.  As delivered Signin requires only Username, Password (which are required by default) and Email Address (A real email is needed to get the Confirmation Number).  You may use Email Address as an alias if you wish.
        -   On the Pool Details page take note of your Pool Name and your Pool ID
        -   On the same page add an app to your User Pool. Specify the same name you intend to use for your app name. I used "signin". Click on Show Details and take note of the App Client Id, and the App Client Secret.  Click Save Changes.
        -   Take a look at the Policies section of the Pool Details page to see what password requirements you want to implement.  I unchecked "Require special characters" and required a minimum length of only 6.  If you use something other than that edit the storyboard text for the signup view controller to say that they are required.  
    - Use AWS account and create a Federated identity pool in the Cognito console.
        -   This will automatically create (if you let it) roles for authenticated and unauthenticated users.
        -   Choose "allow unauthenticated identities" (I have not tested without unauthenticated identities)
        -   Choose authentication providers, and add their keys.  
        -   When configuring Google+ (Google Plus), note that Google is an Open ID Connect provider and should be configured by:      
                - Configuring Google in "Authentication Providers"
                - Configuring an identity provider in IAM
                - Configuring an OIDC (Open ID Connect) provider in "Authentication Providers"
                - The mobile hub website will do this for you if you start configuring there.
        -   Configure Facebook  in "Authentication Providers"
        -   Configure your Cognito User Pool from above in "Authentication Providers"
        

- To build the app you need an enhanced version of the mobile-hub-helper (changes are described at the bottom of the README.md). If you clone this repository with --recursive you will get the correct version.
- cd to top level directory aws-mobile-hub-helper (inside SignIn-awsmhh/aws-mobilehub-helper-ios) and do ``pod install``.  If for some reason (like you didn't clone --recursive) there is no Podfile, then clone the correct version of aws-mobile-hub-helper-ios into this directory and then do pod install')
- Create a new file in Xcode File > New > File... > IOS > Other > Configuration Settings File.  Name the file AWSKeys.xcconfig (because that is the filename ignored in the .gitignore, and that might help you avoid uploading your keys to github!).  In that file put the following:

```
    //
    //  AWSKeys.xcconfig
    //
    // This file should be in .gitignore so keys don't end up on github
    // keys entered here are referenced in Info.plist

    COGNITO_USER_POOL_APP = signin
    COGNITO_USER_POOL_NAME = Your Pool Name
    COGNITO_USER_POOL_ID = Your Pool ID
    COGNITO_USER_POOL_APP_CLIENT_ID = Your App Client ID
    COGNITO_USER_POOL_APP_CLIENT_SECRET = Your App Client Secret
    COGNITO_REGIONTYPE = Your region name for instance USEast1

    // Note:  this is the federated Identity Pool ID (And not the one for the user pool)
    COGNITO_IDENTITY_POOL_ID = Your federated identities pool id
// After the user is authenticated, I have to add that user's identity
// token to the logins map in the credentials provider
// (Cognito? not user pools.  I think this is how Cognito finds out about
// User Pools (and developer authenticated IdP's)).
// So my Amazon User Pool Provider name is:


COGNITO_USER_POOL_IDP_NAME = cognito-idp.us-east-1.amazonaws.com/< your pool id like us-east-1_sfoOIFIdif>

// this ID goes in a login entry dictionary in the cognito
// credentials provider that includes
// COGNITO_USER_POOL_IDP_NAME:"ID Token from IDP (in this case User Pools)"
//

GOOGLE_CLIENT_ID = from your mobile hub downloaded info.plist
GOOGLE_URL_SCHEME = from your mobile hub downloaded info.plist
FACEBOOK_APP_ID =  from your mobile hub downloaded info.plist

// this next one is never used, and can be left out.  I just do it for documentation.
PROJECT_CLIENT_ID = < Not needed... from the Info.plist downloaded when you made a mobile hub like MobileHub 3252345-3245-325-345-3425-2345 aws-my-sample-app-ios-swift-v0.4>

```
- You must specify (before the next step) your AWSKeys.xcconfig as a Configuration for (Debug and Release) in your project settings -> Select Project -> Select Info -> Select Configurations -> Select the AWSKeys file in both  Debug and Release. 
- You must do a Product -> Clean ( If you change the configuration of AWSKeys.xcconfig settings you must do it again in order for it to update Info.plist
- Build and Run (Tested on a iPhone6 format machine)



##### Changes to aws/mobile-hub-helper
- The following changes were required and have been made. If you want to use user pools or developer identities and/or link identities, these are fixes.  If you want to use only google or facebook, and one at a time these are enhancements.
    -   Expose the required method completeLogin and allow AWSSignInProvider's to resume sessions when the app restarts (in addition to the hard-coded Google and Facebook). Required to allow a swift AWSSignInManager (without using bridging headers).
    -   Enhancement to provide currentSignInProvider externally to AWSIdentityManager (via the currentSignInProvider and providerKey methods) so that Cognito User Pools providers (and developer providers) can manage signup, signin, update attributes, forgot password etc.  To do those you need to be get at your user pool from within the app (unless you want to do the web redirection approach used by google and facebook (which is unnecessarily complex for developer providers).
    -   The mobile-hub-helper has a hard-coded affinity for Google+ and Facebook.  Only those two providers may resume sessions using AWSIdentityManager. While it is possible to try to go around AWSIdentityManager and AWSMobileClient using appDelegate code, a better solution is to make AWSIdentityManager resume any type of session that any AWSSignInProvider produces. Added a SignInProviderKeyDictionary entry to Info.plist.  This dictionary relates AWSSignInProvider class names to keys stored in NSUserDefaults, instead of just hard coding "Google" and "Facebook".
    -   Created AWSCUPIdPSignInProvider.swift.  This class, included in this repository, is an AWSSignInProvider for Cognito User Pools.  It makes sense to include it in aws-mobile-hub-helper, but I did not because that repo is distributed as a static library and swift cannot make those.
    -   Added the ability to find out the name of the key in NSUserDefaults (Google, Facebook, and whatever friendly key name you use for User Pools) which is useful for the App being able to tell what Authentication Provider is giving the error (ex: "Login with Google failed Because" rather than "Login failed because")
    -   Added the ability to merge identities. If you set the boolean Info.plist key “Allow Merged Identities” to YES, AWSIdentityManager will maintain an NSDictionary called cachedLogins, which is added to when a new login call is made and which is shortened when a logout call is made.  Then when it returns logins it always returns the loginCache. (This code now works even if identities cannot be merged.  In that case the merge request should be canceled so: the provider is logged out (this removes that new identity that was unmergable from the running app, wipes the keychain, cleans up loginCache and removes the NSUserDefaults session key) and the application goes through a resume process where it starts any remaining sessions (there will always be at least one). 
    -   Modified to reload all the signInProviders that left NSUserDefaults keys, not just one of them as before).  Now maintains a cache of the providers (in addition to a cache of logins). Supports providerKey(signInProvider) method to get current provider key name (a friendly name) for ANY provider (not just the currently active provider).  Use of all of this is demonstrated in the SignIn-awsmhh app.  What this will let us do is improve the above behavior when a login error occurs because identities cannot be be merged, and leave the user authenticated with the prior signInProvider after that rejection (code to do that is in test).


##### Use modified aws-mobile-hub-helper-ios with AWS Mobile Hub 

The project group SharedMobileHubSources are sources needed by both SignIn-awsmhh and MySampleApp (which was downloaded from the Mobile Hub).  Each of these is included in both targets.

Changes to the Mobile Hub sources were tracked in git, so you can use View-Version Editor to see the differences.  The changes are as follows:
- Updated to compile using Swift 3
- Updated to remove the use of //import AWSMobileHubHelper because now it uses SignIn-awsmhh-Bridging-Header.h to access the libraries in the shared submodule aws-mobile-hub-helper-ios.
- Made changes to SignInViewController to make it log in with User Pools.
- Made changes to MainViewController to make it log in multiple times to support identity linking.

##### Use modified aws-mobile-hub-helper-ios with YOUR AWS Mobile Hub download


**First:**  I assume what you are trying to do is to make one of the MySampleApp's from Mobile Hub work with Cognito User Pools.  And that you have set up a user pool and also have configured the app for google and facebook and your desired capabilities in the mobile hub.

- assuming that is correct, and done then here are the steps

_(There might be an easier processes than the one below to do all this, but this way you can use the symbolic debugger on the AWS code (which I find is necessary from time to time.))_

- Configure and download the sample app, in this example I refer to the downloaded app as MySampleApp
- **CHECKPOINT** Build the sample app and it should run, if it doesn’t, fix that first.
- Create an AWSKeys.xcconfig file, with the key information from your Info.plist in your MySampleApp project.
- Open your “MySampleApp” in xcode
- Rename your Info.plist to OldInfo.plist( Under App/SupportingFiles )
- Right Click on SupportingFiles and choose add files to “MySampleApp”
- Add the file Info.plist from SignIn-awsmhh (If you don’t have it, grab that off github… Suggest you github clone —recursive the repo)
- (This part is variable depending upon what DEMO features you enabled in the Mobile Hub site, but in Info.plist copy any of the keys under AWS in the OldInfo.plist into you Info.plist.  This includes ContentManager, DynamoDBObjectMapper, Cognito, and UserFileManager.
- BUT do not change IdentityManager or CredentialsProvider
- delete OldInfo.plist move to trash
- Right Click on MySampleApp and choose add files to “MySampleApp”
- Add the .gitignore file from SignIn-awsmhh (you will have to hold Command-Shift-. to see it and add it once you choose add files)
- In your project settings -> Select Project -> Select Info -> Select Configurations -> Select the AWSKeys.xcconfig file in both  Debug and Release.
- (now your keys configuration comes from the AWSKeys.xcconfig file.)
- IMPORTANT: Choose product clean (this will rebuild the Info.plist from the AWSKeys.xcconfig
- at this point, the app should run just fine just like it used to.  Try it to be sure.  If it doesn’t fix that first.
- Now you are going to replace the aws-mobile-hub-helper-framework, with the updated one.
- Under Frameworks delete AWSMobileHubHelper.framework and move it to trash
- Then in terminal: 
cd to your MySampleApp home (I.E. to the app home (where the .xcodeproj file is))
- The next steps put MySampleApp under git source control
```
git init
git add -A
git submodule add https://github.com/BruceBuckland/aws-mobilehub-helper-ios.git
cd aws-mobilehub-helper-ios
```
- Now you have to get to the old Swift 2 version of the AWSCUPIdPSignInProvider.swift file.  Because the swift3 version is not compatible with the Mobile Hub.

```
git checkout 79b396ca7c4718bac263d6c1604de96d15b67bf3
```
- _(Note: You can also use any commit before swift3 compatibility.  This is only because the Mobile Hub downloads swift 2 code )_

```
pod install
```
- _(Note: pod install loads the libraries for the dependencies for the aws-mobile-hub-helper-ios)_

- open aws-mobile-hub-helper-ios in xcode (open ./aws-mobile-hub-helper-ios/AWSMobileHubHelper.xcworkspace)
- Click run to Build the project
- Back in the terminal the following lines will 
- build the .framework ( and put out BUILD SUCCEEDED)
- create an empty podfile"Podfile", for the your project name

```
./Scripts/GenerateHelperFramework.sh
cd ..
pod init

```

- edit the Podfile using your favorite editor and make the Podfile look like this.

```
platform :ios, '9.0'

target 'MySampleApp' do
# Comment this line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!

# Pods for MySampleApp
pod 'AWSCognito'
pod 'AWSCognitoIdentityProvider'
end
```

- _(Note: I don't think the **platform :ios, '9.0'** is critical, other versions should work. This is just how I tested)_
- Get dependencies

```
pod install
```

- open xcode and open the xcworkspace for MySampleApp (NOT the xcodeproj)
- right click on Frameworks and add files to MySampleApp
- the file you want is in aws-mobile-hub-helper-ios/builtFramework/framework and then highlight AWSMobileHubHelper.framework and click Add.
- **CHECKPOINT** Build and run the project. The app should build and function fine, if it doesn’t, stop and fix it.
- You are using the updated version of the aws-mobile-hub-helper-ios, and you can now (for instance) click cancel in facebook login without a problem… which the standard app does not do). You can also add UserPools to your login providers.

- To add userpools

- In your app edit MySampleApp/MySampleApp/App/SignIn/SignInViewController.swift. Replace the function handleCustomLogin() with
```
// CUPIdP changes

// Now facebook and Google prompt for UID password, but in the demo app this signin view
// prompts BEFORE the user even chooses the signInProvider.
// For a "minimal change" fix, just to get User Pools working for the first time
// I am going to stick the username and password into the shared
// instance of AWSCUPIdPSignInProvider.  
// If AWS had thought harder about AWSIdentityManager it would have a loginWithUsernamePassword 
// method.


func handleCustomLogin() {

// Handle Login logic for User Pools Sign In using OpenID Connect
//

// let AWSInfoIdentityManager = "IdentityManager"

if (customUserIdField.text != nil) && (customPasswordField.text != nil) {


let customSignInProvider = AWSCUPIdPSignInProvider.sharedInstance

// Push userId and password to our AWSCUPIdPSignInProvider

customSignInProvider.customUserIdField = customUserIdField.text
customSignInProvider.customPasswordField = customPasswordField.text

handleLoginWithSignInProvider(customSignInProvider)

}
}

```
- This code references AWSCUPIdPSignInProvider, a new AWSSignInProvider, it is not in the framework (because AWS still distributes the framework as a static library, and because swift files can't make static libraries) 

- Right click MySampleApp (the source directory not the one at the top level) and Add files to MySampleApp
- add the file you will find in the MySampleApp/aws-mobile-hub-helper-ios/AWSMobileHubHelper/SignIn/AWSCUPIdPSignInProvider.swift.
- Build and run.
- You can now log in with Cognito User Pools, Facebook and Google.

- Further (if you change the MainViewController.swift a little so that you can signin even when you are signed in… ) you can log into multiple ID providers simultaneously and merge cognito identities between the providers.

_I know this just lets you login (the signup etc won’t work.  You can use SignIn-awsmhh to create accounts). If you want to create accounts, update attributes, etc in the sample there is a little work to do, but not too much. If you can’t figure out how, you will have to take a look at the SignIn-awsmhh example._
- Here are some hints on using cognito user pools in this environment:
  - you can invoke AWSIdentityManager.currentSignInProvider to get the current provider.
  - You can find the friendly name of a provider as a string, using AWSIdentityManager.providerKey 
  - If currentSignInProvider is AWSCUPIdPSignInProvider (check with conditional binding) it has properties: 
    - pool - The cognito user pool
    - user - The cognito user pool user
  - Using those properties you can invoke the various methods for manipulating Cognito User Pools: signup, forgot password, updateAttributes, confirmation messages etc.

