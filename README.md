# Signin 
##### Overview
Signin is an example of an AWS User Pools authentication for IOS written in Swift. 
- MFA (multi-factor authentication) is not implemented.
- updating attributes is implemented
- Signup is implemented
- Google login is implemented
- user Pool login is implemented
- facebook login is implemented
- Forgot password is implemented
- While some functions (signup and forgot password) require a verification code, it you leave the app there needs to be a way to enter that code, and that is NOT implemented.

##### Background
The initial signin app was built using aws-ios-sdk but this one uses the far superior mobile-hub-helper framework. 

##### What the App does
The app has a logged in and a not logged in state.  Both should be allowed (in your cognito console federated identity choose -allow unauthenticated identities)

##### Building Signin
- Install cocoapods
- Install the AWS IOS SDK (Tested with version 2.4.9 or greater).
- Use AWS account and create a User Pool in the Cognito console.
    -   Make sure you make a User Pool not a Federated Identities Pool
    -   Configure your User Pool with email as a required field (aka Attribute) and no other required fields. If you want phone number to be required, or want more fields then you would need to change the SignupViewController.swift to require the required ones, and allow input of all attributes.  As delivered Signin requires only Username, Password (which are required by default) and Email Address (A real email is needed to get the Confirmation Number).
    -   On the Pool Details page take note of your Pool Name and your Pool ID
    -   On the same page add an app to your User Pool. Specify the same name you intend to use for your app name. I used "signin". Click on Show Details and take note of the App Client Id, and the App Client Secret.  Click Save Changes.
    -   Take a look at the Policies section of the Pool Details page to see what password requirements you want to implement.  I unchecked "Require special characters" and required a minimum length of only 6.  If you use something other than that edit the storyboard text for the signup view controller to say that they are required.  
- Use AWS account and create a Federated identity pool in the Cognito console.
- Create a new file in Xcode File > New > File... > IOS > Other > Configuration Settings File.  Name the file AWSKeys.xcconfig (because that is the filename ignored in the .gitignore).  In that file put the following:

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

