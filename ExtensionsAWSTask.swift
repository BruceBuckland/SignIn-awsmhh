//
//  ExtensionsAWSTask.swift
//  SignIn-awsmhh
//
//  Created by Bruce Buckland on 11/17/16.
//  Copyright © 2016 Bruce Buckland. All rights reserved.
//

import Foundation
import AWSCore

extension AWSTask {
    public func continueWithExceptionCheckingBlock(completionBlock:(result: AnyObject?, error: NSError?) -> Void) {
        self.continueWithBlock({(task: AWSTask) -> AnyObject? in
            if let exception = task.exception {
                print("Fatal exception: \(exception)")
                kill(getpid(), SIGKILL);
            }
            let result: AnyObject? = task.result
            let error: NSError? = task.error
            completionBlock(result: result, error: error)
            return nil
        })
        
    }
}
