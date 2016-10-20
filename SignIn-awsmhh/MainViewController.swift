//
//  MainViewController.swift
//  signin
//
//  Created by Bruce Buckland on 7/10/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognito
import AWSCognitoIdentityProvider
import AWSDynamoDB
import AWSMobileHubHelper

class MainViewController: UIViewController {
    
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var otherDataLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var updateUserAttributesButton: UIButton!
    
    @IBOutlet weak var actionRequringAuthentication: UIButton!
    // MARK: Properties
    // attributes for update attributes call
    var attributes: [AWSCognitoIdentityProviderAttributeType] = []
    
    // loggedIn state change observers
    var signInObserver: AnyObject!
    var signOutObserver: AnyObject!
    var completeInitializationObserver: AnyObject!
    
    // loginViewControler - so we can re-use it (there must be an IOS-ey way to do this)
    var loginController: UIViewController!
    
    
    // MARK: Global Variables for Changing Image Functionality.
    var backgroundImageCycler: BackgroundImageCycle?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // set the default color to the color of the appNameLabel
        AppColor.defaultColor = appNameLabel.textColor
        
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // get a background image cycler
        if backgroundImageCycler == nil {
            backgroundImageCycler = BackgroundImageCycle(self.imageView, speed: 12)
        }
        backgroundImageCycler?.start()
        
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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)
        
        signInObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignInNotification, object: AWSIdentityManager.defaultIdentityManager(), queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self] (note: NSNotification) -> Void in
            guard let strongSelf = self else { return }
            print("Sign In Observer observed sign in.")
            strongSelf.setupBarButtonItems()
            strongSelf.refreshInterface("-SignIn")
            })
        
        signOutObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignOutNotification, object: AWSIdentityManager.defaultIdentityManager(), queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self](note: NSNotification) -> Void in
            guard let strongSelf = self else { return }
            print("Sign Out Observer observed sign out.")
            strongSelf.setupBarButtonItems()
            strongSelf.refreshInterface("-SignOut")
            })
        
        completeInitializationObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSMobileClient.AWSMobileClientDidCompleteInitialization, object: AWSMobileClient.sharedInstance, queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self](note: NSNotification) -> Void in
            guard let strongSelf = self else { return }
            print("Initialization of AWSIdentityManager complete, we now have an identityId")
            strongSelf.refreshInterface("-Complete")
            })
        
        setupBarButtonItems()
        refreshInterface()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(signInObserver)
        NSNotificationCenter.defaultCenter().removeObserver(signOutObserver)
    }
    
    func setupBarButtonItems() {
        struct Static {
            static var onceToken: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.onceToken, {
            let loginButton: UIBarButtonItem = UIBarButtonItem(title: nil, style: .Done, target: self, action: nil)
            self.navigationItem.rightBarButtonItem = loginButton
        })
        
        if (AWSIdentityManager.defaultIdentityManager().loggedIn) {
            navigationItem.rightBarButtonItem!.title = NSLocalizedString("Sign-Out", comment: "Label for the logout button.")
            
            navigationItem.rightBarButtonItem!.action = #selector(MainViewController.handleLogout)
//            let mergeButton: UIBarButtonItem = UIBarButtonItem(title: "Merge", style: .Done, target: self, action: #selector(MainViewController.goToLogin))
//            self.navigationItem.leftBarButtonItem = mergeButton
        }
        if !(AWSIdentityManager.defaultIdentityManager().loggedIn) {
            navigationItem.rightBarButtonItem!.title = NSLocalizedString("Sign-In", comment: "Label for the login button.")
            navigationItem.rightBarButtonItem!.action = #selector(MainViewController.goToLogin)
//            self.navigationItem.leftBarButtonItem = nil // can't merge when not logged in
        }
    }
    
    func goToLogin() {
        print("Handling optional sign-in.")
        
        if loginController == nil { // use the same one - or we get multiple observers there
            let loginStoryboard = UIStoryboard(name: "Main", bundle: nil)
            loginController = loginStoryboard.instantiateViewControllerWithIdentifier("login")
        }
        
        navigationController!.pushViewController(loginController, animated: true)
    }
    
    func handleLogout() {
        if (AWSIdentityManager.defaultIdentityManager().loggedIn) {
            AWSIdentityManager.defaultIdentityManager().logoutWithCompletionHandler({(result: AnyObject?, error: NSError?) -> Void in
                
                self.refreshInterface() // WILL kick off authentication
                
                self.navigationController!.popToRootViewControllerAnimated(false)
                
                self.setupBarButtonItems()
            })
            // print("Logout Successful: \(signInProvider.getDisplayName)");
            
        } else {
            assert(false)
        }
    }
    
    
    
    @IBAction func doSomethingAuthorizedPressed(sender: AnyObject) {
        refreshInterface()
    }
    
    func refreshInterface(appendToId: String = "") {
        
        self.updateUserAttributesButton.hidden = true
        self.actionRequringAuthentication.hidden = true
        self.otherDataLabel.text = ""
        
        if let signInProvider = AWSIdentityManager.defaultIdentityManager().currentSignInProvider as? AWSCUPIdPSignInProvider {
            
            // Here we are dealing with an AWSCUPIdPSignInProvider
            
            if AWSIdentityManager.defaultIdentityManager().loggedIn {
                self.updateUserAttributesButton.hidden = false
            }
            signInProvider.user.getDetails().continueWithSuccessBlock() { (task) in
                dispatch_async(dispatch_get_main_queue()) {
                    if task.error != nil {  // some sort of error
                        let alert = UIAlertController(title: "", message: task.error?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                        
                        NSLog("Domain: " + (task.error?.domain)! + " Code: \(task.error?.code)")
                        NSLog(task.error?.userInfo["message"] as! String)
                    } else {
                        
                        
                        if let response = task.result as? AWSCognitoIdentityUserGetDetailsResponse {
                            
                            self.otherDataLabel.text! +=  "\nAttributes: "
                            for attribute in response.userAttributes! {
                                self.otherDataLabel.text! += attribute.name! +  ":" + attribute.value! + "\n"
                                self.attributes.append(attribute) // keep for seque
                            }
                        }
                    }
                }
                return nil  // return from get details synchronously
            }
        }
        
        // What can I get from every Provider?
        
        if AWSIdentityManager.defaultIdentityManager().loggedIn {

            let name = NSStringFromClass(AWSIdentityManager.defaultIdentityManager().currentSignInProvider.dynamicType)
            
            let defaultDictionary = AWSInfo().defaultServiceInfo("IdentityManager")?.infoDictionary
            
            if let classKeys = defaultDictionary?["SignInProviderClassDictionary"] as? NSDictionary {
                for key in classKeys {
                    if key.1 as! String == name {
                        self.usernameLabel.text = (key.0 as! String)
                    }
                }
            } else {
                print("Info.plist configuration missing for  SignInProviderClassDictionary")
            }

            self.usernameLabel.text = self.usernameLabel.text! + " authenticated " +  AWSIdentityManager.defaultIdentityManager().userName!
            self.actionRequringAuthentication.hidden = false
        } else {
            self.usernameLabel.text = "Guest User"
        }
        
        self.otherDataLabel.text! +=  "\nIdentityId: \(AWSIdentityManager.defaultIdentityManager().identityId)" + appendToId
        
        
    }
    
    
    
    
    func goFindUserPoolConfig(response: AWSCognitoIdentityUserSession) {
        
        //        // request a description of my pool id
        //        let descriptionRequest = AWSCognitoIdentityProviderDescribeUserPoolRequest()
        //        descriptionRequest.userPoolId = AWSCUPIdPSignInProvider.sharedInstance.identityProviderName
        //
        //
        //        // using default provider
        //        let provider = AWSCognitoIdentityProvider.defaultCognitoIdentityProvider()
        //
        //        // maybe we need to AWSCognitoIdentityProvider.registerCognitoIdentityProviderWithConfiguration(<#T##configuration: AWSServiceConfiguration##AWSServiceConfiguration#>, forKey: <#T##String#>)
        //
        //        NSLog("8 Signed in (before provider.describeUserPool): \(self.pool?.currentUser()?.signedIn)")
        //
        //        provider.describeUserPool(descriptionRequest).continueWithBlock{ (task) in
        //
        //            dispatch_async(dispatch_get_main_queue()) {
        //
        //                if task.error != nil {  // some sort of error
        //                    // NSLog(task.error?.userInfo["message"] as! String)
        //                    NSLog("task: \(task)")
        //                    NSLog("task.error: \(task.error)")
        //                    NSLog("Domain: " + (task.error?.domain)! + " Code: \(task.error?.code)")
        //                    NSLog("\(task.error?.userInfo)")
        //                    //  NSLog("\(task.error?.userInfo["message"] as! String)")
        //
        //                }
        //                else {
        //                    let response = task.result as! AWSCognitoIdentityProviderDescribeUserPoolResponse
        //                    NSLog("Description of user pool \(descriptionRequest) is \(response)" )
        //                    NSLog("done")
        //                }
        //            }
        //            return nil
        //        }
        //
        //
        //
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "updateAttributes" {
            let targetViewController = segue.destinationViewController as! UpdateAttributesViewController
            targetViewController.username = AWSIdentityManager.defaultIdentityManager().userName
            targetViewController.attributes = self.attributes
        }
    }
}

