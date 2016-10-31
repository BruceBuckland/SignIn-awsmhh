//
//  AppColor.swift
//  signin
//
//  Created by Bruce Buckland on 8/17/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import UIKit

// some of this can be done with global tint in storyboard editor
extension K {
    
    static let ENABLED_BACKGROUND_ALPHA:CGFloat = 0.8
    static let DISABLED_BACKGROUND_ALPHA:CGFloat = 0.28
    static let ENABLED_BACKGROUND_COLOR:UIColor = UIColor.red
    static let DISABLED_BACKGROUND_COLOR:UIColor = UIColor.white
    static let ENABLED_TITLE_ALPHA:CGFloat = 0.8
    static let DISABLED_TITLE_ALPHA:CGFloat = 0.5
    static let ENABLED_TITLE_COLOR:UIColor = UIColor.white
    static let DISABLED_TITLE_COLOR:UIColor = UIColor.white

}
class AppColor: NSObject {
    
    // properties are default colors for interface objects
    
    static var defaultColor = UIColor.red
    static let navControl = UINavigationBar.appearance()
    
    // functions help color interface objects with default colors
    
    class func colorizeField(_ fields:UITextField...) {
        for field in fields {
            field.textColor = defaultColor.lighter(0.1)
            field.tintColor = defaultColor
        }
    }
    
    class func colorizeButton(_ buttons:UIButton...) {
        for button in buttons {
            button.setTitleColor(defaultColor, for: UIControlState())
        }
    }
}
