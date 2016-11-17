//
//  SignupViewController.swift
//  signin
//
//  Created by Bruce Buckland on 7/13/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider

class SignupViewController: UIViewController {
    
    // Properties
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    var sentTo: String?
    var usernameText: String? // prefilled from previous ViewController
    
    // Outlets
    
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var phoneField: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var signupButton: FieldSensitiveUIButton!
    
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        signupButton.disable()
        usernameField.text = usernameText
        signupButton.updateTheme()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        let customSignInProvider = AWSCUPIdPSignInProvider.sharedInstance
        customSignInProvider.configureIdentityManager()
        self.pool = customSignInProvider.pool

        signupButton.updateTheme()
        // don't require the phoneField, you can if you want of course.
        signupButton.requiredFields(usernameField,passwordField,emailField)
        
        if let username = usernameText {
            usernameField.text = username
        }
        
    }
    
    
    //call the following function to sign up
    
    @IBAction func signupPressed(sender: AnyObject) {
        var attributes = [AWSCognitoIdentityUserAttributeType]()
        let phone = AWSCognitoIdentityUserAttributeType()
        
        // Attribute names for users seem to be from the Open ID Standard Claims list
        // http://openid.net/specs/openid-connect-core-1_0.html#StandardClaims
        // I have not found any other documentation of the AWS user attributes
        
        phone.name = "phone_number"
        
        //requires country code.  Some better processing needed here to help
        // for instance if it doesn't start with a + we should insert one
        // must be some nice library for that.
        
        phone.value = phoneField.text
        
        let email = AWSCognitoIdentityUserAttributeType()
        email.name = "email"
        email.value = emailField.text
        
        if email.value != ""{
            attributes.append(email)
        }
        if phone.value != ""{
            attributes.append(phone)
        }
        
        signupWithUniqueEmail(emailField.text!, username: self.usernameField.text!, password: self.passwordField.text!, userAttributes: attributes)
    }
    // This task returns either a task that returns signup request or a task that returns an error that the email is in use.
    // In cases where we have declared email an alias, the email address should get user not found if we want to signup with
    // it.  If it is NOT an alias in the pool, this is a wasted call BUT should work because it would only reject usernames that are
    // email addresses and already in use, which is ok (I don't think email addresses are legal usernames, so that's ok).
    func signupWithUniqueEmail(email: String, username: String, password: String, userAttributes: [AWSCognitoIdentityUserAttributeType]?)  {
        self.user = self.pool!.getUser(emailField.text!)
        self.user?.getSession(email, password: "93490349 this should always be the wrong password 283749823", validationData: nil).continueWithBlock({ (task) -> AWSTask? in
            // needs to be async so we can ALWAYS return nil for AWSTask
            
            
            if task.error == nil  {
                NSLog("How did you guess that password, and why?")
                return nil
            } else {  // we should either get wrong password or user not exist
                if let rejectType = task.error?.code  {
                    
                    switch rejectType {
                    case AWSCognitoIdentityProviderErrorType.NotAuthorized.rawValue:
                        
                        // If it is not authorized, then the email exists as an alias to another user
                        return AWSTask(error: NSError(domain: AWSCognitoIdentityProviderErrorDomain, code: AWSCognitoIdentityProviderErrorType.UsernameExists.rawValue, userInfo: ["message":"Email already in use by a user"]))
                        
                    case AWSCognitoIdentityProviderErrorType.UserNotFound.rawValue:
                        
                        // If it is not found, then the email is not an alias to another user and can be used
                        return self.pool!.signUp(self.usernameField.text!, password: self.passwordField.text!, userAttributes: userAttributes, validationData: nil)
                        
                    default:
                        
                        // Other errors - we will have to see
                        NSLog("When checking if email was unique encountered unexpected error type: \(rejectType) expected NotAuthorized or UserNotFound - debug - continuing")
                        return self.pool!.signUp(self.usernameField.text!, password: self.passwordField.text!, userAttributes: userAttributes, validationData: nil)
                    }
                }
            }
            return nil
        }).continueWithBlock({ (task) in
            
            dispatch_async(dispatch_get_main_queue()) {
                
                if task.error != nil {  // some sort of error
                    let myerror = task.error
                    NSLog("\(myerror)")
                    
                    let alert = UIAlertController(title: "", message: task.error?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    NSLog("Domain: " + (task.error?.domain)! + " Code: \(task.error?.code)")
                    NSLog(task.error?.userInfo["message"] as! String)
                    
                    
                }
                else {
                    let response: AWSCognitoIdentityUserPoolSignUpResponse = task.result as! AWSCognitoIdentityUserPoolSignUpResponse
                    // NSLog("AWSCognitoIdentityUserPoolSignUpResponse: \(response)")
                    self.user = response.user
                    
                    if (response.userConfirmed != AWSCognitoIdentityUserStatus.Confirmed.rawValue) { // not confirmed
                        
                        // setup to send sentTo thru segue
                        self.sentTo = response.codeDeliveryDetails?.destination
                        self.performSegueWithIdentifier("confirmSignup", sender: self)
                    } else { // user is confirmed - can it happen?
                        self.navigationController?.popToRootViewControllerAnimated(true) // back to login
                    }
                }
            }
            return nil
        })
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "confirmSignup" {
            let confirmViewController = segue.destinationViewController as! ConfirmSignupViewController
            confirmViewController.sentTo = self.sentTo
            confirmViewController.user = self.pool?.getUser(self.usernameField.text!)  // why not just use self.user?
        }
    }
    

}
