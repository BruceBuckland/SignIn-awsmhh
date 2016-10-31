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
    
    //MARK: Global Variables for Changing Image Functionality.
    var backgroundImageCycler: BackgroundImageCycle?
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var confirmationCodeField: UITextField!
    @IBOutlet weak var newPasswordField: UITextField!
    @IBOutlet weak var updatePasswordButton: FieldSensitiveUIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        if backgroundImageCycler == nil {
            backgroundImageCycler = BackgroundImageCycle(self.imageView, speed: 10 )
        }
        backgroundImageCycler?.start()
        
        AppColor.colorizeField(confirmationCodeField,newPasswordField)
        updatePasswordButton.colorize(enabledBackgroundColor: AppColor.defaultColor)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        updatePasswordButton.requiredFields(confirmationCodeField,newPasswordField)
    }
    
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
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
    
    
    @IBAction func updatePasswordPressed(_ sender: AnyObject) {
        self.user?.confirmForgotPassword(self.confirmationCodeField.text!, password: self.newPasswordField.text!).continue({ (task) in
            
            DispatchQueue.main.async {
                
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: (task.error as? NSError)?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    NSLog("\(task.error)")
                }
                else {
                    let _ = self.navigationController?.popToRootViewController(animated: true)
                    
                }
            }
            return nil
        })
        
    }
}
