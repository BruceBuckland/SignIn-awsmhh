//
//  SignupViewController.swift
//  signin
//
//  Created by Bruce Buckland on 7/13/16.
//  Copyright © 2016 Bruce Buckland. 
//  Permission is hereby granted, free of charge, to any person obtaining a 
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in 
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

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
    
    override func viewWillAppear(_ animated: Bool) {
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
        
        let customSignInProvider = AWSCUPIdPSignInProvider.sharedInstance
        customSignInProvider.configureIdentityManager()
        self.pool = customSignInProvider.pool
        
        // don't require the phoneField, you can if you want of course.
        
        signupButton.requiredFields(usernameField,passwordField,emailField)
     
        if let username = usernameText {
            usernameField.text = username
        }

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



 

    //call the following function to sign up
    
    @IBAction func signupPressed(_ sender: AnyObject) {
        var attributes = [AWSCognitoIdentityUserAttributeType]()
        let phone = AWSCognitoIdentityUserAttributeType()
        
        // Attribute names for users seem to be from the Open ID Standard Claims list
        // http://openid.net/specs/openid-connect-core-1_0.html#StandardClaims
        // I have not found any other documentation of the AWS user attributes
        
        phone?.name = "phone_number"
        
        //requires country code.  Some better processing needed here to help 
        // for instance if it doesn't start with a + we should insert one
        // must be some nice library for that.
        
        phone?.value = phoneField.text

        let email = AWSCognitoIdentityUserAttributeType()
        email?.name = "email"
        email?.value = emailField.text
        
        if email?.value != ""{
            attributes.append(email!)
        }
        if phone?.value != ""{
            attributes.append(phone!)
        }
        
        self.pool!.signUp(usernameField.text!, password: passwordField.text!, userAttributes: attributes, validationData: nil).continue({ (task) in
            // needs to be async so we can ALWAYS return nil for AWSTask
            DispatchQueue.main.async {
                
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: (task.error as? NSError)?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    NSLog("\(task.error)")
                }
                else {
                    let response: AWSCognitoIdentityUserPoolSignUpResponse = task.result!

                    self.user = response.user
                    
                    if (response.userConfirmed?.intValue != AWSCognitoIdentityUserStatus.confirmed.rawValue) { // not confirmed
                        
                        // setup to send sentTo thru segue
                        self.sentTo = response.codeDeliveryDetails?.destination
                        self.performSegue(withIdentifier: "confirmSignup", sender: sender)
                    } else { // user is confirmed - can it happen?
                        _ = self.navigationController?.popToRootViewController(animated: true) // back to login
                    }
                }
            }
            return nil
        })
    }

    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "confirmSignup" {
            let confirmViewController = segue.destination as! ConfirmSignupViewController
            confirmViewController.sentTo = self.sentTo
            confirmViewController.user = self.pool?.getUser(self.usernameField.text!)  // why not just use self.user?
        }
    }
    
    
    
}
