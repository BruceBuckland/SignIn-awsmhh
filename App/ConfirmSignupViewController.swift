//
//  ConfirmSignupViewController.swift
//  signin
//
//  Created by Bruce Buckland on 7/23/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider

class ConfirmSignupViewController: UIViewController {
    
    // properties
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    var sentTo: String?
    
    // Outlets
    
    @IBOutlet weak var confirmButton: FieldSensitiveUIButton!
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var confirmationCodeField: UITextField!
    
    @IBOutlet weak var codeSentToLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        
        // setup outlets
        usernameField.text = user?.username
        codeSentToLabel.text! += sentTo! // append destination to Label
        
        confirmButton.requiredFields(usernameField,confirmationCodeField)
        confirmButton.disable()
    }
    
    @IBAction func confirmPressed(sender: AnyObject) {
        self.user?.confirmSignUp(confirmationCodeField.text!).continueWithBlock{ (task) in
            // needs to be async so we can ALWAYS return nil for AWSTask
            dispatch_async(dispatch_get_main_queue()) {
                
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: task.error?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    NSLog("Domain: " + (task.error?.domain)! + " Code: \(task.error?.code)")
                    NSLog(task.error?.userInfo["message"] as! String)
                    
                    
                } else { // confirmed back to login
                    // this viewcontroller makes the assumption that
                    // it is called in a navigation controller (ugh)
                    self.navigationController!.popToRootViewControllerAnimated(true)
                }
            }
            return nil
        }
    }
    
    @IBAction func resendConfirmationCodePressed(sender: AnyObject) {
        self.user?.resendConfirmationCode().continueWithBlock{ (task) in
            // needs to be async so we can ALWAYS return nil for AWSTask
            dispatch_async(dispatch_get_main_queue()) {
                
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: task.error?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    NSLog("Domain: " + (task.error?.domain)! + " Code: \(task.error?.code)")
                    NSLog(task.error?.userInfo["message"] as! String)
                    
                    
                } else { // resend successful
                    let response: AWSCognitoIdentityUserResendConfirmationCodeResponse = task.result as! AWSCognitoIdentityUserResendConfirmationCodeResponse
                    
                    let resentTo = response.codeDeliveryDetails?.destination
                    let alert = UIAlertController(title: "Code Resent", message:  "Code resent to: \(resentTo)", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
            return nil
        }
    }
}
