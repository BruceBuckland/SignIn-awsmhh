//
//  ViewController.swift
//

import UIKit

import AWSCore
import AWSCognitoIdentityProvider
// import AWSMobileHubHelper

class ViewController: UIViewController, AWSCognitoIdentityPasswordAuthentication {
    
    var usernameText: String?
    
    
    // loggedIn state change observers
    var didSignInObserver: AnyObject!
    var didSignOutObserver: AnyObject!
    var didCompleteInitializationObserver: AnyObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        didSignInObserver = NSNotificationCenter.defaultCenter().addObserverForName(
            AWSIdentityManagerDidSignInNotification,
            object: AWSIdentityManager.defaultIdentityManager(),
            queue: NSOperationQueue.mainQueue(),
            usingBlock: {(note: NSNotification) -> Void in
                
                // perform successful login actions here
                if AWSIdentityManager.defaultIdentityManager().currentSignInProvider is AWSCUPIdPSignInProvider {
                    // only remember the name of the user if it is a CUPIdP name
                    self.usernameText = AWSIdentityManager.defaultIdentityManager().userName
                    print(">>>>> Sign In Observer observed sign in for: " + self.usernameText!)
                }
        })
        
        didSignOutObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignOutNotification, object: AWSIdentityManager.defaultIdentityManager(), queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self](note: NSNotification) -> Void in
            print(">>>>> Sign Out Observer observed sign out.")
            })
        
        
        // when we really have an identityId - start processing.
        didCompleteInitializationObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSMobileClient.AWSMobileClientDidCompleteInitialization, object: AWSMobileClient.sharedInstance, queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self](note: NSNotification) -> Void in
            
            NSLog(">>>>> Initialization of AWSIdentityManager complete, we now have an identityId \(AWSIdentityManager.defaultIdentityManager().identityId)"))
            })
        
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(didSignInObserver)
        NSNotificationCenter.defaultCenter().removeObserver(didSignOutObserver)
        NSNotificationCenter.defaultCenter().removeObserver(didCompleteInitializationObserver)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actionSignIn(sender: AnyObject) {
        
        let identifiant:String? = "Username0"
        let motDePasse:String?  = "Password0"
        
        if (identifiant != nil) && (motDePasse != nil) {
            
            // BEFORE you log in you may have sessions left over
            let identityProvidersWithActiveSessions = AWSIdentityManager.defaultIdentityManager().activeProviders()
            NSLog("Active Sessions Exist with these signin providers: \(identityProvidersWithActiveSessions)")
            
            let customSignInProvider = AWSCUPIdPSignInProvider.sharedInstance
            
            // Push userId and password to our AWSCUPIdPSignInProvider
            
            customSignInProvider.customUserIdField = identifiant
            customSignInProvider.customPasswordField = motDePasse
            
            handleLoginWithSignInProvider(customSignInProvider)
            
        }
        
        
    }
    func showAlert(titleText: String, message: String) {
        var alertController: UIAlertController!
        alertController = UIAlertController(title: titleText, message: message, preferredStyle: .Alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Done", comment: "Label to cancel dialog box."), style: .Cancel, handler: nil)
        alertController.addAction(doneAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showErrorDialog(loginProviderName: String, withError error: NSError) {
        print("\(loginProviderName) failed to sign in w/ error: \(error)")
        if let message = error.userInfo["message"] {
            showAlert(NSLocalizedString("\(loginProviderName) Sign-in Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("Sign in using \(loginProviderName) failed: \(message)", comment: "Sign-in message structure for sign-in failure."))
        } else if let message = error.userInfo["NSLocalizedDescription"]{
            showAlert(NSLocalizedString("\(loginProviderName) Sign-in Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("Sign in using \(loginProviderName) failed: \(message)", comment: "Sign-in message structure for sign-in failure."))
        } else {
            showAlert(NSLocalizedString("\(loginProviderName) Sign-In Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("\(loginProviderName) failed to sign in w/ error: \(error)", comment: "Sign-in message structure for sign-in failure."))
        }
    }
    
    func handleLoginWithSignInProvider(signInProvider: AWSSignInProvider) {
        
        AWSIdentityManager.defaultIdentityManager().loginWithSignInProvider(signInProvider, completionHandler: {(result: AnyObject?, error: NSError?) -> Void in
            // If no error reported by SignInProvider, discard the sign-in view controller.
            if error == nil {
//                dispatch_async(dispatch_get_main_queue(),{
//                    self.navigationController!.popViewControllerAnimated(true)
//                })
            } else {
                dispatch_async(dispatch_get_main_queue(),{
                    self.showErrorDialog(AWSIdentityManager.defaultIdentityManager().providerKey(signInProvider), withError: error!)
                })
            }
            print("result = \(result), error = \(error)")
            
        })
    }
    
    // MARK: Protocole AWSCognitoIdentityPasswordAuthentication
    func getPasswordAuthenticationDetails(authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource) {
        
    }
    
    func didCompletePasswordAuthenticationStepWithError(error: NSError?) {
        
    }
    
}

