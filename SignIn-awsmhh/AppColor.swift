//
//  AppColor.swift
//  signin
//
//  Created by Bruce Buckland on 8/17/16.
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
