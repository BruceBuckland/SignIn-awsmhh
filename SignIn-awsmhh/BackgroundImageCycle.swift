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
    fileprivate var idx = 0
    fileprivate var backGroundArray = [UIImage(named: "img1.jpg"),UIImage(named:"img2.jpg"), UIImage(named: "img3.jpg"), UIImage(named: "img4.jpg"),UIImage(named: "img5.jpg")]
        //,UIImage(named: "img6.jpg"),UIImage(named: "img7.jpg"),UIImage(named: "img8.jpg"),UIImage(named: "img9.jpg"),UIImage(named: "img10.jpg"),UIImage(named: "img11.jpg"),UIImage(named: "img12.jpg"),UIImage(named: "img13.jpg"),UIImage(named: "img14.jpg"),UIImage(named: "img15.jpg")]
    // cycle images and put the animations onto the main queue
    var backgroundImageTimer: Timer? = nil
    var viewToCycle: UIImageView?
    var cycleTime: TimeInterval = 6

    override init() { // I think I don't need this.
        super.init()
    }
    
    convenience init(_ imageView: UIImageView, speed: TimeInterval = 6 ) {
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

    fileprivate func cycleBackgroundImages() {
        
//        // animate in first background without delay
//        self.changeImage()
        
        // schedule background flips (successful login will shut it down)
        backgroundImageTimer = Timer.scheduledTimer(timeInterval: cycleTime, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
    }
    
    @objc fileprivate func changeImage() { // #selector and private requires changeImage @objc
        if idx >= backGroundArray.count-1 {
            idx = 0
        }
        else{
            idx += 1
            // NSLog( "BackgroundImageCycle \(idx)\n")
        }
        let toImage = backGroundArray[idx]

        DispatchQueue.main.async { UIView.transition(with: self.viewToCycle!, duration: 3, options: .transitionCrossDissolve, animations: {
            self.viewToCycle!.image = toImage
            }, completion: nil)
        }
        
    }
    
    
    
}
