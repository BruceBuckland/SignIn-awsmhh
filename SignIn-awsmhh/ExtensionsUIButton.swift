//
//  ExtensionsUIButton.swift
//  signin
//
//  Created by Bruce Buckland on 7/26/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import UIKit
class FieldSensitiveUIButton: UIButton {
    
    var nonEmptyFields:[UITextField]?
    // button color (background color)
    var enabledBackgroundAlpha: CGFloat = K.ENABLED_BACKGROUND_ALPHA
    var disabledBackgroundAlpha: CGFloat = K.DISABLED_BACKGROUND_ALPHA
    var enabledBackgroundColor:UIColor = K.ENABLED_BACKGROUND_COLOR
    var disabledBackgroundColor:UIColor = K.DISABLED_BACKGROUND_COLOR
    
    // button title color
    var enabledTitleAlpha: CGFloat = K.ENABLED_TITLE_ALPHA
    var disabledTitleAlpha: CGFloat = K.DISABLED_TITLE_ALPHA
    var enabledTitleColor:UIColor = K.ENABLED_TITLE_COLOR
    var disabledTitleColor:UIColor = K.DISABLED_TITLE_COLOR


    // call the UIButton init (is this required... seemed to work without it).
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        

    }
    
// in the view controller setup the button in viewWillAppear with colors and  (usually) disable the button and then call required fields in viewDidLoad


    func requiredFields(_ nonEmpty: UITextField...) {
        self.nonEmptyFields = nonEmpty
        for field in nonEmptyFields! {
            field.addTarget(self, action: #selector(self.textFieldDidChange), for: UIControlEvents.editingChanged)
        }
    }
    
    func colorize(enabledBackgroundAlpha: CGFloat = K.ENABLED_BACKGROUND_ALPHA,
            disabledBackgroundAlpha: CGFloat = K.DISABLED_BACKGROUND_ALPHA,
            enabledBackgroundColor: UIColor = K.ENABLED_BACKGROUND_COLOR,
            disabledBackgroundColor: UIColor = K.DISABLED_BACKGROUND_COLOR,
            enabledTitleAlpha: CGFloat = K.ENABLED_TITLE_ALPHA,
            disabledTitleAlpha: CGFloat = K.DISABLED_TITLE_ALPHA,
            enabledTitleColor: UIColor = K.ENABLED_TITLE_COLOR,
            disabledTitleColor: UIColor = K.DISABLED_TITLE_COLOR) {
        
        self.enabledBackgroundAlpha = enabledBackgroundAlpha
        self.disabledBackgroundAlpha = disabledBackgroundAlpha
        self.enabledBackgroundColor = enabledBackgroundColor
        self.disabledBackgroundColor = disabledBackgroundColor
        self.enabledTitleAlpha = enabledTitleAlpha
        self.disabledTitleAlpha = disabledTitleAlpha
        self.enabledTitleColor = enabledTitleColor
        self.disabledTitleColor = disabledTitleColor
        
    }
    
    func textFieldDidChange() {
        var state = false
        for field in nonEmptyFields! {
            state = state || field.text!.isEmpty
        }
        // state is true if ANY field is empty 
        
        state ? self.disable() : self.enable()
    }
    
    func enable(){
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.backgroundColor = self.enabledBackgroundColor.withAlphaComponent(self.enabledBackgroundAlpha)
            self.setTitleColor(self.enabledTitleColor.withAlphaComponent(self.enabledTitleAlpha), for: UIControlState())
            }, completion: nil)
        self.isEnabled = true
    }
    func disable(){
        self.isEnabled = false
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.backgroundColor = self.disabledBackgroundColor.withAlphaComponent(self.disabledBackgroundAlpha)
            self.setTitleColor(self.disabledTitleColor.withAlphaComponent(self.disabledTitleAlpha), for: UIControlState())
            }, completion: nil)
    }
    
    
}
