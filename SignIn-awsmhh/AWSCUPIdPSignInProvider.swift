//
//  AWSCUPIdPSignInProvider.swift
//
//  Created by Bruce Buckland on 9/20/16.
//
//
// the name is intended to help differentiate between cognito
// identity pools and user pools.  Cognito User Pools (CUP)
// Identity Provider (IdP).
//


import Foundation
import AWSCognitoIdentityProvider // needed for user pools
import AWSMobileHubHelper

// AWSIdentityProvider intercept... uses NSClassFromString on our Class name
@objc(AWSCUPIdPSignInProvider)


class AWSCUPIdPSignInProvider: NSObject, AWSSignInProvider {
    
    static let sharedInstance = AWSCUPIdPSignInProvider() // create a singleton
    
    
    // Carry serviceConfiguration
    private var serviceConfiguration: AWSServiceConfiguration?
    
    
    // Info.plist must contain (in addition to the mobile-hub-helper items)
    // AWS->IdentityManager->Default->SignInProviderClass dictionary
    // which contains the NSUserDefaults key that indicates an ongoing session
    // and the class name of the SignInProvider
    // "Google":"AWSGoogleSignInProvider"
    // "Facebook":"AWSFacebookSignInProvider"
    // "CognitoYourUserPools":"AWSCUPIdPSignInProvider"
    // and so on listing all of the possible sign in providers
    
    let AWSCUPIdPSignInProviderKey = "CognitoYourUserPools"
    let AWSInfoIdentityManager = "IdentityManager"
    let AWSInfoCUPIdPIdentifier = "CognitoYourUserPools"
    let ServiceConfigurationKeyForUserPool = "UserPool"
    let COGNITO_USER_POOL_ID = "COGNITO_USER_POOL_ID"
    let COGNITO_USER_POOL_APP_CLIENT_ID = "COGNITO_USER_POOL_APP_CLIENT_ID"
    let COGNITO_USER_POOL_APP_CLIENT_SECRET = "COGNITO_USER_POOL_APP_CLIENT_SECRET"
    let COGNITO_REGIONTYPE = "COGNITO_REGIONTYPE"
    
    // the service name in "logins" must be unique, and (it is documented that) you can't change it once you use it with a Federated Pool
    // But I need a name to use for error messages (Incorrect UserId password)
    // And the tokens are specific to the userpoolname, so I need COGNITO_USER_POOL_NAME
    
    let COGNITO_USER_POOL_IDP_NAME = "COGNITO_USER_POOL_IDP_NAME"
    let COGNITO_USER_POOL_NAME = "COGNITO_USER_POOL_NAME"
    
    
    var identityProviderFriendlyName:String  { // name for display
        return getUserPoolName(COGNITO_USER_POOL_NAME)
    }
    
    var identityProviderName:String  { // name for logins
        return getUserPoolName(COGNITO_USER_POOL_IDP_NAME)
    }
    
    func getUserPoolName(forKey: String) -> String {
        
        let defaultDictionary = AWSInfo().defaultServiceInfo(AWSInfoIdentityManager)?.infoDictionary
        if let serviceKeys = defaultDictionary?[AWSInfoCUPIdPIdentifier] as? NSDictionary {
        
        let serviceName = serviceKeys[forKey] as! String  // use nice name
            return serviceName
        } else {
            print("Info.plist configuration missing for \(AWSInfoCUPIdPIdentifier) or \(COGNITO_USER_POOL_IDP_NAME)")
        }
        return "userPool/NotConfiguredInInfo.plist" }
    
    
    
    
    
    
    // pragma mark - Properties
    
    // pool and user are read only properties - an enhancement allowing this
    // SignInProvider to provide the pool for non-login tasks like updating
    // password, attributes, signing up, creating ids etc.
    var pool: AWSCognitoIdentityUserPool { return userPool! }
    private var userPool: AWSCognitoIdentityUserPool?
    
    var user: AWSCognitoIdentityUser { return userPoolUser! }
    private var userPoolUser: AWSCognitoIdentityUser?

    // pragma mark - AWSIdentityProvider
    private var _loggedIn: Bool = false
    
    var loggedIn: Bool {
        @objc(isLoggedIn)
        get {
            return self._loggedIn
        }
        set {
            self._loggedIn = newValue
        }
    }
    
    var userName:String?
    var imageURL:NSURL?
    
    // pragma mark - methods
    
    // we must call AWSIdentityManager's completeLogin method to get
    // the state signalling for SignIn and SignOut and also to get
    // credentials
    
    func completeLogin() {
        NSUserDefaults.standardUserDefaults().setObject("YES", forKey: self.AWSCUPIdPSignInProviderKey)

        self.imageURL = NSURL(string: "https://admin.mashable.com/wp-content/uploads/2011/09/not-google-plus.jpg") // temporary place holder - should load user image
        self.userName = self.userPoolUser!.username

        self.loggedIn = true
        
        AWSIdentityManager.defaultIdentityManager().completeLogin()
    }
    
    // using NSUserDefaults the SignInProvider keeps current logged in state even when device is shut down.
    
    func reloadSession()  {
        if NSUserDefaults.standardUserDefaults().stringForKey(AWSCUPIdPSignInProviderKey) == "YES" {
            
            print("Reloading session:......................................................")
            
            configureIdentityManager()  // init pool and current user
            self.userPoolUser?.getSession().continueWithBlock { (task) in
                
                if task.error != nil {  // some sort of error
                    print("Error:\(task.error)")
                } else {

                    let response = task.result as! AWSCognitoIdentityUserSession
                    
                    print("\n\n\ngetSession idToken:\n\(response.idToken)")
                    print("\n\n\ngetSession Access Token:\n\(response.accessToken )")
                    print("\n\n\ngetSession expirationTime:\n\(response.expirationTime)")
                    
                    self.completeLogin()
                    
                    // AWSIdentityManager.defaultIdentityManager().completeLogin() calls the
                    // completionHandler( task.result!, nil )
                    
                }
                
                return nil
            }
        }
        
        
    }
    //    func completeLogin()  {
    //
    //    }
    
    typealias AWSIdentityManagerCompletionBlock = (AnyObject?,NSError?) -> Void
    
    // not a great way to do it, but for demonstration
    // these are the parameters for login
    
    var customUserIdField:String? = ""
    var customPasswordField:String? = ""
    
    func login(completionHandler: AWSIdentityManagerCompletionBlock )
        -> Void  {
            
            configureIdentityManager()
            
            if (customUserIdField != nil) && (customUserIdField != "") && (customPasswordField != nil)  && (customPasswordField != "")  {
                self.userPoolUser = userPool!.getUser(customUserIdField!)
                self.userPoolUser?.getSession(customUserIdField!, password: customPasswordField!, validationData: nil).continueWithBlock { (task) in
                    
                    if task.error != nil {  // some sort of error
                        completionHandler(nil,task.error!)  // this may not be right..
                    } else {
                        
                        let response = task.result as! AWSCognitoIdentityUserSession
                        
                        print("\n\n\nAuthentication idToken:\n\(response.idToken)")
                        print("\n\n\nAuthentication Access Token:\n\(response.accessToken )")
                        print("\n\n\nAuthentication expirationTime:\n\(response.expirationTime)")
                        
                        self.completeLogin()
                        
                    }
                    
                    return nil
                }
                
            } else {
                // email or password not set - no feedback to user
                print("Login Called without Username and Password set")
                
            }
    }
    
    func logout() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AWSCUPIdPSignInProviderKey)
        self.loggedIn = false
        
    }
    
    
    func token() -> AWSTask {
        return (userPool?.token())!
    }
    
    
    
    

    
    func configureIdentityManager() {
        
        if self.userPool != nil { // Cognito Your User Pools is already initialized
            return
        }
        
        // AWSInfo lets us get configuration data from the AWS section of Info.plist
        // serviceInfo gets a dictionary for a key within a key under AWS
        // IdentityManager - dict
        //      CognitoYourUserPools - dict
        // defaultServiceInfo gets a key within the default section of a key under aws
        // IdentityManager - dict
        //      Default
        //          CognitoYourUserPools - dict
        // So we try to conform to the AWS way of doing it, although it is none too clear
        // what "Default" means, so we let our
        
        let defaultDictionary = AWSInfo().defaultServiceInfo(AWSInfoIdentityManager)?.infoDictionary
        if let keyDictionary = defaultDictionary?[AWSInfoCUPIdPIdentifier] as? NSDictionary {
            let userPoolId = keyDictionary[COGNITO_USER_POOL_ID] as? String
            let userPoolAppClientId = keyDictionary[COGNITO_USER_POOL_APP_CLIENT_ID] as? String
            let userPoolAppClientSecret = keyDictionary[COGNITO_USER_POOL_APP_CLIENT_SECRET] as? String
            let cognitoRegionType = keyDictionary[COGNITO_REGIONTYPE] as? String
            
            // get a service configuration
            
            serviceConfiguration = AWSServiceConfiguration(region: cognitoRegionType!.aws_regionTypeValue(), credentialsProvider:nil)
            
            // now create a user pool configuration with our keys and ids
            
            let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: userPoolAppClientId!, clientSecret: userPoolAppClientSecret, poolId: userPoolId!)
            
            // now we register that pool with the service configuration which will allow us
            // to use the pool
            
            AWSCognitoIdentityUserPool.registerCognitoIdentityUserPoolWithConfiguration(serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: ServiceConfigurationKeyForUserPool)
            
            // and this gets a working pool.
            
            self.userPool = AWSCognitoIdentityUserPool(forKey: ServiceConfigurationKeyForUserPool)
            
            
            self.userPoolUser = self.pool.currentUser() // if I have a current user this is it
            
            
            
            // AWSIdentityManager initializes and manages the Cognito Federated Identity pool and the Credentials
            // provider (which are one in the same).  So we don't need a credentialsProvider here, all we need to do is
            // serve AWSIdentityManager via the token and identityProviderName methods to get credentials
        } else {
            print("Info.plist not configured with \(AWSInfoCUPIdPIdentifier)")
        }
        
        
    }
    
    func interceptApplication(application: UIApplication, didFinishLaunchingWithOptions: [NSObject:AnyObject]?) -> Bool {
        
        configureIdentityManager()
        return true
    }
    
    func interceptApplication(application: UIApplication, openURL: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        // this doesn't happen for us (meaningfully).
        return true
    }
}



