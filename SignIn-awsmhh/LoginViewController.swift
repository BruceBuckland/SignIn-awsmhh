//
//  LoginViewController.swift
//


import UIKit
import AWSCore
import AWSCognitoIdentityProvider
//import AWSMobileHubHelper
import FBSDKLoginKit



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
    
    override func viewWillAppear(_ animated: Bool) {
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
        
        
        didSignInObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.AWSIdentityManagerDidSignIn,
            object: AWSIdentityManager.defaultIdentityManager(),
            queue: OperationQueue.main,
            using: {(note: Notification) -> Void in
                
                // perform successful login actions here
                if AWSIdentityManager.defaultIdentityManager().currentSignInProvider is AWSCUPIdPSignInProvider {
                    // only remember the name of the user if it is a CUPIdP name
                    self.usernameText = AWSIdentityManager.defaultIdentityManager().userName
                }
        })
        
        // Facebook login permissions can be optionally set, but must be set
        // before user authenticates.
        
        AWSFacebookSignInProvider.sharedInstance().setPermissions(["public_profile"]);
        // or ask for @[@"public_profile", @"email", @"user_friends"]; but in swift.
        
        // Facebook login behavior can be optionally set, but must be set
        // to use webview, uncomment out this line.
        // popup window, doesn't remember username
        //AWSFacebookSignInProvider.sharedInstance().setLoginBehavior(FBSDKLoginBehavior.web.rawValue)
        // seems to use safari, and remembers apparently this is the default. 
        AWSFacebookSignInProvider.sharedInstance().setLoginBehavior(FBSDKLoginBehavior.native.rawValue)
        //AWSFacebookSignInProvider.sharedInstance().setLoginBehavior(FBSDKLoginBehavior.systemAccount.rawValue)
        // AWSFacebookSignInProvider.sharedInstance().setLoginBehavior(FBSDKLoginBehavior.SystemAccount.rawValue)
        
        // AWSFacebookSignInProvider.sharedInstance().setLoginBehavior(FBSDKLoginBehavior.Browser.rawValue)
        
        
        // Facebook UI Setup
        facebookButton.addTarget(self, action: #selector(LoginViewController.handleFacebookLogin), for: .touchUpInside)
        let facebookButtonImage: UIImage? = UIImage(named: "FacebookButton")
        if let facebookButtonImage = facebookButtonImage{
            facebookButton.setImage(facebookButtonImage, for: UIControlState())
        } else {
            print("Facebook button image unavailable. We're hiding this button.")
            facebookButton.isHidden = true
        }
        view.addConstraint(NSLayoutConstraint(item: facebookButton, attribute: .top, relatedBy: .equal, toItem: anchorViewForFacebook(), attribute: .bottom, multiplier: 1, constant: 8.0))
        
        // Google login scopes can be optionally set, but must be set
        // before user authenticates.
        AWSGoogleSignInProvider.sharedInstance().setScopes(["profile", "openid"])
        
        // Sets up the view controller that the Google signin will be launched from.
        AWSGoogleSignInProvider.sharedInstance().setViewControllerForGoogleSignIn(self)
        
        // Google UI Setup
        googleButton.addTarget(self, action: #selector(LoginViewController.handleGoogleLogin), for: .touchUpInside)
        let googleButtonImage: UIImage? = UIImage(named: "GoogleButton")
        if let googleButtonImage = googleButtonImage {
            googleButton.setImage(googleButtonImage, for: UIControlState())
        } else {
            print("Google button image unavailable. We're hiding this button.")
            googleButton.isHidden = true
        }
        view.addConstraint(NSLayoutConstraint(item: googleButton, attribute: .top, relatedBy: .equal, toItem: anchorViewForGoogle(), attribute: .bottom, multiplier: 1, constant: 8.0))
        // CognitoYourUserPools login setup
        loginButton.addTarget(self, action: #selector(LoginViewController.handleCUPIdPLogin), for: .touchUpInside)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(didSignInObserver)
    }
    
    func dimissController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // this is hooked to a tap gesture recognizer in the storyboard
    
    @IBAction func backgroundPressed(_ sender: AnyObject) {
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    // MARK: code (currently unused) for AWSCognitoIdentityPasswordAuthentication
    // completion routine returned by getPasswordAuthenticationDetails
    var passwordAuthenticationCompletion = AWSTaskCompletionSource<AnyObject>.init()
    
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
    
    /**
     Obtain username and password from end user.
     @param authenticationInput input details including last known username
     @param passwordAuthenticationCompletionSource set passwordAuthenticationCompletionSource.result
     with the username and password received from the end user.
     */
    func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        self.passwordAuthenticationCompletion = passwordAuthenticationCompletionSource as! AWSTaskCompletionSource<AnyObject>
        
        DispatchQueue.main.async(execute: {
            
            //            self.usernameText = authenticationInput.lastKnownUsername
            
        })
    }
    
    
    // And in another confusing thing.  If you authenticate CORRECTLY with no error
    // the API calls didCompletePasswordAuthenticationStepWithError (but with a null error)
    // so here is where we get control back, and we send the authenticated user back into our app
    // viewcontroller.  Or if we get an error, we explain/complain (using just the default
    // error messages) and let the user try again.
    
    func didCompleteStepWithError(_ error: Error?) {
        
        DispatchQueue.main.async(execute: {
            if let theError = error as? NSError {
                let ac = UIAlertController(title: "Authentication Error", message: theError.userInfo["message" as NSObject] as? String, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true, completion: nil)
                
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
        
        UIView.animate(withDuration: 0.6, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.usernameField.alpha = 1.0
            self.passwordField.alpha = 1.0
            self.forgotPasswordButton.alpha = 1.0
            self.youreNewLabel.alpha = 1.0
            self.signUpNowButton.alpha = 1.0
            self.loginButton.alpha = 1.0
            }, completion: nil)
    }
    
    func handleLoginWithSignInProvider(_ signInProvider: AWSSignInProvider) {
        
        AWSIdentityManager.defaultIdentityManager().loginWithSign(signInProvider, completionHandler: {(result: Any?, error: Error?) -> Void in
            // If no error reported by SignInProvider, discard the sign-in view controller.
            if error == nil {
                DispatchQueue.main.async(execute: {
                    self.navigationController!.popViewController(animated: true)
                })
            } else {
                DispatchQueue.main.async(execute: {
                    self.showErrorDialog(AWSIdentityManager.defaultIdentityManager().providerKey(signInProvider), withError: error!)
                })
            }
            print("result = \(result), error = \(error)")
            
        })
    }
    
    func showAlert(_ titleText: String, message: String) {
        var alertController: UIAlertController!
        alertController = UIAlertController(title: titleText, message: message, preferredStyle: .alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Done", comment: "Label to cancel dialog box."), style: .cancel, handler: nil)
        alertController.addAction(doneAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showErrorDialog(_ loginProviderName: String, withError error: Error) {
        print("\(loginProviderName) failed to sign in w/ error: \(error)")
        if let message = (error as NSError).userInfo["message"] {
            showAlert(NSLocalizedString("\(loginProviderName) Sign-in Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("Sign in using \(loginProviderName) failed: \(message)", comment: "Sign-in message structure for sign-in failure."))
        } else if let message = (error as NSError).userInfo["NSLocalizedDescription"]{
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let segueID = segue.identifier {
            switch segueID {
            case "forgotPassword":
                let forgotPasswordViewController = segue.destination as! ForgotPasswordViewController
                forgotPasswordViewController.usernameText = self.usernameField.text
            case "signupNow":
                let signupViewController = segue.destination as! SignupViewController
                signupViewController.usernameText = self.usernameField.text
            default:
                break
            }
        }
    }
}

