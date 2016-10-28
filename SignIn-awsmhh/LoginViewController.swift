//
//  LoginViewController.swift
//


import UIKit
import AWSCore
import AWSCognitoIdentityProvider
//import AWSMobileHubHelper



class LoginViewController: UIViewController, AWSCognitoIdentityPasswordAuthentication {
    
    //Mark: Properties
    
    var didSignInObserver: AnyObject! // MHH signaling
    
    var usernameText: String?
    
    //MARK: Outlets for UI Elements.
    
    @IBOutlet weak var appNameLabel: UILabel!
    
    @IBOutlet weak var usernameField:   UITextField!
    @IBOutlet weak var imageView:       UIImageView!
    @IBOutlet weak var passwordField:   UITextField!
    
    @IBOutlet weak var youreNewLabel: UILabel!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var signUpNowButton: UIButton!
    
    @IBOutlet weak var facebookButton: UIButton!
    
    @IBOutlet weak var googleButton: UIButton!

    
    // helper subclass button be made active when fields are full
    @IBOutlet weak var loginButton: FieldSensitiveUIButton!
    
    //MARK: Global Variables for Changing Image Functionality.
    var backgroundImageCycler: BackgroundImageCycle?
    
    
    //MARK: View Controller LifeCycle
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.usernameField.text = self.usernameText // remember the userid
        self.passwordField.text = ""
        
        loginButton.disable()
        
        
        // setup background cycling - can't do it in viewDidLoad because
        // it never gets restarted when s/he logs out
        
        if backgroundImageCycler == nil {
            backgroundImageCycler = BackgroundImageCycle(self.imageView, speed: 5)
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
        print("Sign In Loading.")
        
        // set default text and button color at any entrypoints to the app
        //
        
        AppColor.defaultColor = appNameLabel.textColor
        
        // setup fade in animations
        // fades from alpha 0 to 1 at first display.
        // this causes an error in the log due to my use of uivisualeffect
        // but functionality seems uneffected.
        
        colorInterface()
        fadeInInterface()
        
        // button helper subclass
        loginButton.requiredFields(usernameField,passwordField)
        
        
        didSignInObserver = NSNotificationCenter.defaultCenter().addObserverForName(
            AWSIdentityManagerDidSignInNotification,
            object: AWSIdentityManager.defaultIdentityManager(),
            queue: NSOperationQueue.mainQueue(),
            usingBlock: {(note: NSNotification) -> Void in
                
                // perform successful login actions here
                if AWSIdentityManager.defaultIdentityManager().currentSignInProvider is AWSCUPIdPSignInProvider {
                    // only remember the name of the user if it is a CUPIdP name
                    self.usernameText = AWSIdentityManager.defaultIdentityManager().userName
                }
        })
        
        // Facebook login permissions can be optionally set, but must be set
        // before user authenticates.
        
        AWSFacebookSignInProvider.sharedInstance().setPermissions(["public_profile"]);
        
        // Facebook login behavior can be optionally set, but must be set
        // to use webview, uncomment out this line.
        //AWSFacebookSignInProvider.sharedInstance().setLoginBehavior(FBSDKLoginBehavior.Web.rawValue)
        //AWSFacebookSignInProvider.sharedInstance().setLoginBehavior(FBSDKLoginBehavior.Web.rawValue)
        
        // Facebook UI Setup
        facebookButton.addTarget(self, action: #selector(LoginViewController.handleFacebookLogin), forControlEvents: .TouchUpInside)
        let facebookButtonImage: UIImage? = UIImage(named: "FacebookButton")
        if let facebookButtonImage = facebookButtonImage{
            facebookButton.setImage(facebookButtonImage, forState: .Normal)
        } else {
            print("Facebook button image unavailable. We're hiding this button.")
            facebookButton.hidden = true
        }
        view.addConstraint(NSLayoutConstraint(item: facebookButton, attribute: .Top, relatedBy: .Equal, toItem: anchorViewForFacebook(), attribute: .Bottom, multiplier: 1, constant: 8.0))
        
        // Google login scopes can be optionally set, but must be set
        // before user authenticates.
        AWSGoogleSignInProvider.sharedInstance().setScopes(["profile", "openid"])
        
        // Sets up the view controller that the Google signin will be launched from.
        AWSGoogleSignInProvider.sharedInstance().setViewControllerForGoogleSignIn(self)
        
        // Google UI Setup
        googleButton.addTarget(self, action: #selector(LoginViewController.handleGoogleLogin), forControlEvents: .TouchUpInside)
        let googleButtonImage: UIImage? = UIImage(named: "GoogleButton")
        if let googleButtonImage = googleButtonImage {
            googleButton.setImage(googleButtonImage, forState: .Normal)
        } else {
            print("Google button image unavailable. We're hiding this button.")
            googleButton.hidden = true
        }
        view.addConstraint(NSLayoutConstraint(item: googleButton, attribute: .Top, relatedBy: .Equal, toItem: anchorViewForGoogle(), attribute: .Bottom, multiplier: 1, constant: 8.0))
        // CognitoYourUserPools login setup
        loginButton.addTarget(self, action: #selector(LoginViewController.handleCUPIdPLogin), forControlEvents: .TouchUpInside)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(didSignInObserver)
    }
    
    func dimissController() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // this is hooked to a tap gesture recognizer in the storyboard
    
    @IBAction func backgroundPressed(sender: AnyObject) {
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    // MARK: code (currently unused) for AWSCognitoIdentityPasswordAuthentication
    // completion routine returned by getPasswordAuthenticationDetails
    var passwordAuthenticationCompletion: AWSTaskCompletionSource = AWSTaskCompletionSource.init()
    
    // MARK: AWSCognitoIdentityPasswordAuthentication delegate must
    // implement getPasswordAuthenticationDetails and
    // didCompletePasswordAuthenticationStepWithError
    // i think this view controller was set as the delegate by appDelegate
    // when it returned the view controller on startPasswordAuthentication
    // but the documentation is unclear.  In any case, this is where you
    // will get control when you try to access the user object for a
    // user that is not authenticated
    
    // note: AWS is going to pass us a passwordAuthenticationCompletionSource
    // object, which we must save for the callback. When we have a username and password
    // to authenticate we call the setResult method of that object.
    
    // if we do turn on this code, then
    // call setResult in the callback object the API provided once we have a password (don't know whether we can call normal getSession at
    // that point, or whether we need two paths through the code)
    // self.passwordAuthenticationCompletion.setResult(AWSCognitoIdentityPasswordAuthenticationDetails(username: usernameField.text!, password: passwordField.text!))
    
    
    func getPasswordAuthenticationDetails(authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource) {
        self.passwordAuthenticationCompletion = passwordAuthenticationCompletionSource
        
        dispatch_async(dispatch_get_main_queue(), {
            
            //            self.usernameText = authenticationInput.lastKnownUsername
            
        })
    }
    
    
    // And in another confusing thing.  If you authenticate CORRECTLY with no error
    // the API calls didCompletePasswordAuthenticationStepWithError (but with a null error)
    // so here is where we get control back, and we send the authenticated user back into our app
    // viewcontroller.  Or if we get an error, we explain/complain (using just the default
    // error messages) and let the user try again.
    
    func didCompletePasswordAuthenticationStepWithError(error: NSError?) {
        
        dispatch_async(dispatch_get_main_queue(), {
            if let theError = error {
                let ac = UIAlertController(title: "Authentication Error", message: theError.userInfo["message" as NSObject] as? String, preferredStyle: .Alert)
                ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(ac, animated: true, completion: nil)
                
                // Clear password and user try again
                self.passwordField.text = nil
                self.loginButton.disable()
                
                
            } else { // no error means we are authenticated (loggedIn)
                
                // we are logged in, go get credentials
                
            }
            
        })
    }
    // MARK: end of code (currently unused) for AWSCognitoIdentityPasswordAuthentication
    
    // MARK: - Utility Methods
    func colorInterface() {
        
        // app opens with all elements alpha 0 (invisible)
        // then they fade in
        
        usernameField.alpha = 0.0
        passwordField.alpha = 0.0
        loginButton.alpha = 0.0
        forgotPasswordButton.alpha = 0.0
        youreNewLabel.alpha = 0.0
        signUpNowButton.alpha = 0.0
        
        
        AppColor.colorizeField(usernameField,passwordField)
        AppColor.colorizeButton(forgotPasswordButton,signUpNowButton)
        loginButton.colorize(enabledBackgroundColor: AppColor.defaultColor)
        
    }
    
    func fadeInInterface() {
        
        UIView.animateWithDuration(0.6, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.usernameField.alpha = 1.0
            self.passwordField.alpha = 1.0
            self.forgotPasswordButton.alpha = 1.0
            self.youreNewLabel.alpha = 1.0
            self.signUpNowButton.alpha = 1.0
            self.loginButton.alpha = 1.0
            }, completion: nil)
    }
    
    func handleLoginWithSignInProvider(signInProvider: AWSSignInProvider) {
        
        AWSIdentityManager.defaultIdentityManager().loginWithSignInProvider(signInProvider, completionHandler: {(result: AnyObject?, error: NSError?) -> Void in
            // If no error reported by SignInProvider, discard the sign-in view controller.
            if error == nil {
                dispatch_async(dispatch_get_main_queue(),{
                    self.navigationController!.popViewControllerAnimated(true)
                })
            } else {
                dispatch_async(dispatch_get_main_queue(),{
                    self.showErrorDialog(AWSIdentityManager.defaultIdentityManager().providerKey(signInProvider), withError: error!)
                })
            }
            print("result = \(result), error = \(error)")
            
        })
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
    
    // MARK: - IBActions
    func handleFacebookLogin() {
        handleLoginWithSignInProvider(AWSFacebookSignInProvider.sharedInstance())
    }
    
    
    func handleGoogleLogin() {
        handleLoginWithSignInProvider(AWSGoogleSignInProvider.sharedInstance())
    }
    // CUPIdP changes
    
    // Now facebook and Google prompt for UID password, but here we prompt
    // for them BEFORE calling handleLoginWithSignInProvider.
    // Best solution is probably to make CUPIdP login work just like Google
    // and Facebook and let it prompt for it's own password.  If we did that we could
    // just have a row of "login with..." buttons on the home screen that
    // would disappear upon successful login.
    
    func handleCUPIdPLogin() {
        
        if (usernameField.text != nil) && (passwordField.text != nil) {

            let customSignInProvider = AWSCUPIdPSignInProvider.sharedInstance
            
            // Push userId and password to our AWSCUPIdPSignInProvider
            customSignInProvider.customUserIdField = usernameField.text
            customSignInProvider.customPasswordField = passwordField.text
            
            handleLoginWithSignInProvider(customSignInProvider)
        }
    }
    
    
    func anchorViewForFacebook() -> UIView {
        return signUpNowButton
    }
    
    func anchorViewForGoogle() -> UIView {
        return facebookButton
        
    }
    
    // MARK: - Navigation
    
    // Prefill the username for forgot password and also for
    // signup now (in case the user tried a username first)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let segueID = segue.identifier {
            switch segueID {
            case "forgotPassword":
                let forgotPasswordViewController = segue.destinationViewController as! ForgotPasswordViewController
                forgotPasswordViewController.usernameText = self.usernameField.text
            case "signupNow":
                let signupViewController = segue.destinationViewController as! SignupViewController
                signupViewController.usernameText = self.usernameField.text
            default:
                break
            }
        }
    }
}

