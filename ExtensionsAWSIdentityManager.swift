//
//  ExtensionsAWSIdentityManager.swift
//  SignIn-awsmhh
//
//  Created by Bruce Buckland on 11/15/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import Foundation
import AWSCognito


let DatasetForUsernameState = "IdPUsers_State"

extension AWSIdentityManager {
    /**
     * The providerKey is a user readable name of the signInProvider passed as an such
     * as Facebook or Google or whatever you choose for your developer identity provider
     * or cognito user pools. The name is used as the key for the NSUserDefaults Active
     * Session indicator. This value is needed for user feedback (for instance a Cognito login
     * error can say "Failed to login to Cognito Pool" instead of "Failed to login
     * to cognito-idp.us-east-1_KRlVhYCpHqM", which is much less user friendly.
     * Keys are used as user friendly name AND to maintain active sessions.
     * The keys are established using Info.Plist under
     * AWS->IdentityManager->Default->SignInProviderKeyDictionary
     * @return provider name or nil (nil if classname not found)
     */
    class func providerKey(provider: AWSSignInProvider) -> String {
        let AWSInfoIdentityManager = "IdentityManager"
        let defaultDictionary = AWSInfo().defaultServiceInfo(AWSInfoIdentityManager)?.infoDictionary
        let signInProviderKeyDictionary = defaultDictionary?["SignInProviderKeyDictionary"] as! NSDictionary
        if let key = signInProviderKeyDictionary[String(provider.dynamicType)] as! String? {
            return key
        } else {
            return "SignInProviderKeyDictionary is not configured properly"
        }
    }
    
    /**
     * providerList is a list of all configured AWSsignInProviders based upon Info.plist
     * or AWSSignInProviderFactory registration list.  Be careful removing IdentityProviders
     * because if you remove an identity provider and it has synced data, that synced data is there forever
     * using up space but never used.
     */
    class func providerList() -> [String] {
        let AWSInfoIdentityManager = "IdentityManager"
        let defaultDictionary = AWSInfo().defaultServiceInfo(AWSInfoIdentityManager)?.infoDictionary
        let signInProviderKeyDictionary = defaultDictionary?["SignInProviderKeyDictionary"] as! NSDictionary
        return signInProviderKeyDictionary.allValues  as! [String] //[String(provider.dynamicType)]
    }
    
    // Track usernames against IdentityIds the username and provider in a dictionary
    // We only sync if the username is not yet recorded on this device
    //
    func getIdentitiesForIdentityId() -> NSDictionary? {
        let syncClient: AWSCognito = AWSCognito.defaultCognito()
        let adminState: AWSCognitoDataset = syncClient.openOrCreateDataset(DatasetForUsernameState)
        
        var providerDict:[String:String] = [:]
        
        for provider in AWSIdentityManager.providerList() {
            providerDict[provider] = adminState.stringForKey(provider)
        }
        return providerDict
    }
    
    /**
     * log the userName and providerKey for a user in a
     * Cognito Sync dataset and synchronize.  If the
     * userName and providerKey already exists it won't
     * synchronize
     * @param username username to store
     * @param provider providerKey to store
     */
    func recordIdentityForIdentityId(username: String, provider: String) {
        let syncClient: AWSCognito = AWSCognito.defaultCognito()
        let adminState: AWSCognitoDataset = syncClient.openOrCreateDataset(DatasetForUsernameState)
        
        if let storedUserName = adminState.stringForKey(provider) { // Got a Dataset record
            if storedUserName != username {
                abort()
            } else {
                return // do nothing the username is sync'd already
            }
        } else { // There is no Dataset Record for this provider
            adminState.setString(username, forKey: provider)
            NSLog("Synchronize occured setString \(provider)=>\(username)")
            adminState.synchronize().continueWithExceptionCheckingBlock({(result: AnyObject?, error: NSError?) -> Void in
                if let error = error {
                    print("AWS task error saving username for identityId: \(error.localizedDescription)")
                }
                NSLog("Stored Identities after sync: \(self.getIdentitiesForIdentityId())")
            })
        }
    }
}
