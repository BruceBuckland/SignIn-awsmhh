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
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var forgotPasswordButton: FieldSensitiveUIButton!
    //MARK: Global Variables for Changing Image Functionality.
    var backgroundImageCycler: BackgroundImageCycle?
    
    
    
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        if backgroundImageCycler == nil {
            backgroundImageCycler = BackgroundImageCycle(self.imageView, speed: 10 )
        }
        backgroundImageCycler?.start()

        // set colors for fields and buttons
        AppColor.colorizeField(usernameField)
        
        forgotPasswordButton.colorize(enabledBackgroundColor:AppColor.defaultColor)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        forgotPasswordButton.requiredFields(usernameField)
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")

        
        if let username = usernameText {
            usernameField.text = username
            if usernameField.text != "" {
                forgotPasswordButton.enable() // he doesn't have to click
            }
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
    
    func colorInterface(defaultColor: UIColor) {
        
        usernameField.textColor = defaultColor.lighter(0.75)
        usernameField.tintColor = defaultColor
        
        forgotPasswordButton.colorize(enabledBackgroundAlpha: 0.8, disabledBackgroundAlpha: 0.28, enabledBackgroundColor:defaultColor , disabledBackgroundColor: UIColor.whiteColor(), enabledTitleAlpha: 0.8, disabledTitleAlpha: 0.5, enabledTitleColor: UIColor.whiteColor(), disabledTitleColor: UIColor.whiteColor())
        
        
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
