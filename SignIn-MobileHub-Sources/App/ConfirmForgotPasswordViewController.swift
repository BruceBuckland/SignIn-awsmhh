//
//  ConfirmForgotPasswordViewController.swift
//  signin
//
//  Created by Bruce Buckland on 7/23/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider


class ConfirmForgotPasswordViewController: UIViewController {
    
    // properties
    var user: AWSCognitoIdentityUser?
    
    @IBOutlet weak var confirmationCodeField: UITextField!
    @IBOutlet weak var newPasswordField: UITextField!
    @IBOutlet weak var updatePasswordButton: FieldSensitiveUIButton!
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        updatePasswordButton.updateTheme()
        updatePasswordButton.disable()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePasswordButton.updateTheme()
        // Do any additional setup after loading the view.
        updatePasswordButton.requiredFields(confirmationCodeField,newPasswordField)
    }
    
    
    @IBAction func updatePasswordPressed(sender: AnyObject) {
        self.user?.confirmForgotPassword(self.confirmationCodeField.text!, password: self.newPasswordField.text!).continueWithBlock{ (task) in
            
            dispatch_async(dispatch_get_main_queue()) {
                
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: task.error?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    NSLog("Domain: " + (task.error?.domain)! + " Code: \(task.error?.code)")
                    NSLog(task.error?.userInfo["message"] as! String)
                    
                    
                }
                else {
                    self.navigationController?.popToRootViewControllerAnimated(true)
                    
                }
            }
            return nil
        }
        
    }
}
