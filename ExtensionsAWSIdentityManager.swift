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
let KeyForProviderDictionary = "Providers"

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
    
    // Track usernames against IdentityIds the username and provider in a dictionary
    // We only sync if the username is not yet recorded on this device
    // There is a Dataset record called "Providers" in the dataset containing a Dictionary
    // provider name is the key, username is the value
    //
    func getIdentitiesForIdentityId() -> NSDictionary? {
        let syncClient: AWSCognito = AWSCognito.defaultCognito()
        let adminState: AWSCognitoDataset = syncClient.openOrCreateDataset(DatasetForUsernameState)
        // get JSON data from our key
        if let jsonData = adminState.stringForKey(KeyForProviderDictionary)?.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let providerDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as! [String:AnyObject]
                // successful conversion from JSON
                return providerDict
                
            } catch let error as NSError {
                print("JSON error: \(error.localizedDescription)")
            }
        }
        return nil
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
        let usernameState: AWSCognitoDataset = syncClient.openOrCreateDataset(DatasetForUsernameState)
        var providerDict:NSDictionary?
        
        func syncDict(providerDictionary: NSDictionary?) {
            do {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(providerDictionary!, options: NSJSONWritingOptions.PrettyPrinted)
                usernameState.setString(String(data: jsonData, encoding: NSUTF8StringEncoding), forKey: KeyForProviderDictionary)
                // sync
                NSLog("Synchronize occured")
                usernameState.synchronize().continueWithExceptionCheckingBlock({(result: AnyObject?, error: NSError?) -> Void in
                    if let error = error {
                        print("AWS task error saving username for identityId: \(error.localizedDescription)")
                    }
                })
            } catch let error as NSError {
                print("JSON error: \(error.localizedDescription)")
            }
        }
        
        if let jsonData = usernameState.stringForKey(KeyForProviderDictionary)?.dataUsingEncoding(NSUTF8StringEncoding) { // Got a Dataset record
            do {
                let providerDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as! NSMutableDictionary
                
                if providerDict[provider] as? String == username { // have dict have username
                    return
                } else { // need to sync new username
                    providerDict.setValue(username, forKey: provider)
                    syncDict(providerDict)
                }
                
            } catch let error as NSError {
                print("JSON error: \(error.localizedDescription)")
                providerDict = [provider:username]
                syncDict(providerDict)
            }
        } else { // There is no Dataset Record
            providerDict = [provider:username]
            syncDict(providerDict)
        }
        
        
    }
}
