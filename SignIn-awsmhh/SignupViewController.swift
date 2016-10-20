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
    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var signupButton: FieldSensitiveUIButton!

    //MARK: Global Variables for Changing Image Functionality.
    var backgroundImageCycler: BackgroundImageCycle?
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        if backgroundImageCycler == nil {
            backgroundImageCycler = BackgroundImageCycle(self.imageView, speed: 8)
        }
        backgroundImageCycler?.start()

        // set colors for fields and buttons
        AppColor.colorizeField(passwordField,usernameField,emailField,phoneField)
        
        signupButton.colorize(enabledBackgroundColor:AppColor.defaultColor)
        
        signupButton.disable()
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        
        // don't require the phoneField, you can if you want of course.
        
        signupButton.requiredFields(usernameField,passwordField,emailField)
     
        if let username = usernameText {
            usernameField.text = username
        }

    }
    
    
    
    
    override func viewWillDisappear(animated: Bool) {
        backgroundImageCycler?.stop()
        backgroundImageCycler = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if backgroundImageCycler != nil {
            backgroundImageCycler?.stop()
            backgroundImageCycler = nil  // frees the image array
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
        
        self.pool!.signUp(usernameField.text!, password: passwordField.text!, userAttributes: attributes, validationData: nil).continueWithBlock{ (task) in
            // needs to be async so we can ALWAYS return nil for AWSTask
            dispatch_async(dispatch_get_main_queue()) {
                
                if task.error != nil {  // some sort of error
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
                        self.performSegueWithIdentifier("confirmSignup", sender: sender)
                    } else { // user is confirmed - can it happen?
                        self.navigationController?.popToRootViewControllerAnimated(true) // back to login
                    }
                }
            }
            return nil
        }
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
