//
//  BackgroundImageCycle.swift
//  signin
//
//  Created by Bruce Buckland on 7/24/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import UIKit

// Create a view called "imageView" in storyboard, and use this 
// class by instantiating one in viewWillAppear
// and invoking start, and in viewWillDisappear invoke stop
// and deinit the instance (to save memory).  Also in 
// didReceiveMemoryWarning recommend you stop and deinit.
// 
// if you put a blur visual effect with an alpha that is not 1
// over the imageView, you will get a runtime log message
// but I have not found a functionality problem.

class BackgroundImageCycle: NSObject {
    //MARK: Global Variables for Changing Image Functionality.
    private var idx = 0
    private var backGroundArray = [UIImage(named: "img1.jpg"),UIImage(named:"img2.jpg"), UIImage(named: "img3.jpg"), UIImage(named: "img4.jpg"),UIImage(named: "img5.jpg")]
        //,UIImage(named: "img6.jpg"),UIImage(named: "img7.jpg"),UIImage(named: "img8.jpg"),UIImage(named: "img9.jpg"),UIImage(named: "img10.jpg"),UIImage(named: "img11.jpg"),UIImage(named: "img12.jpg"),UIImage(named: "img13.jpg"),UIImage(named: "img14.jpg"),UIImage(named: "img15.jpg")]
    // cycle images and put the animations onto the main queue
    var backgroundImageTimer: NSTimer? = nil
    var viewToCycle: UIImageView?
    var cycleTime: NSTimeInterval = 6

    override init() { // I think I don't need this.
        super.init()
    }
    
    convenience init(_ imageView: UIImageView, speed: NSTimeInterval = 6 ) {
        self.init()
        viewToCycle = imageView
        idx = Int(arc4random_uniform(UInt32(backGroundArray.count)))
        cycleTime = speed
        
    }
    
   
    func start() {
        if self.backgroundImageTimer == nil {
            cycleBackgroundImages()
        }
    }

    func stop() {
        if self.backgroundImageTimer != nil {
            backgroundImageTimer?.invalidate()
            backgroundImageTimer = nil
        }
    }

    private func cycleBackgroundImages() {
        
//        // animate in first background without delay
//        self.changeImage()
        
        // schedule background flips (successful login will shut it down)
        backgroundImageTimer = NSTimer.scheduledTimerWithTimeInterval(cycleTime, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
    }
    
    @objc private func changeImage() { // #selector and private requires changeImage @objc
        if idx >= backGroundArray.count-1 {
            idx = 0
        }
        else{
            idx += 1
            // NSLog( "BackgroundImageCycle \(idx)\n")
        }
        let toImage = backGroundArray[idx]

        dispatch_async(dispatch_get_main_queue()) { UIView.transitionWithView(self.viewToCycle!, duration: 3, options: .TransitionCrossDissolve, animations: {
            self.viewToCycle!.image = toImage
            }, completion: nil)
        }
        
    }
    
    
    
}
