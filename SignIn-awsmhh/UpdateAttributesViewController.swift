//
//  UpdateAttributesViewController.swift
//  signin
//
//  Created by Bruce Buckland on 8/21/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider


class UpdateAttributesViewController: UIViewController {
    
    // Properties
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    
    var username: String?
    var attributes: [AWSCognitoIdentityProviderAttributeType]?
    
  //  var codeDeliveryDetailsList: AWSCognitoIdentityProviderCodeDeliveryDetailsType?
    
    
    
    // Outlets
    
    @IBOutlet weak var UpdateAttributesButton: FieldSensitiveUIButton!
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    
    //MARK: Global Variables for Changing Image Functionality.
    var backgroundImageCycler: BackgroundImageCycle?
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        
        if backgroundImageCycler == nil {
            backgroundImageCycler = BackgroundImageCycle(self.imageView, speed: 8)
        }
        backgroundImageCycler?.start()
        
        // set colors for fields and buttons
        AppColor.colorizeField(usernameField,emailField,phoneField)
        UpdateAttributesButton.colorize(enabledBackgroundColor:AppColor.defaultColor)
        
        UpdateAttributesButton.disable()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        
        // don't require the phoneField, you can if you want of course.
        
        UpdateAttributesButton.requiredFields(usernameField,phoneField,emailField)
        
        usernameField.text = username
        for attribute in attributes! {
            if attribute.name! == "phone_number" {
                phoneField.text = attribute.value!
            } else if attribute.name! == "email" {
                emailField.text = attribute.value!
            }
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
    
    @IBAction func UpdateAttributesPressed(_ sender: AnyObject) {
        
        
        
        // Attribute names for users seem to be from the Open ID Standard Claims list
        // http://openid.net/specs/openid-connect-core-1_0.html#StandardClaims
        // I have not found any other documentation of the AWS user attributes
        
        self.user = self.pool?.getUser(usernameField.text!)
        
        
        // This is a terrible way to do this, we need a user attribute model class
        // make the attributes array only contain changed attributes
        var attributesToUpdate = [AWSCognitoIdentityUserAttributeType]()
        
        // is there a phone number
        
        var needAnAttribute = true
        
        for attribute in attributes! {
            
            if attribute.name! == "phone_number" {
                if attribute.value! != phoneField.text { // changed
                    needAnAttribute = false
                    let reclassedProviderAttribute = AWSCognitoIdentityUserAttributeType()
                    reclassedProviderAttribute?.name = attribute.name
                    reclassedProviderAttribute?.value = phoneField.text
                    attributesToUpdate.append(reclassedProviderAttribute!)
                    
                }
            }
        }
        
        // if we don't have a phone number attribute but the field isn't empty then
        // add the attribute (wonder if this works)
        
        if needAnAttribute {
            if phoneField.text != "" {
                let reclassedProviderAttribute = AWSCognitoIdentityUserAttributeType()
                reclassedProviderAttribute?.name = "phone_number"
                reclassedProviderAttribute?.value = phoneField.text
                attributesToUpdate.append(reclassedProviderAttribute!)
                needAnAttribute = false
            }
        }
        
        
        // is there an email
        needAnAttribute = true
        
        for attribute in attributes! {
            if attribute.name! == "email" {
                if attribute.value! != emailField.text { // changed
                    needAnAttribute = false
                    let reclassedProviderAttribute = AWSCognitoIdentityUserAttributeType()
                    reclassedProviderAttribute?.name = attribute.name
                    reclassedProviderAttribute?.value = emailField.text
                    attributesToUpdate.append(reclassedProviderAttribute!)
                }
                
            }
            
        }
        // if we don't have an email attribute but the field isn't empty then
        // add the attribute (wonder if this works)
        
        if needAnAttribute {
            if emailField.text != "" {
                let reclassedProviderAttribute = AWSCognitoIdentityUserAttributeType()
                reclassedProviderAttribute?.name = "email"
                reclassedProviderAttribute?.value = emailField.text
                attributesToUpdate.append(reclassedProviderAttribute!)
                needAnAttribute = false
            }
        }
        
        
        
        
        // here we have to figure out if there were attributes to add in case
        // they were not existing attributes.
        
        updateAnAttribute(attributesToUpdate)?.continue( {(task) in
            if task.error != nil {
               NSLog("\(task.error)")
            }
        return nil
        } )
    }
    
    // recursively goes through the attributes list and
    // updates one at a time in sequence
    
    func updateAnAttribute(_ remainingAttributes: [AWSCognitoIdentityUserAttributeType]) -> AWSTask<AnyObject>? {
        
        var workingAttributes:[AWSCognitoIdentityUserAttributeType] = remainingAttributes
        
        
        if workingAttributes.count >= 1 {
            
            return self.user?.update([workingAttributes.removeFirst() ]).continue({ (task) in
                if task.error != nil {
                    NSLog("error\(task.error)")
                } else {
                                NSLog("Update Attributes Continuation Block Running for: \((task.result)?.codeDeliveryDetailsList?[0].attributeName) Delivery list count is: \((task.result)?.codeDeliveryDetailsList?.count)")
                }

                DispatchQueue.main.async {
                    
                    if task.error != nil {  // some sort of error
                        let alert = UIAlertController(title: "", message: (task.error as? NSError)?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        NSLog("\(task.error)")
                    } else {
                        let response = task.result 
                        
                        
                        if let delivery = response?.codeDeliveryDetailsList?[0] {
                            DispatchQueue.main.async {
                                // setup to send sentTo thru segue
                                self.performSegue(withIdentifier: "confirmAttribute", sender: delivery)
                            }
                        }
                    }
                }
                return self.updateAnAttribute(workingAttributes)  // recurse
            })
        } else {
            
            // no more to update


            return nil
        }
        
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "confirmAttribute" {
            
            let confirmViewController = segue.destination as! ConfirmAttributeViewController
            
            
            confirmViewController.confirmedAttribute = (sender as! AWSCognitoIdentityProviderCodeDeliveryDetailsType).attributeName
            
            confirmViewController.sentTo = (sender as! AWSCognitoIdentityProviderCodeDeliveryDetailsType).destination
            
            confirmViewController.user = self.pool?.getUser(self.usernameField.text!)  // why not just use self.user?
            
        }
    }
    
    
}
