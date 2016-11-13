# SignIn-awsmhh

##### Overview
The SignIn app is an example of an AWS User Pools authentication for IOS written in Swift. 
- "Cognito Your User Pools" login is implemented
- Facebook and Google+ login is implemented
- Signup, Forgot Password and Update Attributes are implemented
- While some functions require entry of a verification code and that is implemented, if you terminate the app there needs to be a way to enter that code, and that is NOT implemented.
- MFA (multi-factor authentication) is not implemented.
- Supports identity linking

MySampleApp
- This is the source downloaded from MobileHub with most of the capabilities turned on.
- It uses the same MobileHubHelper as SignIn does.  The nice thing is that this means it has access to all of the capabilities of the modified MobileHubHelper, including identity linking and user pools.
- Small changes were required to make the code work in this project.
 - Removed some imports from the source, because I am using a bridging-header.
 - Changed the MainViewController to make it allow "linking" (which is really just signing in a second time with a different provider)
 - MySampleApp does not implement the SignUp Forgot Password etc in the sample app, but that would be pretty easy (I did that in the SignIn app)
 - Changed the SignInViewController to actually log in with User Pools when you type a username and password and click signin.  


##### Background
This app was built to use the far superior mobile-hub-helper framework to replace earlier efforts with the ios-sdk samples.

##### What the App does
The app is written in Swift using AWS Mobile Hub Helper and AWS Mobile Client (from the AWS Mobile Hub). The app has a logged in and a not logged in state.  Both should be allowed (in your cognito console federated identity choose -allow unauthenticated identities). The app will allow login using Facebook, Google and a custom User Pool that you create in Cognito User Pools. You can switch between identities  or link identities.  The app allows you to Sign Out (which simply signs you out of one SignInProvider account, possibly leaving you logged in as the same identity on another linked account).  The app also allows you to Sign Out of ALL accounts . The app supports the latest AWS IOS SDK and currently is written in Swift 2.
#Building
##### Building SignIn
- Clone the repository using the --recursive flag, that way you will get the aws-mobilehub-helper-ios installed for you.
- Install cocoapods
- Use AWS account and create a User Pool in the Cognito console.
    -   Make sure you make a User Pool not a Federated Identities Pool
    -   Configure your User Pool with email as a required field (aka Attribute) and no other required fields. If you want phone number to be required, or want more fields then you would need to change the SignupViewController.swift to require the required ones, and allow input of all attributes.  As delivered Signin requires only Username, Password (which are required by default) and Email Address (A real email is needed to get the Confirmation Number).
    -   On the Pool Details page take note of your Pool Name and your Pool ID
    -   On the same page add an app to your User Pool. Specify the same name you intend to use for your app name. I used "signin". Click on Show Details and take note of the App Client Id, and the App Client Secret.  Click Save Changes.
    -   Take a look at the Policies section of the Pool Details page to see what password requirements you want to implement.  I unchecked "Require special characters" and required a minimum length of only 6.  If you use something other than that edit the storyboard text for the signup view controller to say that they are required.  
- Use AWS account and create a Federated identity pool in the Cognito console.
- To build the app you need an enhanced version of the mobile-hub-helper (changes are described at the bottom of the README.md). Clone the mobile-hub-helper fork at https://github.com/BruceBuckland/aws-mobilehub-helper-ios which has a few small fixes in it to make it handle User Pools and/or developer identities.
- pod install
- The easiest way to do this next step may be to use AWS Mobile Hub to create configure and download an app using your google and facebook keys, and then copy the data you need from the Info.plist in that downloaded app.   But if you understand the console or aws cli, and are comfortable with Cognito and IAM, you can build the required config there and grab the id's needed for AWSKeys.config.
Create a new file in Xcode File > New > File... > IOS > Other > Configuration Settings File.  Name the file AWSKeys.xcconfig (because that is the filename ignored in the .gitignore, and that might help you avoid uploading your keys to github!).  In that file put the following:

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
PROJECT_CLIENT_ID = < from the Info.plist downloaded when you made a mobile hub like MobileHub 3252345-3245-325-345-3425-2345 aws-my-sample-app-ios-swift-v0.4>
```

- You will need to specify your AWSKeys.xcconfig as a Configuration for (Debug and Release) in your project settings -> Select Project -> Select Info -> Select Configurations -> Select the AWSKeys file in both  Debug and Release. 
- If you change the configuration of these settings you must do a Product -> Clean (which gets rid of the preconfigured info.plist I think, so the settings can find thier way to K. struct in ConstantsK.swift
- This app uses an AWSSignInProvider class called AWSCUPIdPSignInProvider that allows authentication using Cognito Your User Pools. 
- Build and Run (Tested on a iPhone6 format machine)



##### Optional, if you want to use the framework, you have to build it.
  - cd top level directory aws-mobile-hub-helper
  - Scripts/GenerateHelperFramework.sh (This puts a builtFramework directory at top level)
  - In xcode open SignIn-awsmhh remove the AWSMobileHubHelper.framework from that app and add the file aws-mobilehub-helper-ios/builtFramework/framework/AWSMobileHubHelper.framework to your app.

##### Changes to aws/mobile-hub-helper
- The following changes were required and have been made. If you want to use user pools or developer identities and/or link identities, these are needed fixes.  
    -   Expose the required method completeLogin and allow AWSSignInProvider's to resume sessions when the app restarts (in addition to the hard-coded Google and Facebook). Required to allow a swift AWSSignInManager (without using bridging headers).
    -   Enhancement to provide currentSignInProvider externally to AWSIdentityManager (via the currentSignInProvider and providerKey methods) so that Cognito User Pools providers (and developer providers) can manage signup, signin, update attributes, forgot password etc.  To do those you need to be get at your user pool from within the app (unless you want to do the web redirection approach used by google and facebook (which is unnecessarily complex for developer providers).
    -   The mobile-hub-helper has a hard-coded affinity for Google+ and Facebook.  Only those two providers may resume sessions using AWSIdentityManager. While it is possible to try to go around AWSIdentityManager and AWSMobileClient using appDelegate code, a better solution is to make AWSIdentityManager resume any type of session that any AWSSignInProvider produces. Added a SignInProviderKeyDictionary entry to Info.plist.  This dictionary relates AWSSignInProvider class names to keys stored in NSUserDefaults, instead of just hard coding "Google" and "Facebook".
    -   Created AWSCUPIdPSignInProvider.swift.  This class, included in this repository, is an AWSSignInProvider for Cognito User Pools.  It makes sense to include it in aws-mobile-hub-helper, but I did not because that repo is distributed as a static library and swift cannot make those.
    -   Added the ability to find out the name of the key in NSUserDefaults (Google, Facebook, and whatever friendly key name you use for User Pools) which is useful for the App being able to tell what Authentication Provider is giving the error (ex: "Login with Google failed Because" rather than "Login failed because")
    -   Added the ability to merge identities. If you set the boolean Info.plist key “Allow Merged Identities” to YES, AWSIdentityManager will maintain an NSDictionary called cachedLogins, which is added to when a new login call is made and which is shortened when a logout call is made.  Then when it returns logins it always returns the loginCache. (This code now works even if identities cannot be merged.  In that case the merge request should be canceled so: the provider is logged out (this removes that new identity that was unmergable from the running app, wipes the keychain, cleans up loginCache and removes the NSUserDefaults session key) and the application goes through a resume process where it starts any remaining sessions (there will always be at least one). 
    -   Modified to reload all the signInProviders that left NSUserDefaults keys, not just one of them as before).  Now maintains a cache of the providers (in addition to a cache of logins). Supports providerKey(signInProvider) method to get current provider key name (a friendly name) for ANY provider (not just the currently active provider).  Use of all of this is demonstrated in the SignIn app.  What this will let us do is improve the above behavior when a login error occurs because identities cannot be be merged, and leave the user authenticated with the prior signInProvider after that rejection (code to do that is in test).


##### Bugs and To Do
- Unless we have the delegate based authentication, the login screen requires the user to click "Sign-In".  But if it is a new user, the user needs to "Sign-Up".  So there is a UX problem (because the user might not click "Sign-In").

- If you try to link an identityId to another that has the same IdP, you get cannot merge identities.  This is correct.  However if you try to link an identity with a new username from the same Cognito Pool, you drive Cognito crazy and it keeps trying to get credentials using the new token for the old identityId, then gives up with a cryptic error (GetCredentialsForIdentity keeps failing. Clearing identityId did not help. Please check your Amazon Cognito Identity configuration.).  This is not a user friendly message.  If I try it again it works (having cleared the identityId, like it promised to do previously but clearly didn't).  The next login works in any case. This could be a credentials provider bug, or it could just be something we need to detect upon login.  Further investigation needed.

- If try to Sign up a user with a duplicate email address, it creates the user and when the user confirms, Cognito says "duplicate" and puts the user in an unusable state.  At this point there is no way to "fix that user other than administratively.  So this will result in practice with users that mess up with email addresses in a position where they need to pick a new username.  This seems very unfriendly.  The solution (obviously) is to notify the user that the email address is duplicate upon signup.  So.... We need to fetch the user that the user tries to sign up with BEFORE letting him fall into the mantrap that AWS have laid, and hopefully someday AWS will hide all this in the sdk.
  - A first version of a fix for this has now been applied to SignIn and MySampleApp.  The change applies to SignUpViewController. What it does is attempt to login with the alias (email) but uses a very unlikely password.  We expect it to fail in one of two ways. If it is not authorized, then the email exists as an alias to another user, if it is not found, then the email is not an alias to another user and can be used.  Based upon that response we either return an error or perform the user.SignUp.  This seems to work well and is a good workaround till they fix the SDK

- Make SignUp buttons pick up color from cognito sync

- AWSGoogleSignInProvider crashes on startup sometime, I think it is related to trying to start up when it's token is expired or something, because the crash is only occassional, but when it does crash.. it keeps crashing.  Investigate.

- As a fix to AWSGoogleSignInProvider crashes, and really ANY AWSSignInProvider crash, what I did is to set a NSUserDefaults flag (ProvidersOk) that get set to no when starting and gets set to YES when the AWSSignInProviders all complete initialization. If upon starting up the ProviderOk flag is NO, then it drops all the provider keys and clears the keychain.  That way it at least the providers get a clean slate (though you do have to log in again).

- Need to make Username get carried around the various Signin Screens
    Done... but it carries usernames from one IdP to the next, so it needs improvement to only carry cognito (your) user pools names around.

- Need to make delegate based authentication work.  I think this may present problems in the context of mobilehubhelper, but maybe not.  


