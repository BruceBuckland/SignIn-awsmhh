//
//  MainViewController.swift
//  signin
//
//  Created by Bruce Buckland on 7/10/16.
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
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        actionRequiringAuthenticationButton.setTitle("Sign-Out All Accounts", for: UIControlState())
        actionNotRequiringAuthenticationButton.setTitle("What providers are active?", for: UIControlState())
        
        signInObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AWSIdentityManagerDidSignIn, object: AWSIdentityManager.defaultIdentityManager(), queue: OperationQueue.main, using: {[weak self] (note: Notification) -> Void in
            guard let strongSelf = self else { return }
            print("Sign In Observer observed sign in.")
            strongSelf.setupBarButtonItems()
            strongSelf.refreshInterface("-SignIn \(strongSelf.authenticatedBy())")
            })
        
        signOutObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AWSIdentityManagerDidSignOut, object: AWSIdentityManager.defaultIdentityManager(), queue: OperationQueue.main, using: {[weak self](note: Notification) -> Void in
            guard let strongSelf = self else { return }
            print("Sign Out Observer observed sign out.")
            strongSelf.setupBarButtonItems()
            strongSelf.refreshInterface("-Sign-out says current login is: \(strongSelf.authenticatedBy())")
            })
        // when we really have an identityId - start processing.
        completeInitializationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AWSMobileClient.AWSMobileClientDidCompleteInitialization), object: AWSMobileClient.sharedInstance, queue: OperationQueue.main, using: {[weak self](note: Notification) -> Void in
            guard let strongSelf = self else { return }
            print("Initialization of AWSIdentityManager complete, we now have an identityId")
            strongSelf.refreshInterface("-Complete \(strongSelf.authenticatedBy())")
            })
        setupBarButtonItems()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(signInObserver)
        NotificationCenter.default.removeObserver(signOutObserver)
    }
    
    func setupBarButtonItems() {
        
        let loginButton: UIBarButtonItem = UIBarButtonItem(title: nil, style: .done, target: self, action: nil)
        self.navigationItem.rightBarButtonItem = loginButton
        
        
        if (AWSIdentityManager.defaultIdentityManager().isLoggedIn) {
            navigationItem.rightBarButtonItem!.title = NSLocalizedString("Sign-Out", comment: "Label for the logout button.")
            
            navigationItem.rightBarButtonItem!.action = #selector(MainViewController.handleLogout)
            let mergeButton: UIBarButtonItem = UIBarButtonItem(title: "Sign-In or Link Accounts", style: .done, target: self, action: #selector(MainViewController.goToLogin))
            self.navigationItem.leftBarButtonItem = mergeButton
        }
        if !(AWSIdentityManager.defaultIdentityManager().isLoggedIn) {
            navigationItem.rightBarButtonItem!.title = NSLocalizedString("Sign-In", comment: "Label for the login button.")
            navigationItem.rightBarButtonItem!.action = #selector(MainViewController.goToLogin)
            self.navigationItem.leftBarButtonItem = nil // can't merge when not logged in
        }
    }
    
    func goToLogin() {
        print("Handling optional sign-in.")
        
        if loginController == nil { // use the same one - or we get multiple observers there
            let loginStoryboard = UIStoryboard(name: "Main", bundle: nil)
            loginController = loginStoryboard.instantiateViewController(withIdentifier: "login")
        }
        
        navigationController!.pushViewController(loginController, animated: true)
    }
    
    func handleLogout(_ allProviders:Bool = false) {
        if (AWSIdentityManager.defaultIdentityManager().isLoggedIn) {
            AWSIdentityManager.defaultIdentityManager().logout(completionHandler: {(result: Any?, error: Error?) -> Void in
                if allProviders && AWSIdentityManager.defaultIdentityManager().isLoggedIn { // keep logging out till no more providers
                    self.handleLogout(true)
                }
                if error != nil {
                    assert(false)
                }
                self.navigationController!.popToRootViewController(animated: false)
                self.setupBarButtonItems()
            } )
            // print("Logout Successful: \(signInProvider.getDisplayName)");
            
        } else {
            // this condition is possible if you get an error when logging in, and then
            // have an active provider that is not really logged in.
            // probably a bug in AWSIdentityManager
            NSLog("handleLogout ran when defaultIdentityManager was not loggedIn");
            NSLog(self.authenticatedBy())
            NSLog((AWSIdentityManager.defaultIdentityManager().currentSignInProvider as AnyObject).identityProviderName)
            
            // assert(false)
        }
    }
    
    
    // test routine for something that requires an authenticated user
    @IBAction func actionRequiringAuthenticationPressed(_ sender: AnyObject) {
        handleLogout(true)     // Log out all users
    }
    
    // test routines for something that any user can do, even guests.
    @IBAction func actionNotRequiringAuthenticationPressed(_ sender: AnyObject) {
        var line = ""
        for provider in AWSIdentityManager.defaultIdentityManager().activeProviders() as! [AWSSignInProvider] {
            NSLog("provider: \(AWSIdentityManager.defaultIdentityManager().providerKey(provider)) authenticated by: \(self.authenticatedBy()) username: \(provider.userName) imageURL:\(provider.imageURL)")
            
            if AWSIdentityManager.defaultIdentityManager().providerKey(provider) == self.authenticatedBy() {
                if provider.userName == nil { // should not happen but currently does when errors or cancel on signin
                    line += "Sign On Error Not Properly Reversed by Mobile Hub Helper on *" + AWSIdentityManager.defaultIdentityManager().providerKey(provider) + ", "
                } else {
                    line += "\(provider.userName!) on *" + AWSIdentityManager.defaultIdentityManager().providerKey(provider) + ", " // flag our auth provider now
                    
                }
            } else {
                line += "\(provider.userName!) on " + AWSIdentityManager.defaultIdentityManager().providerKey(provider) + ", "
            }
            
        }
        if line == "" {
            line = "None, just a " + self.authenticatedBy()
        }
        self.otherDataLabel.text! = "-Authenticated users:" + line + "\n\n" + self.otherDataLabel.text!
    }
    
    func authenticatedBy() -> String {
        if let currentSignInProvider = AWSIdentityManager.defaultIdentityManager().currentSignInProvider as? AWSSignInProvider {
            return AWSIdentityManager.defaultIdentityManager().providerKey(currentSignInProvider)
        } else {
            return "Guest"
        }
    }
    
    func refreshInterface(_ appendToId: String = "-shouldNotHappen") {
        
        
        self.updateUserAttributesButton.isHidden = true
        self.actionRequiringAuthenticationButton.isHidden = true
        
        let identityManager = AWSIdentityManager.defaultIdentityManager()
        
        if identityManager.isLoggedIn  {
            if let signInProvider = identityManager.currentSignInProvider as? AWSCUPIdPSignInProvider {
                // Here we are dealing with an AWSCUPIdPSignInProvider
                self.updateUserAttributesButton.isHidden = false
                getCUPIdPAttributes(signInProvider: signInProvider)
            }
            
            self.otherDataLabel.text! =  "\n" + self.otherDataLabel.text!
            if let email = identityManager.email {
                self.otherDataLabel.text! = "Email:" + email + "\n" + self.otherDataLabel.text!
            }
            if let phone = identityManager.phone {
                self.otherDataLabel.text! = "Phone:" + phone + "\n" + self.otherDataLabel.text!
            }
            self.otherDataLabel.text! =  "\(appendToId) \(identityManager.identityId!)"  + "\n" + self.otherDataLabel.text!
            
            
            
            
        } else {
            // What can I get if I don't even have a provider (Unauthenticated)
            // debug self.otherDataLabel.text! =  "\(appendToId) \(identityManager.identityId!)"  + "\n" + self.otherDataLabel.text!
        }
        
        // What can I get from every Provider?
        
        if identityManager.isLoggedIn {
            
            print("Authenticated by: \(self.authenticatedBy())")
            
            self.usernameLabel.text = self.authenticatedBy() + " authenticated " +  identityManager.userName!
            self.actionRequiringAuthenticationButton.isHidden = false
        } else {
            self.usernameLabel.text = "Guest User"
        }
        
        
    }
    func getCUPIdPAttributes(signInProvider: AWSCUPIdPSignInProvider)  {
        signInProvider.user.getDetails().continue( { (task) in
            DispatchQueue.main.async {
                if task.error != nil {  // some sort of error
                    let alert = UIAlertController(title: "", message: (task.error as? NSError)?.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    NSLog("\(task.error)")
                } else {
                    if let response = task.result  {
                        
                        self.attributes = response.userAttributes!
                        //                        for attribute in response.userAttributes! {
                        //                            self.attributes.append(attribute) // keep for seque
                        //                        }
                    }
                }
            }
            return nil  // return from get details synchronously
        })
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "updateAttributes" {
            let targetViewController = segue.destination as! UpdateAttributesViewController
            targetViewController.username = AWSIdentityManager.defaultIdentityManager().userName
            
            
            targetViewController.attributes = self.attributes
        }
    }
}

