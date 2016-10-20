# Signin 
##### Overview
Signin is an example of an AWS User Pools authentication for IOS written in Swift. 
- "Cognito Your User Pools" login is implemented
- Facebook and Google+ login is implemented
- Signup, Forgot Password and Update Attributes are implemented
- While some functions require entry of a verification code and that is implemented, if you terminate the app there needs to be a way to enter that code, and that is NOT implemented.
- MFA (multi-factor authentication) is not implemented.


##### Background
The initial signin app (a different repo) was built using aws-ios-sdk but this one uses the far superior mobile-hub-helper framework. 

##### What the App does
The app is written in Swift using AWS Mobile Hub Helper and AWS Mobile Client (from the AWS Mobile Hub). The app has a logged in and a not logged in state.  Both should be allowed (in your cognito console federated identity choose -allow unauthenticated identities). The app will allow login using Facebook, Google and a custom User Pool that you create in Cognito User Pools. You can switch between identities but the app does not (yet) let you link identities (because MHH's AWSIdentityManager does not yet support that.).  The app supports the latest AWS IOS SDK and currently is written in Swift 2

##### Building SignIn-awsmhh
- Clone or download the repository
- Install cocoapods
- Install the AWS IOS SDK (Tested with version 2.4.9 or greater).
- Use AWS account and create a User Pool in the Cognito console.
    -   Make sure you make a User Pool not a Federated Identities Pool
    -   Configure your User Pool with email as a required field (aka Attribute) and no other required fields. If you want phone number to be required, or want more fields then you would need to change the SignupViewController.swift to require the required ones, and allow input of all attributes.  As delivered Signin requires only Username, Password (which are required by default) and Email Address (A real email is needed to get the Confirmation Number).
    -   On the Pool Details page take note of your Pool Name and your Pool ID
    -   On the same page add an app to your User Pool. Specify the same name you intend to use for your app name. I used "signin". Click on Show Details and take note of the App Client Id, and the App Client Secret.  Click Save Changes.
    -   Take a look at the Policies section of the Pool Details page to see what password requirements you want to implement.  I unchecked "Require special characters" and required a minimum length of only 6.  If you use something other than that edit the storyboard text for the signup view controller to say that they are required.  
- Use AWS account and create a Federated identity pool in the Cognito console.
- Clone the mobile-hub-helper fork at https://github.com/BruceBuckland/aws-mobilehub-helper-ios which has 2 small fixes in it to make it handle User Pools
- cd top level directory aws-mobile-hub-helper
- pod install
- Scripts/GenerateHelperFramework.sh (This puts a builtFramework directory at top level)
- In xcode open SignIn-awsmhh remove the AWSMobileHubHelper.framework from that app and add the file aws-mobilehub-helper-ios/builtFramework/framework/AWSMobileHubHelper.framework to your app.

- The easiest way to do this next step may be to use AWS Mobile Hub to create configure and download an app using your google and facebook keys, and then copy the data you need from the Info.plist in that downloaded app. 
Create a new file in Xcode File > New > File... > IOS > Other > Configuration Settings File.  Name the file AWSKeys.xcconfig (because that is the filename ignored in the .gitignore).  In that file put the following:

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

- Build and Run (Tested on a iPhone6 format machine)

- You will need to specify your AWSKeys.xcconfig as a Configuration for (Debug and Release) in your project settings -> Select Project -> Select Info -> Select Configurations -> Select the AWSKeys file in both  Debug and Release. 
- If you change the configuration of these settings you must do a Product -> Clean (which gets rid of the preconfigured info.plist I think, so the settings can find thier way to K. struct in ConstantsK.swift
- This app uses an AWSSignInProvider class called AWSCUPIdPSignInProvider that allows authentication using Cognito Your User Pools. If you want to write your own AWSSignInProvider for another IdentityProvider this class provides a model


