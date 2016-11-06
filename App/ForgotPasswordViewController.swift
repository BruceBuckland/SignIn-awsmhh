//
//  ForgotPasswordViewController.swift
//  signin
//
//  Created by Bruce Buckland on 7/23/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider


class ForgotPasswordViewController: UIViewController {
    
    //properties
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    var sentTo: String?
    var usernameText: String? // prefilled from previous ViewController

    
    // outlets
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var forgotPasswordButton: FieldSensitiveUIButton!
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        usernameField.text = usernameText
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        forgotPasswordButton.requiredFields(usernameField)
        
        let customSignInProvider = AWSCUPIdPSignInProvider.sharedInstance
        customSignInProvider.configureIdentityManager()
        self.pool = customSignInProvider.pool

        
        if let username = usernameText {
            usernameField.text = username
            if usernameField.text != "" {
                forgotPasswordButton.enable() // he doesn't have to click
            }
        }
    }
    
    @IBAction func forgotPasswordPressed(sender: AnyObject) {
        
        self.user = self.pool?.getUser(usernameField.text!)
        self.user?.forgotPassword().continueWithBlock{ (task) in
            
            dispatch_async(dispatch_get_main_queue()) {
                
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: task.error?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    NSLog("Domain: " + (task.error?.domain)! + " Code: \(task.error?.code)")
                    NSLog(task.error?.userInfo["message"] as! String)
                    
                    
                }
                else {
                    self.performSegueWithIdentifier("confirmForgotPassword", sender: sender)
                }
            }
            return nil
        }
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "confirmForgotPassword" {
            // confirm is done with the same user.
            (segue.destinationViewController as! ConfirmForgotPasswordViewController).user = self.user
        }
    }
    
    
}
