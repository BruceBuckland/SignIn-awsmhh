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
// import AWSMobileHubHelper

class MainViewController: UIViewController {
    
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var otherDataLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var updateUserAttributesButton: UIButton!
    
    @IBOutlet weak var actionRequiringAuthenticationButton: UIButton!
    
    @IBOutlet weak var actionNotRequiringAuthenticationButton: UIButton!
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
        actionRequiringAuthenticationButton.setTitle("Sign-Out All Accounts", forState: .Normal)
        actionNotRequiringAuthenticationButton.setTitle("What providers are active?", forState: .Normal)
        
        signInObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignInNotification, object: AWSIdentityManager.defaultIdentityManager(), queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self] (note: NSNotification) -> Void in
            guard let strongSelf = self else { return }
            print("Sign In Observer observed sign in.")
            strongSelf.logUsername()
            strongSelf.setupBarButtonItems()
            strongSelf.refreshInterface("-SignIn \(strongSelf.authenticatedBy())")
            })
        
        signOutObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignOutNotification, object: AWSIdentityManager.defaultIdentityManager(), queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self](note: NSNotification) -> Void in
            guard let strongSelf = self else { return }
            print("Sign Out Observer observed sign out.")
            strongSelf.setupBarButtonItems()
            strongSelf.refreshInterface("-Sign-out says current login is: \(strongSelf.authenticatedBy())")
            })
        // when we really have an identityId - start processing.
        completeInitializationObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSMobileClient.AWSMobileClientDidCompleteInitialization, object: AWSMobileClient.sharedInstance, queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self](note: NSNotification) -> Void in
            guard let strongSelf = self else { return }
            NSLog(">>>>> Initialization of AWSIdentityManager complete, we now have an identityId \(AWSIdentityManager.defaultIdentityManager().identityId)")
            strongSelf.refreshInterface("-Complete \(strongSelf.authenticatedBy())")
            })
        setupBarButtonItems()
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
            let mergeButton: UIBarButtonItem = UIBarButtonItem(title: "Sign-In or Link Accounts", style: .Done, target: self, action: #selector(MainViewController.goToLogin))
            self.navigationItem.leftBarButtonItem = mergeButton
        }
        if !(AWSIdentityManager.defaultIdentityManager().loggedIn) {
            navigationItem.rightBarButtonItem!.title = NSLocalizedString("Sign-In", comment: "Label for the login button.")
            navigationItem.rightBarButtonItem!.action = #selector(MainViewController.goToLogin)
            self.navigationItem.leftBarButtonItem = nil // can't merge when not logged in
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
    
    func handleLogout(allProviders:Bool = false) {
        if (AWSIdentityManager.defaultIdentityManager().loggedIn) {
            AWSIdentityManager.defaultIdentityManager().logoutWithCompletionHandler({(result: AnyObject?, error: NSError?) -> Void in
                if allProviders && AWSIdentityManager.defaultIdentityManager().loggedIn { // keep logging out till no more providers
                    self.handleLogout(true)
                }
                if error != nil {
                    assert(false)
                }
                self.navigationController!.popToRootViewControllerAnimated(false)
                self.setupBarButtonItems()
            })
            // print("Logout Successful: \(signInProvider.getDisplayName)");
            
        } else {
            // this condition is possible if you get an error when logging in, and then
            // have an active provider that is not really logged in.
            // probably a bug in AWSIdentityManager
            NSLog("handleLogout ran when defaultIdentityManager was not loggedIn");
            NSLog(self.authenticatedBy())
            NSLog(AWSIdentityManager.defaultIdentityManager().currentSignInProvider.identityProviderName)
            
            // assert(false)
        }
    }
    
    
    // test routine for something that requires an authenticated user
    @IBAction func actionRequiringAuthenticationPressed(sender: AnyObject) {
        handleLogout(true)     // Log out all users
    }
    
    // test routines for something that any user can do, even guests.
    @IBAction func actionNotRequiringAuthenticationPressed(sender: AnyObject) {
        var line = ""
        for provider in AWSIdentityManager.defaultIdentityManager().activeProviders() as! [AWSSignInProvider] {
            NSLog("provider: \(AWSIdentityManager.providerKey(provider)) authenticated by: \(self.authenticatedBy()) username: \(provider.userName) imageURL:\(provider.imageURL)")
            
            if AWSIdentityManager.providerKey(provider) == self.authenticatedBy() {
                if provider.userName == nil { // should not happen but currently does when errors or cancel on signin
                    line += "Sign On Error Not Properly Reversed by Mobile Hub Helper on *" + AWSIdentityManager.providerKey(provider) + ", "
                } else {
                    line += "\(provider.userName!) on *" + AWSIdentityManager.providerKey(provider) + ", " // flag our auth provider now
                    
                }
            } else {
                line += "\(provider.userName!) on " + AWSIdentityManager.providerKey(provider) + ", "
            }
            
        }
        if line == "" {
            line = "None, just a " + self.authenticatedBy()
        }
        self.otherDataLabel.text! = "-Authenticated users:" + line + " \(AWSIdentityManager.defaultIdentityManager().identityId!)\n" + self.otherDataLabel.text!
    }
    
    func authenticatedBy() -> String {
        if let currentSignInProvider = AWSIdentityManager.defaultIdentityManager().currentSignInProvider as? AWSSignInProvider {
            return AWSIdentityManager.providerKey(currentSignInProvider)
        } else {
            return "Unauthenticated"
        }
    }
    
    func logUsername() {
        let identityManager = AWSIdentityManager.defaultIdentityManager()
        let provider = AWSIdentityManager.providerKey((identityManager.currentSignInProvider as? AWSSignInProvider)!)
        identityManager.recordIdentityForIdentityId(identityManager.userName!, provider: provider)
    }
    func refreshInterface(appendToId: String = "-shouldNotHappen") {
        
        self.updateUserAttributesButton.hidden = true
        self.actionRequiringAuthenticationButton.hidden = true
        
        if let signInProvider = AWSIdentityManager.defaultIdentityManager().currentSignInProvider as? AWSCUPIdPSignInProvider {
            
            // Here we are dealing with an AWSCUPIdPSignInProvider
            
            if AWSIdentityManager.defaultIdentityManager().loggedIn  {
                self.updateUserAttributesButton.hidden = false
                NSLog("We have an \(AWSIdentityManager.providerKey(signInProvider))")
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
                            if (AWSIdentityManager.defaultIdentityManager().identityId == nil) {
                                self.otherDataLabel.text! =  "\(appendToId) identityId is nil"  + "\n" + self.otherDataLabel.text!
                            } else {
                                self.otherDataLabel.text! =  "\(appendToId) \(AWSIdentityManager.defaultIdentityManager().identityId!)"  + "\n" + self.otherDataLabel.text!
                            }
                            
                            
                            for attribute in response.userAttributes! {
                                self.otherDataLabel.text! = attribute.name! +  ":" + attribute.value! + "\n" + self.otherDataLabel.text!
                                
                                self.attributes.append(attribute) // keep for seque
                            }
                        }
                    }
                }
                return nil  // return from get details synchronously
            }
        } else {
            // What can I get if I don't even have a provider (Unauthenticated)
            self.otherDataLabel.text! =  "\(appendToId) \(AWSIdentityManager.defaultIdentityManager().identityId!)"  + "\n" + self.otherDataLabel.text!
        }
        
        // What can I get from every Provider?
        
        if AWSIdentityManager.defaultIdentityManager().loggedIn {
            
            print("Authenticated by: \(self.authenticatedBy())")
            
            self.usernameLabel.text = self.authenticatedBy() + " authenticated " +  AWSIdentityManager.defaultIdentityManager().userName!
            self.actionRequiringAuthenticationButton.hidden = false
        } else {
            self.usernameLabel.text = "Guest User"
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "updateAttributes" {
            let targetViewController = segue.destinationViewController as! UpdateAttributesViewController
            targetViewController.username = AWSIdentityManager.defaultIdentityManager().userName
            targetViewController.attributes = self.attributes
        }
    }
}

