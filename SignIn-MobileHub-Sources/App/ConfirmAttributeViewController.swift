//
//  ConfirmAttributeViewController.swift
//  signin
//
//  Created by Bruce Buckland on 8/28/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider

class ConfirmAttributeViewController: UIViewController {

    // properties
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    var sentTo: String?
    var confirmedAttribute: String?
    
    // Outlets
    
    @IBOutlet weak var confirmButton: FieldSensitiveUIButton!
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var confirmationCodeField: UITextField!
    
    @IBOutlet weak var codeSentToLabel: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        confirmButton.updateTheme()
        confirmButton.disable()
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        
        // setup outlets
        usernameField.text = user?.username
        codeSentToLabel.text! += sentTo! // append destination to Label
        confirmButton.updateTheme()
        confirmButton.requiredFields(usernameField,confirmationCodeField)
        confirmButton.disable()
        
    }
    
    
    
    @IBAction func confirmPressed(sender: AnyObject) {
        self.user?.verifyAttribute(self.confirmedAttribute!, code: self.confirmationCodeField.text!).continueWithBlock{ (task) in
            // needs to be async so we can ALWAYS return nil for AWSTask
            dispatch_async(dispatch_get_main_queue()) {
                
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: task.error?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    NSLog("Domain: " + (task.error?.domain)! + " Code: \(task.error?.code)")
                    NSLog(task.error?.userInfo["message"] as! String)
                    
                    
                } else { // confirmed back to login
                    
                    self.navigationController!.popToRootViewControllerAnimated(true)
                    
                }
            }
            return nil
        }
    }
    
    @IBAction func resendConfirmationCodePressed(sender: AnyObject) {
        self.user?.getAttributeVerificationCode(self.confirmedAttribute!).continueWithBlock{ (task) in
            // needs to be async so we can ALWAYS return nil for AWSTask
            dispatch_async(dispatch_get_main_queue()) {
                
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: task.error?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    NSLog("Domain: " + (task.error?.domain)! + " Code: \(task.error?.code)")
                    NSLog(task.error?.userInfo["message"] as! String)
                    
                    
                } else { // resend successful
                    let response = task.result as! AWSCognitoIdentityUserGetAttributeVerificationCodeResponse
                    
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

